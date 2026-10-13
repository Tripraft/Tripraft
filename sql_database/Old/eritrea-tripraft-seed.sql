-- TripRaft canonical country seed
-- Country: Eritrea
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (232,'Eritrea','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (232001,232,'Maekel','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (232002,232,'Debub','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Archaeological cultural landscape');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage historic city');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2320001,232001,'Asmara','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2320002,232002,'Qohaito','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (232000001,2320001,'Asmara: A Modernist African City','Asmara: A Modernist African City','Maekel','2026-10-06','World heritage historic city','UNESCO World Heritage Centre — World Heritage property 1550','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (232000001,232000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (232000001,232000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 232000001,id FROM tags WHERE tag_name='World heritage historic city';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (232000002,2320002,'Qoahito Cultural Landscape','Qoahito Cultural Landscape','Debub','2026-10-06','Archaeological cultural landscape','UNESCO World Heritage Centre — Tentative List 5600','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (232000002,232000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (232000002,232000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 232000002,id FROM tags WHERE tag_name='Archaeological cultural landscape';
COMMIT;
