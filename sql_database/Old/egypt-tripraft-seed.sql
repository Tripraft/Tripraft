-- TripRaft canonical country seed
-- Country: Egypt
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (818,'Egypt','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (818001,818,'Cairo','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (818002,818,'Faiyum','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (818003,818,'South Sinai','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (81801,'World heritage historic city');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (81802,'World heritage natural site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (81803,'World heritage cultural site');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (8180001,818001,'Cairo','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (8180002,818002,'Faiyum','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (8180003,818003,'Saint Catherine','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (818000001,8180001,'Historic Cairo','Historic Cairo','Cairo','2026-10-06','World heritage historic city','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (818000001,818000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (818000001,818000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (818000001,81801);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (818000002,8180002,'Wadi Al-Hitan (Whale Valley)','Wadi Al-Hitan (Whale Valley)','Faiyum','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (818000002,818000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (818000002,818000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (818000002,81802);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (818000003,8180003,'Saint Catherine Area','Saint Catherine Area','South Sinai','2026-10-06','World heritage cultural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (818000003,818000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (818000003,818000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (818000003,81803);
COMMIT;
