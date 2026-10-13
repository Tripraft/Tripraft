-- TripRaft canonical country seed
-- Country: Equatorial Guinea
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre Tentative List; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (226,'Equatorial Guinea','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (226001,226,'Bioko Sur','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (226002,226,'Annobón','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Cultural heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Island nature reserve');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature reserve');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2260001,226001,'Batete','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2260002,226001,'Ureka','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2260003,226002,'San Antonio de Palé','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (226000001,2260001,'Église néogothique de Batete','Batete Neo-Gothic Church','Bioko Sur','2026-10-06','Cultural heritage','UNESCO World Heritage Centre — Tentative List 7006','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (226000001,226000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (226000001,226000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 226000001,id FROM tags WHERE tag_name='Cultural heritage';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (226000002,2260002,'Réserve Scientifique de la Caldera de Luba','Luba Caldera Scientific Reserve','Bioko Sur','2026-10-06','Nature reserve','UNESCO World Heritage Centre — Tentative List 6945','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (226000002,226000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (226000002,226000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 226000002,id FROM tags WHERE tag_name='Nature reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (226000003,2260003,'Réserve naturelle d''Annobón (RNA)','Annobón Nature Reserve','Annobón','2026-10-06','Island nature reserve','UNESCO World Heritage Centre — Tentative List 6946','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (226000003,226000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (226000003,226000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 226000003,id FROM tags WHERE tag_name='Island nature reserve';
COMMIT;
