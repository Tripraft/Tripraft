-- TripRaft canonical country seed
-- Country: Cabo Verde
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (132,'Cabo Verde','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (132001,132,'Ribeira Grande de Santiago','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (132002,132,'Praia','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (132003,132,'Tarrafal','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (13201,'World heritage site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (13202,'Historic centre');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (13203,'Historic site');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1320001,132001,'Cidade Velha','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1320002,132002,'Praia','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1320003,132003,'Tarrafal','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (132000001,1320001,'Cidade Velha, Historic Centre of Ribeira Grande','Cidade Velha, Historic Centre of Ribeira Grande','Ribeira Grande de Santiago','2026-10-06','World heritage site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (132000001,132000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (132000001,132000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (132000001,13201);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (132000002,1320002,'Centre historique de Praia','Centre historique de Praia','Praia','2026-10-06','Historic centre','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (132000002,132000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (132000002,132000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (132000002,13202);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (132000003,1320003,'Camp de concentration du Tarrafal','Camp de concentration du Tarrafal','Tarrafal','2026-10-06','Historic site','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (132000003,132000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (132000003,132000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (132000003,13203);
COMMIT;
