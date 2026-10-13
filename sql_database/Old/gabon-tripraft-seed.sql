-- TripRaft canonical country seed
-- Country: Gabon
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (266,'Gabon','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (266001,266,'Ogooué-Ivindo','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (266002,266,'Ogooué-Lolo','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Cave and cultural landscape');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage mixed landscape');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage national park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2660001,266001,'Lopé','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2660002,266001,'Makokou','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2660003,266002,'Lastoursville','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (266000001,2660001,'Ecosystem and Relict Cultural Landscape of Lopé-Okanda','Ecosystem and Relict Cultural Landscape of Lopé-Okanda','Ogooué-Ivindo','2026-10-06','World heritage mixed landscape','UNESCO World Heritage Centre — World Heritage property 1147rev','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (266000001,266000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (266000001,266000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 266000001,id FROM tags WHERE tag_name='World heritage mixed landscape';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (266000002,2660002,'Ivindo National Park','Ivindo National Park','Ogooué-Ivindo','2026-10-06','World heritage national park','UNESCO World Heritage Centre — World Heritage property 1653','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (266000002,266000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (266000002,266000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 266000002,id FROM tags WHERE tag_name='World heritage national park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (266000003,2660003,'Grottes de Lastoursville','Lastoursville Caves','Ogooué-Lolo','2026-10-06','Cave and cultural landscape','UNESCO World Heritage Centre — Tentative List 6587','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (266000003,266000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (266000003,266000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 266000003,id FROM tags WHERE tag_name='Cave and cultural landscape';
COMMIT;
