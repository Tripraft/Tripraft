# Purpose: Extracts ordered paragraphs, tables and document furniture from a supplied DOCX, records its SHA-256 and preserves the original in the API agreement directory for review.
"""Run with the source DOCX path; review the generated JSON before committing.

This importer does not complete blanks, execute an agreement or modify Word files.
"""
import hashlib
import json
from pathlib import Path
import shutil
import sys
from xml.etree import ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[2]
DESTINATION = ROOT / 'services/api/app/partners/agreements'
SOURCE_NAME = 'partner-agreement-v3-2026-10-18.docx'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
W = '{' + NS['w'] + '}'


def paragraph_text(element):
    return ''.join(node.text or '' if node.tag == W + 't' else '\n' if node.tag == W + 'br' else '\t'
                   for node in element.iter() if node.tag in {W + 't', W + 'br', W + 'tab'})


def extract(source):
    blocks, furniture = [], []
    with ZipFile(source) as archive:
        body = ET.fromstring(archive.read('word/document.xml')).find('w:body', NS)
        for child in body:
            if child.tag == W + 'p':
                value = paragraph_text(child)
                if not value:
                    continue
                style = child.find('w:pPr/w:pStyle', NS)
                style = style.get(W + 'val', '') if style is not None else ''
                kind = 'heading' if style in {'Heading1', 'Heading2'} else 'bullet' if style == 'ListBullet' else 'paragraph'
                blocks.append({'kind': kind, 'text': value})
            elif child.tag == W + 'tbl':
                rows = [['\n'.join(paragraph_text(p) for p in cell.findall('.//w:p', NS))
                         for cell in row.findall('w:tc', NS)] for row in child.findall('w:tr', NS)]
                blocks.append({'kind': 'table', 'rows': rows})
        for name in sorted(archive.namelist()):
            if name.startswith('word/') and name.endswith('.xml') and any(
                part in name for part in ('header', 'footer', 'footnotes', 'endnotes')
            ):
                paragraphs = [paragraph_text(p) for p in ET.fromstring(archive.read(name)).findall('.//w:p', NS)]
                furniture.append({'part': name, 'paragraphs': [text for text in paragraphs if text]})
    return {
        'version': '3.0', 'document_date': '2026-10-18', 'status': 'DRAFT',
        'title': 'Tour Operator Partner Agreement', 'source_filename': SOURCE_NAME,
        'source_sha256': hashlib.sha256(Path(source).read_bytes()).hexdigest(),
        'blocks': blocks, 'document_furniture': furniture,
    }


def main():
    source = Path(sys.argv[1]).resolve(strict=True)
    result = extract(source)
    DESTINATION.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, DESTINATION / SOURCE_NAME)
    (DESTINATION / 'partner-agreement-v3-2026-10-18.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Imported {len(result["blocks"])} blocks; SHA-256 {result["source_sha256"]}')


if __name__ == '__main__':
    main()
