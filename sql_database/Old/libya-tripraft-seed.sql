-- TripRaft canonical country seed
-- Country: Libya
-- Generated: 2026-10-06
-- Source basis: UNESCO World Heritage Centre; conventional district-level geographic parentage for stable seed mapping
-- Administrative model: The states table uses Libya district-level geographic parents for these World Heritage sites; municipal governance is subject to change and should be audited in a future administrative refresh.
-- Provider-style enrichment is intentionally NULL unless directly source/provider backed.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (434,'Libya','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (434001,434,'Al Marqab District','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (434002,434,'Az Zawiyah District','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (434003,434,'Al Jabal al Akhdar District','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (434004,434,'Nalut District','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (434005,434,'Ghat District','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage archaeological site');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage historic town');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('World Heritage rock art');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4340001,434001,'Al Khums','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4340002,434002,'Sabratha','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4340003,434003,'Shahat','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4340004,434004,'Ghadames','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4340005,434005,'Ghat','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (434000001,4340001,'Archaeological Site of Leptis Magna','Archaeological Site of Leptis Magna','Al Marqab District','2026-10-06','World Heritage archaeological site','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (434000001,434000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (434000001,434000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 434000001,id FROM tags WHERE tag_name='World Heritage archaeological site';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (434000002,4340002,'Archaeological Site of Sabratha','Archaeological Site of Sabratha','Az Zawiyah District','2026-10-06','World Heritage archaeological site','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (434000002,434000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (434000002,434000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 434000002,id FROM tags WHERE tag_name='World Heritage archaeological site';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (434000003,4340003,'Archaeological Site of Cyrene','Archaeological Site of Cyrene','Al Jabal al Akhdar District','2026-10-06','World Heritage archaeological site','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (434000003,434000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (434000003,434000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 434000003,id FROM tags WHERE tag_name='World Heritage archaeological site';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (434000004,4340004,'Old Town of Ghadamès','Old Town of Ghadamès','Nalut District','2026-10-06','World Heritage historic town','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (434000004,434000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (434000004,434000004,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 434000004,id FROM tags WHERE tag_name='World Heritage historic town';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (434000005,4340005,'Rock-Art Sites of Tadrart Acacus','Rock-Art Sites of Tadrart Acacus','Ghat District','2026-10-06','World Heritage rock art','UNESCO World Heritage Centre','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (434000005,434000005,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (434000005,434000005,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 434000005,id FROM tags WHERE tag_name='World Heritage rock art';
COMMIT;
