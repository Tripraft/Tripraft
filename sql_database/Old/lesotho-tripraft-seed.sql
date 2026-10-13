-- TripRaft canonical country seed
-- Country: Lesotho
-- Generated: 2026-10-06
-- Source basis: Visit Lesotho official tourism portal; Lesotho Department of Environment; UNESCO World Heritage Centre; Government of Lesotho district references
-- Administrative model: The states table uses Lesotho administrative districts.
-- Provider-style enrichment is intentionally NULL unless directly source/provider backed.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (426,'Lesotho','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (426001,426,'Maseru District','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (426002,426,'Qacha''s Nek District','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Cultural heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Waterfall');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('National park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4260001,426001,'Thaba Bosiu','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4260002,426001,'Semonkong','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4260003,426002,'Sehlabathebe','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (426000001,4260001,'Thaba Bosiu Cultural Village','Thaba Bosiu Cultural Village','Maseru District','2026-10-06','Cultural heritage','Visit Lesotho official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (426000001,426000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (426000001,426000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 426000001,id FROM tags WHERE tag_name='Cultural heritage';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (426000002,4260002,'Maletsunyane Falls','Maletsunyane Falls','Maseru District','2026-10-06','Waterfall','Visit Lesotho official tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (426000002,426000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (426000002,426000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 426000002,id FROM tags WHERE tag_name='Waterfall';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (426000003,4260003,'Sehlabathebe National Park','Sehlabathebe National Park','Qacha''s Nek District','2026-10-06','National park','Lesotho Department of Environment; UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (426000003,426000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (426000003,426000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 426000003,id FROM tags WHERE tag_name='National park';
COMMIT;
