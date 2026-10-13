-- ============================================================================
-- TripRaft canonical country seed: Zambia
-- Generated: 2026-10-06
-- Canonical schema: v1.1
-- Verification model: source-backed place identity; provider-style live metadata intentionally NULL.
-- Administrative note: Official provinces are used as first-level parents. Large parks crossing provincial boundaries are represented under a documented real gateway.
-- Source basis:
--   - Zambia Tourism — National Parks: https://www.zambiatourism.com/destinations/national-parks/
--   - UNESCO World Heritage Centre — Zambia: https://whc.unesco.org/en/statesparties/zm
-- ============================================================================
PRAGMA foreign_keys = ON;

-- 1. countries
INSERT INTO countries (id,country_name,created_at) VALUES (894,'Zambia','2026-10-06');

-- 2. states
INSERT INTO states (id,country_id,state_name,created_at) VALUES (894001,894,'Southern Province','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (894002,894,'Eastern Province','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (894003,894,'Central Province','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (894004,894,'Western Province','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (894005,894,'Northern Province','2026-10-06');

-- 3. tags
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Museum');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Religious');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Viewpoint');

-- 4. cities
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940001,894001,'Livingstone',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940002,894002,'Mfuwe',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940003,894003,'Itezhi-Tezhi',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940004,894003,'Serenje',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940005,894004,'Kalabo',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940006,894004,'Sioma',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940007,894005,'Nsumbu',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940008,894005,'Mbala',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940009,894005,'Kasama',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (8940010,894004,'Mongu',NULL,NULL,'2026-10-06',2);

-- 5. places
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000001,8940001,'Mosi-oa-Tunya / Victoria Falls','Mosi-oa-Tunya / Victoria Falls',NULL,NULL,NULL,NULL,NULL,'Southern Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Nature',NULL,NULL,NULL,'UNESCO World Heritage Centre and Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000002,8940002,'South Luangwa National Park','South Luangwa National Park',NULL,NULL,NULL,NULL,NULL,'Eastern Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000003,8940003,'Kafue National Park','Kafue National Park',NULL,NULL,NULL,NULL,NULL,'Central Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL. Kafue National Park spans multiple provinces; Itezhi-Tezhi is used as a real southern/central gateway for this single-parent schema.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000004,8940004,'Kasanka National Park','Kasanka National Park',NULL,NULL,NULL,NULL,NULL,'Central Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000005,8940005,'Liuwa Plain National Park','Liuwa Plain National Park',NULL,NULL,NULL,NULL,NULL,'Western Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000006,8940006,'Sioma Ngwezi National Park','Sioma Ngwezi National Park',NULL,NULL,NULL,NULL,NULL,'Western Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000007,8940007,'Nsumbu National Park','Nsumbu National Park',NULL,NULL,NULL,NULL,NULL,'Northern Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Park',NULL,NULL,NULL,'Zambia Tourism','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000008,8940008,'Kalambo Falls National Monument','Kalambo Falls National Monument',NULL,NULL,NULL,NULL,NULL,'Northern Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Nature',NULL,NULL,NULL,'UNESCO World Heritage Centre — Zambia tentative list','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000009,8940009,'Mwela Rock Paintings','Mwela Rock Paintings',NULL,NULL,NULL,NULL,NULL,'Northern Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Heritage',NULL,NULL,NULL,'UNESCO World Heritage Centre — Zambia tentative list','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (894000010,8940010,'Barotse Cultural Landscape','Barotse Cultural Landscape',NULL,NULL,NULL,NULL,NULL,'Western Province',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Heritage',NULL,NULL,NULL,'UNESCO World Heritage Centre — Zambia tentative list','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');

-- 6. opening_hours
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000001,894000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000002,894000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000003,894000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000004,894000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000005,894000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000006,894000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000007,894000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000008,894000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000009,894000009,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (894000010,894000010,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');

-- 7. photos
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000001,894000001,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000002,894000002,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000003,894000003,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000004,894000004,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000005,894000005,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000006,894000006,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000007,894000007,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000008,894000008,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000009,894000009,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (894000010,894000010,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- 8. place_tags
INSERT INTO place_tags (place_id,tag_id) SELECT 894000001,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000002,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000003,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000004,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000005,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000006,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000007,id FROM tags WHERE tag_name='Park';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000008,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000009,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 894000010,id FROM tags WHERE tag_name='Heritage';

-- 9. festivals
-- No festival rows in this conservative verified core.
