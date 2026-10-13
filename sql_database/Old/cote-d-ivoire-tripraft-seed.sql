-- TripRaft canonical country seed
-- Country: Côte d’Ivoire
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre / Tentative Lists; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (384,'Côte d’Ivoire','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (384001,384,'Sud-Comoé','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (384002,384,'Agnéby-Tiassa','2026-10-06');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (38401,'World heritage historic town');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (38402,'Archaeological park');
INSERT OR IGNORE INTO tags (id,tag_name) VALUES (38403,'National park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (3840001,384001,'Grand-Bassam','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (3840002,384002,'Tiassalé','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (3840003,384001,'Adiaké','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (384000001,3840001,'Historic Town of Grand-Bassam','Historic Town of Grand-Bassam','Sud-Comoé','2026-10-06','World heritage historic town','UNESCO World Heritage Centre','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (384000001,384000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (384000001,384000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (384000001,38401);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (384000002,3840002,'Parc archéologique d’Ahouakro','Parc archéologique d’Ahouakro','Agnéby-Tiassa','2026-10-06','Archaeological park','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (384000002,384000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (384000002,384000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (384000002,38402);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (384000003,3840003,'Parc national des Îles Ehotilé','Parc national des Îles Ehotilé','Sud-Comoé','2026-10-06','National park','UNESCO World Heritage Centre tentative list','partial','Identity/source basis verified; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (384000003,384000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (384000003,384000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) VALUES (384000003,38403);
COMMIT;
