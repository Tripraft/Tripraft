-- TripRaft canonical country seed
-- Country: Democratic Republic of the Congo
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (180,'Democratic Republic of the Congo','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (180001,180,'North Kivu','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (180002,180,'South Kivu','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (180003,180,'Ituri','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (18001,'World heritage natural site');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1800001,180001,'Goma','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1800002,180002,'Bukavu','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1800003,180003,'Epulu','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (180000001,1800001,'Virunga National Park','Virunga National Park','North Kivu','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (180000001,180000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (180000001,180000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (180000001,18001);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (180000002,1800002,'Kahuzi-Biega National Park','Kahuzi-Biega National Park','South Kivu','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (180000002,180000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (180000002,180000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (180000002,18001);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (180000003,1800003,'Okapi Wildlife Reserve','Okapi Wildlife Reserve','Ituri','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (180000003,180000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (180000003,180000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (180000003,18001);
COMMIT;
