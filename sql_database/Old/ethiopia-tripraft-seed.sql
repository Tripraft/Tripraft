-- TripRaft canonical country seed
-- Country: Ethiopia
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre; provider-style metadata intentionally NULL.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (231,'Ethiopia','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (231001,231,'Amhara Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (231002,231,'Harari Region','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (231003,231,'Tigray Region','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage archaeological site');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage historic town');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World heritage religious site');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2310001,231001,'Lalibela','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2310002,231002,'Harar','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (2310003,231003,'Aksum','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (231000001,2310001,'Rock-Hewn Churches, Lalibela','Rock-Hewn Churches, Lalibela','Amhara Region','2026-10-06','World heritage religious site','UNESCO World Heritage Centre — World Heritage property 18','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (231000001,231000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (231000001,231000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 231000001,id FROM tags WHERE tag_name='World heritage religious site';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (231000002,2310002,'Harar Jugol, the Fortified Historic Town','Harar Jugol, the Fortified Historic Town','Harari Region','2026-10-06','World heritage historic town','UNESCO World Heritage Centre — World Heritage property 1189rev','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (231000002,231000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (231000002,231000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 231000002,id FROM tags WHERE tag_name='World heritage historic town';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,verification_status,verification_notes,verified_at) VALUES (231000003,2310003,'Aksum','Aksum','Tigray Region','2026-10-06','World heritage archaeological site','UNESCO World Heritage Centre — World Heritage property 15','partial','Identity and administrative placement checked against the cited authoritative source; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (231000003,231000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (231000003,231000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 231000003,id FROM tags WHERE tag_name='World heritage archaeological site';
COMMIT;
