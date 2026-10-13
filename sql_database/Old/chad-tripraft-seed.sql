-- TripRaft canonical country seed
-- Country: Chad
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (148,'Chad','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (148001,148,'Ennedi-Ouest','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (148002,148,'Lac','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14801,'World heritage mixed site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14802,'World heritage natural site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14803,'Cultural landscape');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1480001,148001,'Fada','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1480002,148001,'Ounianga Kébir','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1480003,148002,'Bol','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (148000001,1480001,'Ennedi Massif: Natural and Cultural Landscape','Ennedi Massif: Natural and Cultural Landscape','Ennedi-Ouest','2026-10-06','World heritage mixed site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (148000001,148000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (148000001,148000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (148000001,14801);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (148000002,1480002,'Lakes of Ounianga','Lakes of Ounianga','Ennedi-Ouest','2026-10-06','World heritage natural site','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (148000002,148000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (148000002,148000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (148000002,14802);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (148000003,1480003,'Paysage culturel du Lac Tchad','Paysage culturel du Lac Tchad','Lac','2026-10-06','Cultural landscape','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (148000003,148000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (148000003,148000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (148000003,14803);
COMMIT;
