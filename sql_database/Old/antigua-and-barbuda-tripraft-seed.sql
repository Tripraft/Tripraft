-- ============================================================================
-- TripRaft canonical country seed: Antigua and Barbuda
-- Generated: 2026-10-06
-- Canonical schema: v1.1
-- Verification model: source-backed place identity; provider-style live metadata intentionally NULL.
-- Administrative note: Antigua parishes and the Barbuda dependency are used as first-level parents.
-- Source basis:
--   - Antigua and Barbuda Tourism Authority: https://www.visitantiguabarbuda.com/things-to-do/
--   - UNESCO World Heritage Centre — Antigua Naval Dockyard: https://whc.unesco.org/en/list/1499
--   - Government of Antigua and Barbuda: https://ab.gov.ag/
-- ============================================================================
PRAGMA foreign_keys = ON;

-- 1. countries
INSERT INTO countries (id,country_name,created_at) VALUES (28,'Antigua and Barbuda','2026-10-06');

-- 2. states
INSERT INTO states (id,country_id,state_name,created_at) VALUES (28001,28,'Saint Paul Parish','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (28002,28,'Saint John Parish','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (28003,28,'Saint Peter Parish','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (28004,28,'Saint Philip Parish','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (28005,28,'Barbuda','2026-10-06');

-- 3. tags
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Heritage');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Museum');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Park');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Religious');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Viewpoint');

-- 4. cities
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (280001,28001,'English Harbour',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (280002,28002,'St. John’s',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (280003,28003,'Pares',NULL,NULL,'2026-10-06',1);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (280004,28004,'Willikies',NULL,NULL,'2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,latitude,longitude,created_at,tier) VALUES (280005,28005,'Codrington',NULL,NULL,'2026-10-06',2);

-- 5. places
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000001,280001,'Nelson’s Dockyard','Nelson’s Dockyard',NULL,NULL,NULL,NULL,NULL,'Saint Paul Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Heritage',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority and UNESCO','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000002,280001,'Nelson’s Dockyard Museum','Nelson’s Dockyard Museum',NULL,NULL,NULL,NULL,NULL,'Saint Paul Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Museum',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000003,280001,'Shirley Heights Lookout','Shirley Heights Lookout',NULL,NULL,NULL,NULL,NULL,'Saint Paul Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Viewpoint',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000004,280002,'Government House Museum','Government House Museum',NULL,NULL,NULL,NULL,NULL,'Saint John Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Museum',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000005,280003,'Betty’s Hope','Betty’s Hope',NULL,NULL,NULL,NULL,NULL,'Saint Peter Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Heritage',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000006,280004,'Devil’s Bridge','Devil’s Bridge',NULL,NULL,NULL,NULL,NULL,'Saint Philip Parish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Nature',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000007,280005,'Frigate Bird Sanctuary','Frigate Bird Sanctuary',NULL,NULL,NULL,NULL,NULL,'Barbuda',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Nature',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');
INSERT INTO places (id,city_id,place_name,name_english,ai_summary,suggested_duration,best_time_to_visit,place_tip,advanced_booking,state_name,sunrise_view,sunset_view,sunrise_time,sunset_time,cost,rating_tourist_priority,rating_traveler_experience,latitude,longitude,address,official_website,rank_score,created_at,google_place_id,category,cuisine,price_band,veg_flag,source,updated_at,verification_status,verification_notes,verified_at) VALUES (28000008,280005,'Martello Tower','Martello Tower',NULL,NULL,NULL,NULL,NULL,'Barbuda',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-06',NULL,'Heritage',NULL,NULL,NULL,'Antigua and Barbuda Tourism Authority','2026-10-06','partial','Place identity and administrative/gateway placement checked against authoritative/official sources; live provider-style metadata intentionally left NULL.','2026-10-06');

-- 6. opening_hours
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000001,28000001,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000002,28000002,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000003,28000003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000004,28000004,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000005,28000005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000006,28000006,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000007,28000007,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');
INSERT INTO opening_hours (id,place_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,notes) VALUES (28000008,28000008,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Exact opening hours require an official/operator/provider refresh; no schedule inferred in this seed.');

-- 7. photos
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000001,28000001,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000002,28000002,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000003,28000003,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000004,28000004,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000005,28000005,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000006,28000006,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000007,28000007,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');
INSERT INTO photos (id,place_id,photo_title,usage_terms,thumbnail_url,photo_url,photo_author,photo_license,photo_source_url,photo_status) VALUES (28000008,28000008,NULL,'no-photo-available',NULL,NULL,NULL,NULL,NULL,'no_match');

-- 8. place_tags
INSERT INTO place_tags (place_id,tag_id) SELECT 28000001,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000002,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000003,id FROM tags WHERE tag_name='Viewpoint';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000004,id FROM tags WHERE tag_name='Museum';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000005,id FROM tags WHERE tag_name='Heritage';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000006,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000007,id FROM tags WHERE tag_name='Nature';
INSERT INTO place_tags (place_id,tag_id) SELECT 28000008,id FROM tags WHERE tag_name='Heritage';

-- 9. festivals
-- No festival rows in this conservative verified core.
