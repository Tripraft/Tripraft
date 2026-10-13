#!/usr/bin/env python3
"""Enrich every existing SQLite country from Wikipedia-linked Wikidata facts.

Python 3.10+, standard library only. Run with --help. Never inserts countries,
changes country identities, or migrates schemas. Refreshes available facts by default.
"""
from __future__ import annotations

import argparse
import calendar
from contextlib import closing, contextmanager
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import gzip
import hashlib
import json
import logging
import os
from pathlib import Path
import random
import re
import sqlite3
import sys
import tempfile
import time
import unicodedata
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, quote
from urllib.request import Request, urlopen
import uuid

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ("iso2", "iso3", "iso_numeric", "currency_code", "calling_code", "capital", "region")
PROPERTIES = dict(zip(FIELDS, ("P297", "P298", "P299", "P38", "P474", "P36", "P30")))
WIKIPEDIA = "https://en.wikipedia.org/w/api.php"
WIKIDATA = "https://www.wikidata.org/w/api.php"
TITLE_OVERRIDES = {
    "Georgia": "Georgia (country)",
    "Micronesia": "Federated States of Micronesia",
    "Palestine": "State of Palestine",
    "Côte d’Ivoire": "Ivory Coast",
    "Côte d'Ivoire": "Ivory Coast",
    "Macao": "Macau",
    "Ireland": "Republic of Ireland",
}
# The constituent Netherlands' ISO claims are deprecated because the codes
# identify its sovereign kingdom. Read those codes from the verified P17 parent.
ISO_PARENTS = {"Q55": "Q29999"}
LOG = logging.getLogger("countries")


class ImportFailure(Exception):
    """An actionable input, source, or consistency failure."""


def utcnow():
    return datetime.now(timezone.utc)


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2, allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


