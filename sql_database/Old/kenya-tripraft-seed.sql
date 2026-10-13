-- TripRaft canonical country seed
-- Country: Kenya
-- Generated: 2026-10-06
-- Source basis: authoritative UNESCO / national heritage sources; unsupported provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (404,'Kenya','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (404001,404,'Mombasa County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (404002,404,'Lamu County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (404003,404,'Kilifi County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (404004,404,'Migori County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (404005,404,'Nakuru County','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Archaeology');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4040001,404001,'Mombasa','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4040002,404002,'Lamu','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4040003,404003,'Gedi','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4040004,404004,'Migori','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4040005,404005,'Nakuru','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (404000001,4040001,'Fort Jesus, Mombasa','Fort Jesus, Mombasa','Mombasa County','2026-10-06','World Heritage fort','UNESCO World Heritage Centre','partial','Identity and World Heritage status verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (404000002,4040002,'Lamu Old Town','Lamu Old Town','Lamu County','2026-10-06','World Heritage historic town','UNESCO World Heritage Centre','partial','Identity and World Heritage status verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (404000003,4040003,'The Historic Town and Archaeological Site of Gedi','The Historic Town and Archaeological Site of Gedi','Kilifi County','2026-10-06','World Heritage archaeological site','UNESCO World Heritage Centre','partial','Identity and World Heritage status verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (404000004,4040004,'Thimlich Ohinga Archaeological Site','Thimlich Ohinga Archaeological Site','Migori County','2026-10-06','World Heritage archaeological site','UNESCO World Heritage Centre','partial','Identity and location northwest of Migori verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (404000005,4040005,'Lake Nakuru','Lake Nakuru','Nakuru County','2026-10-06','World Heritage natural site','UNESCO World Heritage Centre','partial','Identity verified as a component of the Kenya Lake System in the Great Rift Valley World Heritage property; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (404000001,404000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (404000002,404000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (404000003,404000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (404000004,404000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (404000005,404000005,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (404000001,404000001,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (404000002,404000002,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (404000003,404000003,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (404000004,404000004,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (404000005,404000005,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 404000001, id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 404000002, id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 404000003, id FROM tags WHERE tag_name='Archaeology';
INSERT INTO place_tags (place_id,tag_id) SELECT 404000004, id FROM tags WHERE tag_name='Archaeology';
INSERT INTO place_tags (place_id,tag_id) SELECT 404000005, id FROM tags WHERE tag_name='Nature';
COMMIT;
