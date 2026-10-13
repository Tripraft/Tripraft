-- TripRaft canonical country seed
-- Country: Comoros
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (174,'Comoros','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (174001,174,'Grande Comore','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (174002,174,'Anjouan','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (174003,174,'Mohéli','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (17401,'Historic medina');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (17402,'Marine park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1740001,174001,'Moroni','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1740002,174002,'Mutsamudu','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1740003,174003,'Fomboni','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (174000001,1740001,'Medina of Moroni','Medina of Moroni','Grande Comore','2026-10-06','Historic medina','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (174000001,174000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (174000001,174000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (174000001,17401);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (174000002,1740002,'Medina of Mutsamudu','Medina of Mutsamudu','Anjouan','2026-10-06','Historic medina','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (174000002,174000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (174000002,174000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (174000002,17401);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (174000003,1740003,'Parc Marin de Mohéli','Parc Marin de Mohéli','Mohéli','2026-10-06','Marine park','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (174000003,174000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (174000003,174000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (174000003,17402);
COMMIT;