@contextmanager
def database_lock(database):
    """OS releases the lock even after interruption; the lock file may remain."""
    path = database.with_name(database.name + ".countries.lock")
    with path.open("a+b") as stream:
        stream.seek(0, os.SEEK_END)
        if stream.tell() == 0:
            stream.write(b"0")
            stream.flush()
        stream.seek(0)
        try:
            if os.name == "nt":
                import msvcrt
                msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as exc:
            raise ImportFailure(f"Another country importer holds {path}") from exc
        try:
            yield
        finally:
            stream.seek(0)
            if os.name == "nt":
                msvcrt.locking(stream.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(stream.fileno(), fcntl.LOCK_UN)


class WikimediaClient:
    def __init__(self, cache, user_agent, timeout=45, retries=4, cache_hours=24):
        self.cache = Path(cache)
        self.user_agent = user_agent
        self.timeout = timeout
        self.retries = retries
        self.cache_seconds = cache_hours * 3600
        self.last_request = 0.0

    def get(self, endpoint, **params):
        params.update(format="json", maxlag=5)
        url = endpoint + "?" + urlencode(sorted(params.items()))
        cache_file = self.cache / (hashlib.sha256(url.encode()).hexdigest() + ".json")
        if cache_file.exists() and time.time() - cache_file.stat().st_mtime < self.cache_seconds:
            try:
                cached = json.loads(cache_file.read_text(encoding="utf-8"))
                if cached["url"] == url and isinstance(cached["response"], dict):
                    return cached["response"]
            except (ValueError, KeyError, OSError):
                LOG.warning("Ignoring damaged cache %s", cache_file)
        for attempt in range(self.retries + 1):
            delay = max(0, 0.25 - (time.monotonic() - self.last_request))
            if delay:
                time.sleep(delay)
            retry_after = 0.0
            try:
                self.last_request = time.monotonic()
                request = Request(url, headers={"User-Agent": self.user_agent,
                                  "Accept": "application/json", "Accept-Encoding": "gzip"})
                with urlopen(request, timeout=self.timeout) as response:
                    raw = response.read()
                    if response.headers.get("Content-Encoding") == "gzip":
                        raw = gzip.decompress(raw)
                    result = json.loads(raw)
                    retry_after = self.retry_delay(response.headers.get("Retry-After"))
                if not isinstance(result, dict):
                    raise ImportFailure("Wikimedia returned a non-object JSON response")
                if "error" in result:
                    error = result["error"]
                    if error.get("code") not in {"maxlag", "ratelimited", "readonly"}:
                        raise ImportFailure(f"Wikimedia API: {error}")
                    raise URLError(str(error))
                atomic_json(cache_file, {"url": url, "accessed_at": utcnow().isoformat(), "response": result})
                return result
            except HTTPError as exc:
                if exc.code not in {429, 500, 502, 503, 504}:
                    raise ImportFailure(f"Wikimedia HTTP {exc.code}: {endpoint}") from exc
                retry_after = self.retry_delay(exc.headers.get("Retry-After"))
                reason = f"HTTP {exc.code}"
                exc.close()
            except (URLError, TimeoutError, ConnectionError, ValueError, OSError) as exc:
                reason = str(exc)
            if attempt == self.retries:
                raise ImportFailure(f"Wikimedia request failed after {attempt + 1} attempts: {reason}")
            delay = max(retry_after, min(60, 2 ** (attempt + 1)) + random.random())
            LOG.warning("%s; retrying in %.1fs", reason, delay)
            # Small sleep segments keep interrupts responsive even for long Retry-After values.
            deadline = time.monotonic() + delay
            while time.monotonic() < deadline:
                time.sleep(min(1, deadline - time.monotonic()))

    @staticmethod
    def retry_delay(value):
        if not value:
            return 0.0
        try:
            return max(0, float(value))
        except ValueError:
            try:
                return max(0, (parsedate_to_datetime(value) - utcnow()).total_seconds())
            except (ValueError, TypeError, OverflowError):
                return 0.0

    def pages(self, titles):
        result = {}
        for group in chunks(sorted(set(titles)), 25):
            data = self.get(WIKIPEDIA, action="query", titles="|".join(group),
                            prop="pageprops", redirects=1)
            query = data.get("query")
            if not isinstance(query, dict) or "pages" not in query:
                raise ImportFailure("Wikipedia returned no page mapping")
            aliases = {r["from"]: r["to"] for kind in ("normalized", "redirects")
                       for r in query.get(kind, [])}
            pages = {p["title"]: p for p in query["pages"].values()}
            for title in group:
                canonical, seen = title, set()
                while canonical in aliases and canonical not in seen:
                    seen.add(canonical)
                    canonical = aliases[canonical]
                result[title] = pages.get(canonical, {})
            LOG.info("Resolved %d/%d Wikipedia titles", len(result), len(set(titles)))
        return result

    def entities(self, ids):
        result = {}
        ids = sorted(set(ids))
        for group in chunks(ids, 25):
            data = self.get(WIKIDATA, action="wbgetentities", ids="|".join(group),
                            props="claims|labels|sitelinks", languages="en", sitefilter="enwiki")
            if not isinstance(data.get("entities"), dict):
                raise ImportFailure("Wikidata returned no entity mapping")
            result.update(data["entities"])
            LOG.info("Downloaded %d/%d Wikidata entities", len(result), len(ids))
        return result


def chunks(items, size):
    for start in range(0, len(items), size):
        yield items[start:start + size]


def time_bounds(value):
    """Interpret Wikibase year/month/day precision without inventing exact dates."""
    match = re.match(r"^\+(\d{4})-(\d{2})-(\d{2})T", value.get("time", ""))
    if not match:
        return None
    year, month, day = map(int, match.groups())
    precision = value.get("precision", 11)
    if not 1 <= year <= 9999 or precision < 9:
        return None
    try:
        if precision == 9:
            return f"{year:04d}-01-01", f"{year:04d}-12-31"
        if precision == 10:
            last = calendar.monthrange(year, month)[1]
            return f"{year:04d}-{month:02d}-01", f"{year:04d}-{month:02d}-{last:02d}"
        date = datetime(year, month, day).date().isoformat()
        return date, date
    except ValueError:
        return None


def current_statements(entity, prop, today):
    candidates = []
    for statement in entity.get("claims", {}).get(prop, []):
        if statement.get("rank") == "deprecated":
            continue
        qualifiers = statement.get("qualifiers", {})
        valid = True
        for code, is_start in (("P580", True), ("P582", False)):
            for qualifier in qualifiers.get(code, []):
                bounds = time_bounds(qualifier.get("datavalue", {}).get("value", {}))
                if bounds is None or (is_start and bounds[0] > today) or (not is_start and bounds[1] <= today):
                    valid = False
        if valid:
            candidates.append(statement)
    preferred = [s for s in candidates if s.get("rank") == "preferred"]
    return [s for s in (preferred or candidates)
            if s.get("mainsnak", {}).get("snaktype") == "value" and "datavalue" in s["mainsnak"]]


def values(entity, prop, today):
    return [s["mainsnak"]["datavalue"]["value"] for s in current_statements(entity, prop, today)]


def item_ids(entity, prop, today):
    return sorted({v["id"] for v in values(entity, prop, today)
                   if isinstance(v, dict) and re.fullmatch(r"Q\d+", v.get("id", ""))})


def normalized_value(field, value):
    if not isinstance(value, str):
        return None
    value = unicodedata.normalize("NFC", value.strip())
    patterns = {"iso2": r"[A-Z]{2}", "iso3": r"[A-Z]{3}",
                "iso_numeric": r"[0-9]{3}", "currency_code": r"[A-Z]{3}"}
    if field == "iso_numeric" and re.fullmatch(r"[0-9]{1,3}", value):
        value = value.zfill(3)
    if field == "calling_code":
        value = re.sub(r"[\s()\-]", "", value)
        if not value.startswith("+"):
            value = "+" + value
        return value if re.fullmatch(r"\+[1-9][0-9]{0,6}", value) else None
    if field in patterns:
        return value if re.fullmatch(patterns[field], value) else None
    return value if value and len(value) <= 500 and not any(ord(c) < 32 for c in value) else None


def extract_facts(entity, linked, today):
    facts, issues, evidence = {}, {}, {}
    for field, prop in PROPERTIES.items():
        statements = current_statements(entity, prop, today)
        raw = values(entity, prop, today)
        links = item_ids(entity, prop, today) if field in {"currency_code", "capital", "region"} else []
        if links:
            raw = []
            missing_codes = []
            for qid in links:
                target = linked.get(qid, {})
                if field == "currency_code":
                    codes = [v for v in values(target, "P498", today)
                             if normalized_value("currency_code", v) is not None]
                    raw.extend(codes)
                    if not codes:
                        missing_codes.append(qid)
                else:
                    raw.append(target.get("labels", {}).get("en", {}).get("value") or
                               target.get("sitelinks", {}).get("enwiki", {}).get("title"))
            if missing_codes:
                issues[field] = "Linked currencies without an alphabetic ISO code excluded: " + ", ".join(missing_codes)
        accepted = sorted({v for value in raw if (v := normalized_value(field, value)) is not None})
        evidence[field] = {"property": prop, "statements": statements, "linked_entities": links}
        if len(accepted) == 0:
            issues[field] = "No valid current value available"
        elif len(accepted) != len(set(json.dumps(v, sort_keys=True) for v in raw)):
            # Never silently store only part of a multi-valued claim.
            issues[field] = "Some source values failed validation; review required"
        elif field.startswith("iso") and len(accepted) > 1:
            issues[field] = "Multiple current ISO codes; review required"
        else:
            facts[field] = "; ".join(accepted)
    return facts, issues, evidence


def validate_identity(row, entity, facts, only_missing=False):
    if not entity or "missing" in entity:
        raise ImportFailure("Missing Wikidata entity")
    # Reject Wikipedia links to non-country topics and accidental disambiguations.
    if not facts.get("iso2") or not facts.get("iso3"):
        if entity.get("id") != "Q1246":  # Kosovo has no officially assigned ISO 3166-1 codes.
            raise ImportFailure("Country identity lacks unambiguous current ISO alpha codes")
    for field in ("iso2", "iso3", "iso_numeric"):
        if only_missing and row[field] is not None and facts.get(field) and row[field] != facts[field]:
            raise ImportFailure(f"Existing {field} disagrees with the linked Wikidata country")


def read_countries(database):
    if not database.is_file():
        raise ImportFailure(f"Database does not exist: {database}")
    with closing(sqlite3.connect(database.as_uri() + "?mode=ro", uri=True, timeout=30)) as conn:
        conn.row_factory = sqlite3.Row
        columns = {r["name"] for r in conn.execute("PRAGMA table_info(countries)")}
        required = {"id", "country_name", "created_at", "updated_at", "retired_at", *FIELDS}
        if not required <= columns:
            raise ImportFailure(f"Incompatible countries schema; missing: {sorted(required - columns)}")
        if conn.execute("PRAGMA quick_check").fetchone()[0] != "ok":
            raise ImportFailure("SQLite quick_check failed")
        if conn.execute("PRAGMA foreign_key_check").fetchone():
            raise ImportFailure("Database has pre-existing foreign key violations")
        rows = [dict(r) for r in conn.execute("SELECT * FROM countries ORDER BY country_name, id")]
    if not rows:
        raise ImportFailure("No countries exist; this importer preserves your existing roster")
    return rows


def make_plan(rows, pages, entities, linked, today, only_missing=False):
    plan, used_ids = [], set()
    for row in rows:
        item = {"id": row["id"], "country_name": row["country_name"], "before": row,
                "status": "ready", "facts": {}, "changes": {}, "issues": {}, "conflicts": {}}
        plan.append(item)
        if row["retired_at"] is not None:
            item["status"] = "retired"
            continue
        title = TITLE_OVERRIDES.get(row["country_name"], row["country_name"])
        page = pages.get(title, {})
        qid = page.get("pageprops", {}).get("wikibase_item", "")
        item["wikipedia_url"] = "https://en.wikipedia.org/wiki/" + quote(page.get("title", title).replace(" ", "_"))
        try:
            if not re.fullmatch(r"Q\d+", qid) or "disambiguation" in page.get("pageprops", {}) or "missing" in page:
                raise ImportFailure("Wikipedia country page is missing or ambiguous")
            if qid in used_ids:
                raise ImportFailure("Two local countries resolve to the same Wikidata entity")
            used_ids.add(qid)
            entity = entities.get(qid, {})
            item["wikidata_id"] = qid
            item["source_url"] = "https://www.wikidata.org/wiki/" + qid
            item["source_revision"] = entity.get("lastrevid")
            item["source_sha256"] = hashlib.sha256(json.dumps(entity, sort_keys=True,
                                                               ensure_ascii=False).encode("utf-8")).hexdigest()
            facts, issues, evidence = extract_facts(entity, linked, today)
            parent_id = ISO_PARENTS.get(qid)
            if parent_id and parent_id in item_ids(entity, "P17", today):
                parent = linked.get(parent_id, {})
                for field in ("iso2", "iso3", "iso_numeric"):
                    codes = {value for raw in values(parent, PROPERTIES[field], today)
                             if (value := normalized_value(field, raw)) is not None}
                    if field not in facts and len(codes) == 1:
                        facts[field] = next(iter(codes))
                        issues.pop(field, None)
                        evidence[field] = {"property": PROPERTIES[field], "source_entity": parent_id,
                                           "relationship": "P17", "statements": current_statements(parent, PROPERTIES[field], today),
                                           "source_sha256": hashlib.sha256(json.dumps(parent, sort_keys=True,
                                                                                      ensure_ascii=False).encode("utf-8")).hexdigest()}
            if entity.get("sitelinks", {}).get("enwiki", {}).get("title") != page.get("title"):
                raise ImportFailure("Wikipedia and Wikidata article identities disagree")
            validate_identity(row, entity, facts, only_missing)
            if qid == "Q1246":
                for field in ("iso2", "iso3"):
                    if field in facts:
                        issues[field] = "Unofficial Wikidata code; Kosovo has no assigned ISO 3166-1 code"
            item.update(facts=facts, issues=issues, evidence=evidence)
            for field, value in facts.items():
                if row[field] != value and (not only_missing or row[field] is None):
                    item["changes"][field] = value
                elif row[field] != value:
                    item["conflicts"][field] = {"existing": row[field], "source": value}
        except ImportFailure as exc:
            item.update(status="failed", error=str(exc))
    return plan


def record_evidence(conn, item, batch_id):
    for field, value in item["changes"].items():
        evidence = item["evidence"][field]
        source_entity = evidence.get("source_entity", item["wikidata_id"])
        source_url = "https://www.wikidata.org/wiki/" + source_entity
        conn.execute("INSERT INTO data_sources(url,source_title,publisher,authority_tier) VALUES(?,?,?,3) "
                     "ON CONFLICT(url) DO NOTHING", (source_url, item["country_name"], "Wikidata"))
        source_id = conn.execute("SELECT id FROM data_sources WHERE url=?", (source_url,)).fetchone()[0]
        notes = json.dumps({"wikidata_id": source_entity, "property": PROPERTIES[field],
                            "revision": item["source_revision"], "license": "CC0",
                            "source_sha256": evidence.get("source_sha256", item["source_sha256"]),
                            "note": "Single Wikimedia source; not independently verified"})
        previous = item["before"][field]
        conn.execute("INSERT INTO data_change_log(batch_id,table_name,record_id,column_name,old_value,"
                     "new_value,change_type,source_id,notes) VALUES(?,'countries',?,?,?,?,?,?,?)",
                     (batch_id, item["id"], field,
                      json.dumps(previous, ensure_ascii=False) if previous is not None else None,
                      json.dumps(value, ensure_ascii=False), "NULL_FILLED" if previous is None else "CORRECTED",
                      source_id, notes))
        conn.execute("INSERT INTO field_verifications(batch_id,entity_type,entity_id,source_table,column_name,"
                     "accepted_value,source_id,verification_status,notes) VALUES(?,'COUNTRY',?,'countries',?,?,?,'partial',?)",
                     (batch_id, item["id"], field, value, source_id, notes))


def apply_plan(database, rows, plan, run_dir, batch_id):
    backup = run_dir / "before.db"
    with closing(sqlite3.connect(database.as_uri() + "?mode=rw", uri=True, timeout=30)) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys=ON")
        tables = {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        provenance_tables = {"data_sources", "data_change_log", "field_verifications", "batch_registry"}
        provenance = provenance_tables <= tables
        if tables & provenance_tables and not provenance:
            raise ImportFailure("Incomplete provenance schema; refusing an unaudited write")
        with closing(sqlite3.connect(backup)) as target:
            conn.backup(target)
        conn.execute("BEGIN IMMEDIATE")
        try:
            actual = [dict(r) for r in conn.execute("SELECT * FROM countries ORDER BY country_name, id")]
            if actual != rows:
                raise ImportFailure("Countries changed during download; rerun to build a fresh plan")
            timestamp = utcnow().isoformat(timespec="seconds")
            if provenance:
                conn.execute("INSERT INTO batch_registry(batch_id,source_filename,output_filename,processing_status,"
                             "started_at,notes) VALUES(?,?,?,'PROCESSING',?,?)",
                             (batch_id, str(Path(__file__).resolve()), str(run_dir / "report.json"), timestamp,
                              "All-country Wikimedia enrichment; existing identities preserved"))
            for item in plan:
                if item["status"] != "ready" or not item["changes"]:
                    continue
                conn.execute("SAVEPOINT country_update")
                try:
                    fields = list(item["changes"])
                    assignments = ", ".join(f'"{field}"=?' for field in fields)
                    conn.execute(f"UPDATE countries SET {assignments}, updated_at=? WHERE id=?",
                                 [item["changes"][field] for field in fields] + [timestamp, item["id"]])
                    if provenance:
                        record_evidence(conn, item, batch_id)
                    item["status"] = "applied"
                except sqlite3.IntegrityError as exc:
                    conn.execute("ROLLBACK TO country_update")
                    item.update(status="failed", error=f"Database constraint rejected country: {exc}")
                finally:
                    conn.execute("RELEASE country_update")
            if conn.execute("PRAGMA foreign_key_check").fetchone():
                raise ImportFailure("Foreign key validation failed; rolling back")
            if provenance:
                needs_review = any(p["status"] == "failed" or p["conflicts"] or p["issues"] for p in plan)
                conn.execute("UPDATE batch_registry SET processing_status=?,completed_at=? WHERE batch_id=?",
                             ("NEEDS_REVIEW" if needs_review else "PASS", timestamp, batch_id))
            conn.commit()
        except BaseException:
            conn.rollback()
            raise
    return str(backup)


def run(args):
    database = args.database.resolve()
    output = args.output.resolve()
    batch_id = "countries-" + utcnow().strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    run_dir = output / "runs" / batch_id
    run_dir.mkdir(parents=True)
    report = {"batch_id": batch_id, "database": str(database), "dry_run": args.dry_run,
              "only_missing": args.only_missing,
              "started_at": utcnow().isoformat(), "status": "fetching", "countries": []}
    report_path = run_dir / "report.json"
    try:
        with database_lock(database):
            rows = read_countries(database)
            LOG.info("Loaded %d existing country IDs from %s", len(rows), database)
            client = WikimediaClient(output / "cache", args.user_agent, args.timeout, args.retries, args.cache_hours)
            titles = [TITLE_OVERRIDES.get(r["country_name"], r["country_name"])
                      for r in rows if r["retired_at"] is None]
            pages = client.pages(titles)
            qids = [p.get("pageprops", {}).get("wikibase_item") for p in pages.values()]
            entities = client.entities([q for q in qids if q and re.fullmatch(r"Q\d+", q)])
            today = utcnow().date().isoformat()
            related = set()
            for entity in entities.values():
                for prop in ("P38", "P36", "P30"):
                    related.update(item_ids(entity, prop, today))
                if entity.get("id") in ISO_PARENTS:
                    related.add(ISO_PARENTS[entity["id"]])
            linked = client.entities(list(related))
            # Retain the exact downloaded claims and linked labels/currency codes for audit.
            atomic_json(run_dir / "sources.json", {"wikipedia_pages": pages, "countries": entities,
                                                   "linked_entities": linked, "as_of": today})
            plan = make_plan(rows, pages, entities, linked, today, args.only_missing)
            report["countries"] = plan
            report["status"] = "planned"
            atomic_json(report_path, report)
            changes = sum(len(p["changes"]) for p in plan)
            if not args.dry_run and changes:
                report["backup"] = str(run_dir / "before.db")
                report["backup"] = apply_plan(database, rows, plan, run_dir, batch_id)
                report["database_committed"] = True
            report["status"] = "dry_run" if args.dry_run else "completed"
            report["summary"] = {
                "countries_total": len(rows),
                "countries_failed": sum(p["status"] == "failed" for p in plan),
                "countries_retired": sum(p["status"] == "retired" for p in plan),
                "countries_updated": sum(p["status"] == "applied" for p in plan),
                "fields_planned": changes,
                "fields_written": sum(len(p["changes"]) for p in plan if p["status"] == "applied"),
                "fields_unavailable": sum(field not in p["facts"] for p in plan for field in p["issues"]),
                "fields_with_source_notes": sum(field in p["facts"] for p in plan for field in p["issues"]),
                "fields_conflicting": sum(len(p["conflicts"]) for p in plan),
            }
            report["completed_at"] = utcnow().isoformat()
            atomic_json(report_path, report)
            atomic_json(output / "latest.json", {"report": str(report_path), "summary": report["summary"]})
            LOG.info("%s", json.dumps(report["summary"]))
            LOG.info("Report: %s", report_path)
            return 1 if report["summary"]["countries_failed"] or report["summary"]["fields_conflicting"] else 0
    except BaseException as exc:
        report.update(status="interrupted" if isinstance(exc, KeyboardInterrupt) else "failed", error=str(exc))
        # A transaction failure can leave in-memory items marked applied although SQLite rolled back.
        for item in report["countries"]:
            if item["status"] == "applied" and not report.get("database_committed"):
                item["status"] = "rolled_back"
        atomic_json(report_path, report)
        LOG.error("%s. Report: %s", exc or "Interrupted", report_path)
        if isinstance(exc, KeyboardInterrupt):
            return 130
        if not isinstance(exc, (ImportFailure, sqlite3.Error, OSError, ValueError)):
            raise
        return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=ROOT / "data/catalog/tripraft-canonical.db")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "data")
    parser.add_argument("--dry-run", action="store_true", help="Fetch and report without updating database records")
    parser.add_argument("--only-missing", action="store_true", help="Preserve populated fields; default refreshes available facts")
    parser.add_argument("--user-agent", default=os.environ.get("WIKIMEDIA_USER_AGENT",
                        "TripraftCountryImporter/1.0 (local SQLite country enrichment; Python urllib)"),
                        help="Identifying Wikimedia User-Agent; optionally include your contact URL/email")
    parser.add_argument("--timeout", type=float, default=45, help="Per-request timeout in seconds")
    parser.add_argument("--retries", type=int, default=4, help="Retries per failed request")
    parser.add_argument("--cache-hours", type=float, default=24, help="Cache TTL; use 0 for fresh downloads")
    args = parser.parse_args(argv)
    if args.timeout <= 0 or args.retries < 0 or args.cache_hours < 0:
        parser.error("timeout must be positive; retries and cache-hours must be nonnegative")
    if not args.user_agent.strip() or any(c in args.user_agent for c in "\r\n"):
        parser.error("user-agent must be a nonempty single line")
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
