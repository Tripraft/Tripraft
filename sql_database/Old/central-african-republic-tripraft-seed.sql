-- TripRaft canonical country seed
-- Country: Central African Republic
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (140,'Central African Republic','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (140001,140,'Nana-Mambéré','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (140002,140,'Bamingui-Bangoran','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (140003,140,'Sangha-Mbaéré','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14001,'Megalithic site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14002,'Historic and archaeological site');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (14003,'Nature reserve');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1400001,140001,'Bouar','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1400002,140002,'Ndélé','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (1400003,140003,'Bambio','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (140000001,1400001,'Les mégalithes de Bouar','Les mégalithes de Bouar','Nana-Mambéré','2026-10-06','Megalithic site','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (140000001,140000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (140000001,140000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (140000001,14001);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (140000002,1400002,'Le Tata du Sultan Sénoussi, les grottes de Kaga-Kpoungouvou et la ville de Ndélé','Le Tata du Sultan Sénoussi, les grottes de Kaga-Kpoungouvou et la ville de Ndélé','Bamingui-Bangoran','2026-10-06','Historic and archaeological site','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (140000002,140000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (140000002,140000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (140000002,14002);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (140000003,1400003,'La Réserve intégrale de la Mbaéré-Bondingué','La Réserve intégrale de la Mbaéré-Bondingué','Sangha-Mbaéré','2026-10-06','Nature reserve','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (140000003,140000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (140000003,140000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (140000003,14003);
COMMIT;
