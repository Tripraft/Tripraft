-- TripRaft canonical country seed
-- Country: Eswatini
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre and Eswatini Tourism Authority; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (748,'Eswatini','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (748001,748,'Hhohho','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Archaeological heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Historic memorial');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Museum');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (7480001,748001,'Ngwenya','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (7480002,748001,'Lobamba','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (748000001,7480001,'Ngwenya Mines','Ngwenya Mines','Hhohho','2026-10-06','Archaeological heritage','UNESCO World Heritage Centre — Tentative List 5421','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (748000001,748000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (748000001,748000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 748000001,id FROM tags WHERE tag_name='Archaeological heritage';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (748000002,7480002,'Eswatini National Museum (Umsamo Wesive)','Eswatini National Museum (Umsamo Wesive)','Hhohho','2026-10-06','Museum','Eswatini Tourism Authority','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (748000002,748000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (748000002,748000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 748000002,id FROM tags WHERE tag_name='Museum';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (748000003,7480002,'King Sobhuza II Memorial Park','King Sobhuza II Memorial Park','Hhohho','2026-10-06','Historic memorial','Eswatini Tourism Authority','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (748000003,748000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (748000003,748000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 748000003,id FROM tags WHERE tag_name='Historic memorial';
COMMIT;
