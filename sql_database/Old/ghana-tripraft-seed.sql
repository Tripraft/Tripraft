-- TripRaft canonical country seed
-- Country: Ghana
-- Generated: 2026-10-06
-- Source basis: authoritative UNESCO / national heritage sources; unsupported provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (288,'Ghana','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (288001,288,'Central Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (288002,288,'Greater Accra Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (288003,288,'Ashanti Region','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Heritage');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2880001,288001,'Cape Coast','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2880002,288001,'Elmina','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2880003,288002,'Accra','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2880004,288003,'Kumasi','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (288000001,2880001,'Cape Coast Castle','Cape Coast Castle','Central Region','2026-10-06','World Heritage castle','UNESCO World Heritage Centre / Ghana Museums and Monuments Board','partial','Identity and heritage status verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (288000002,2880002,'Elmina Castle','St. George’s d’Elmina Castle','Central Region','2026-10-06','World Heritage castle','UNESCO World Heritage Centre / Ghana Museums and Monuments Board','partial','Identity and heritage status verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (288000003,2880003,'Christiansborg Castle','Christiansborg Castle','Greater Accra Region','2026-10-06','World Heritage castle','UNESCO World Heritage Centre / Ghana Museums and Monuments Board','partial','Identity verified as a component of Ghana’s UNESCO-listed Forts and Castles property; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (288000004,2880004,'Asante Traditional Buildings','Asante Traditional Buildings','Ashanti Region','2026-10-06','World Heritage cultural site','UNESCO World Heritage Centre','partial','Identity and World Heritage status verified; Kumasi is used as the supported tourism hub for the serial property near the city; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (288000001,288000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (288000002,288000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (288000003,288000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (288000004,288000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (288000001,288000001,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (288000002,288000002,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (288000003,288000003,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (288000004,288000004,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 288000001, id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 288000002, id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 288000003, id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 288000004, id FROM tags WHERE tag_name='Heritage';
COMMIT;
