-- TripRaft canonical country seed
-- Country: Republic of the Congo
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (178,'Republic of the Congo','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (178001,178,'Cuvette-Ouest','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (178002,178,'Kouilou','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (178003,178,'Pool','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (17801,'World heritage natural site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (17802,'Historic site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (17803,'Royal cultural landscape');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1780001,178001,'Mbomo','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1780002,178002,'Loango','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1780003,178003,'Mbé','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (178000001,1780001,'Forest Massif of Odzala-Kokoua','Forest Massif of Odzala-Kokoua','Cuvette-Ouest','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (178000001,178000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (178000001,178000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (178000001,17801);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (178000002,1780002,'Ancien port d’embarquement des esclaves de Loango','Ancien port d’embarquement des esclaves de Loango','Kouilou','2026-10-06','Historic site','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (178000002,178000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (178000002,178000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (178000002,17802);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (178000003,1780003,'Domaine royal de Mbé','Domaine royal de Mbé','Pool','2026-10-06','Royal cultural landscape','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (178000003,178000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (178000003,178000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (178000003,17803);
COMMIT;
