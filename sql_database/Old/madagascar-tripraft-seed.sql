-- TripRaft canonical country seed
-- Country: Madagascar
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre; Protected Areas of Madagascar / Madagascar National Parks source material
-- Administrative model: The states table uses Madagascar regions for the represented tourism hubs.
-- Provider-style enrichment is intentionally NULL unless directly source/provider backed.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (450,'Madagascar','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (450001,450,'Analamanga Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (450002,450,'Melaky Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (450003,450,'Ihorombe Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (450004,450,'Diana Region','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage cultural landscape');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage national park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('National park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Special reserve');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500001,450001,'Ambohimanga Rova','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500002,450002,'Bekopaka','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500003,450003,'Ranohira','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500004,450004,'Joffreville','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500005,450004,'Mahamasina','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4500006,450004,'Nosy Be','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000001,4500001,'Royal Hill of Ambohimanga','Royal Hill of Ambohimanga','Analamanga Region','2026-10-06','World Heritage cultural landscape','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000001,450000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000001,450000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000001,id FROM tags WHERE tag_name='World Heritage cultural landscape';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000002,4500002,'Tsingy de Bemaraha National Park','Tsingy de Bemaraha National Park','Melaky Region','2026-10-06','World Heritage national park','UNESCO World Heritage Centre; Protected Areas of Madagascar','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000002,450000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000002,450000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000002,id FROM tags WHERE tag_name='World Heritage national park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000003,4500003,'Isalo National Park','Isalo National Park','Ihorombe Region','2026-10-06','National park','Protected Areas of Madagascar / Madagascar National Parks','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000003,450000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000003,450000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000003,id FROM tags WHERE tag_name='National park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000004,4500004,'Montagne d''Ambre National Park','Montagne d''Ambre National Park','Diana Region','2026-10-06','National park','Protected Areas of Madagascar / Madagascar National Parks','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000004,450000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000004,450000004,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000004,id FROM tags WHERE tag_name='National park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000005,4500005,'Ankarana Special Reserve','Ankarana Special Reserve','Diana Region','2026-10-06','Special reserve','UNESCO World Heritage Centre; Protected Areas of Madagascar','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000005,450000005,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000005,450000005,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000005,id FROM tags WHERE tag_name='Special reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (450000006,4500006,'Lokobe National Park','Lokobe National Park','Diana Region','2026-10-06','National park','Protected Areas of Madagascar / Madagascar National Parks','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (450000006,450000006,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (450000006,450000006,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 450000006,id FROM tags WHERE tag_name='National park';
COMMIT;
