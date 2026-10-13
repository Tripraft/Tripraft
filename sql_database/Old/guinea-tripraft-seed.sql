-- TripRaft canonical country seed
-- Country: Guinea
-- Generated: 2026-10-06
-- Source basis: authoritative UNESCO / national heritage sources; unsupported provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (324,'Guinea','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (324001,324,'Boké Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (324002,324,'Nzérékoré Region','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (3240001,324001,'Sambailo','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (3240002,324002,'Lola','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (324000001,3240001,'Badiar National Park','Parc National du Badiar','Boké Region','2026-10-06','National park','UNESCO World Heritage Centre','partial','Identity and administrative location verified from Guinea’s UNESCO Tentative List entry; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (324000002,3240002,'Mount Nimba Strict Nature Reserve','Mount Nimba Strict Nature Reserve','Nzérékoré Region','2026-10-06','World Heritage natural site','UNESCO World Heritage Centre','partial','Identity and Guinean World Heritage property location verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (324000001,324000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO opening_hours (id,place_id,notes) VALUES (324000002,324000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (324000001,324000001,'no-photo-available','no_match');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (324000002,324000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 324000001, id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 324000002, id FROM tags WHERE tag_name='Nature';
COMMIT;
