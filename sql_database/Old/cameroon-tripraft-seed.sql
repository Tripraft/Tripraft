-- TripRaft canonical country seed
-- Country: Cameroon
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (120,'Cameroon','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (120001,120,'East','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (120002,120,'Far North','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (12001,'World heritage natural site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (12002,'World heritage cultural landscape');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (12003,'National park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1200001,120001,'Somalomo','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1200002,120002,'Mokolo','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1200003,120002,'Waza','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (120000001,1200001,'Dja Faunal Reserve','Dja Faunal Reserve','East','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (120000001,120000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (120000001,120000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (120000001,12001);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (120000002,1200002,'Diy-Gid-Biy Cultural Landscape of the Mandara Mountains','Diy-Gid-Biy Cultural Landscape of the Mandara Mountains','Far North','2026-10-06','World heritage cultural landscape','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (120000002,120000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (120000002,120000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (120000002,12002);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (120000003,1200003,'Waza National Park','Waza National Park','Far North','2026-10-06','National park','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (120000003,120000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (120000003,120000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (120000003,12003);
COMMIT;
