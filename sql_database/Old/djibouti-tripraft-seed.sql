-- TripRaft canonical country seed
-- Country: Djibouti
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (262,'Djibouti','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (262001,262,'Tadjourah','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (262002,262,'Obock','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (262003,262,'Djibouti','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (26201,'Natural site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (26202,'Natural landscape');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (26203,'Historic urban landscape');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2620001,262001,'Lake Assal','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2620002,262002,'Obock','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2620003,262003,'Djibouti City','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (262000001,2620001,'Le Lac Assal','Le Lac Assal','Tadjourah','2026-10-06','Natural site','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (262000001,262000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (262000001,262000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (262000001,26201);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (262000002,2620002,'Les paysages naturels de la région d’Obock','Les paysages naturels de la région d’Obock','Obock','2026-10-06','Natural landscape','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (262000002,262000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (262000002,262000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (262000002,26202);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (262000003,2620003,'Le paysage urbain historique de la ville de Djibouti et ses bâtiments spécifiques','Le paysage urbain historique de la ville de Djibouti et ses bâtiments spécifiques','Djibouti','2026-10-06','Historic urban landscape','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (262000003,262000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (262000003,262000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (262000003,26203);
COMMIT;
