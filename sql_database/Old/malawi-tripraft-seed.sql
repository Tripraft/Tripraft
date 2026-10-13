-- TripRaft canonical country seed
-- Country: Malawi
-- Generated: 2026-10-06
-- Source basis: Visit Malawi official tourism portal; Malawi Department of National Parks and Wildlife; UNESCO World Heritage Centre
-- Administrative model: The states table uses Malawi’s three first-level regions for represented hubs.
-- Provider-style enrichment is intentionally NULL unless directly source/provider backed.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (454,'Malawi','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (454001,454,'Southern Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (454002,454,'Central Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (454003,454,'Northern Region','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage national park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage rock art');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage cultural landscape');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Wildlife reserve');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('National park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Scenic area');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540001,454001,'Cape Maclear','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540002,454002,'Dedza','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540003,454001,'Mulanje','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540004,454001,'Chikwawa','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540005,454001,'Liwonde','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540006,454003,'Chelinda','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540007,454003,'Rumphi','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540008,454002,'Nkhotakota','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4540009,454001,'Zomba','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000001,4540001,'Lake Malawi National Park','Lake Malawi National Park','Southern Region','2026-10-06','World Heritage national park','UNESCO World Heritage Centre; Visit Malawi official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000001,454000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000001,454000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000001,id FROM tags WHERE tag_name='World Heritage national park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000002,4540002,'Chongoni Rock-Art Area','Chongoni Rock-Art Area','Central Region','2026-10-06','World Heritage rock art','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000002,454000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000002,454000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000002,id FROM tags WHERE tag_name='World Heritage rock art';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000003,4540003,'Mount Mulanje Cultural Landscape','Mount Mulanje Cultural Landscape','Southern Region','2026-10-06','World Heritage cultural landscape','UNESCO World Heritage Centre; Visit Malawi official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000003,454000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000003,454000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000003,id FROM tags WHERE tag_name='World Heritage cultural landscape';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000004,4540004,'Majete Wildlife Reserve','Majete Wildlife Reserve','Southern Region','2026-10-06','Wildlife reserve','Visit Malawi official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000004,454000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000004,454000004,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000004,id FROM tags WHERE tag_name='Wildlife reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000005,4540005,'Liwonde National Park','Liwonde National Park','Southern Region','2026-10-06','National park','Visit Malawi official tourism portal; Malawi Department of National Parks and Wildlife','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000005,454000005,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000005,454000005,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000005,id FROM tags WHERE tag_name='National park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000006,4540006,'Nyika National Park','Nyika National Park','Northern Region','2026-10-06','National park','Visit Malawi official tourism portal; Malawi Department of National Parks and Wildlife','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000006,454000006,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000006,454000006,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000006,id FROM tags WHERE tag_name='National park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000007,4540007,'Vwaza Marsh Wildlife Reserve','Vwaza Marsh Wildlife Reserve','Northern Region','2026-10-06','Wildlife reserve','Visit Malawi official tourism portal; Malawi Department of National Parks and Wildlife','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000007,454000007,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000007,454000007,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000007,id FROM tags WHERE tag_name='Wildlife reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000008,4540008,'Nkhotakota Wildlife Reserve','Nkhotakota Wildlife Reserve','Central Region','2026-10-06','Wildlife reserve','Visit Malawi official tourism portal; Malawi Department of National Parks and Wildlife','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000008,454000008,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000008,454000008,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000008,id FROM tags WHERE tag_name='Wildlife reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (454000009,4540009,'Zomba Plateau','Zomba Plateau','Southern Region','2026-10-06','Scenic area','Visit Malawi official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (454000009,454000009,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (454000009,454000009,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 454000009,id FROM tags WHERE tag_name='Scenic area';
COMMIT;
