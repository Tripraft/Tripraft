-- TripRaft canonical country seed
-- Country: Liberia
-- Generated: 2026-10-06
-- Source basis: Liberia National Tourism Authority / official Liberia Tourism portal; protected-area identity references
-- Administrative model: The states table uses Liberia counties.
-- Provider-style enrichment is intentionally NULL unless directly source/provider backed.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;
INSERT INTO countries (id,country_name,created_at) VALUES (430,'Liberia','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (430001,430,'Montserrado County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (430002,430,'Bong County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (430003,430,'Nimba County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (430004,430,'Sinoe County','2026-10-06');
INSERT INTO states (id,country_id,state_name,created_at) VALUES (430005,430,'Grand Cape Mount County','2026-10-06');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Historic site');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Waterfall');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('Nature reserve');
INSERT OR IGNORE INTO tags (tag_name) VALUES ('National park');
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4300001,430001,'Monrovia','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4300002,430002,'Kpatawee','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4300003,430003,'Yekepa','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4300004,430004,'Jalay Town','2026-10-06',2);
INSERT INTO cities (id,state_id,city_name,created_at,tier) VALUES (4300005,430005,'Robertsport','2026-10-06',2);
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (430000001,4300001,'Providence Island','Providence Island','Montserrado County','2026-10-06','Historic site','Liberia National Tourism Authority / official Liberia Tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (430000001,430000001,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (430000001,430000001,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 430000001,id FROM tags WHERE tag_name='Historic site';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (430000002,4300002,'Kpatawee Waterfall','Kpatawee Waterfall','Bong County','2026-10-06','Waterfall','Liberia National Tourism Authority / official Liberia Tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (430000002,430000002,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (430000002,430000002,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 430000002,id FROM tags WHERE tag_name='Waterfall';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (430000003,4300003,'East Nimba Nature Reserve','East Nimba Nature Reserve','Nimba County','2026-10-06','Nature reserve','Liberia National Tourism Authority / official Liberia Tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (430000003,430000003,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (430000003,430000003,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 430000003,id FROM tags WHERE tag_name='Nature reserve';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (430000004,4300004,'Sapo National Park','Sapo National Park','Sinoe County','2026-10-06','National park','Liberia National Tourism Authority / official Liberia Tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (430000004,430000004,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (430000004,430000004,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 430000004,id FROM tags WHERE tag_name='National park';
INSERT INTO places (id,city_id,place_name,name_english,state_name,created_at,category,source,updated_at,verification_status,verification_notes,verified_at) VALUES (430000005,4300005,'Lake Piso Multiple Use Reserve','Lake Piso Multiple Use Reserve','Grand Cape Mount County','2026-10-06','Nature reserve','Liberia National Tourism Authority / official Liberia Tourism portal','2026-10-06','partial','Place identity and administrative placement checked against the cited authoritative source basis; unsupported provider-style metadata intentionally NULL.','2026-10-06');
INSERT INTO opening_hours (id,place_id,notes) VALUES (430000005,430000005,'Exact hours require official/operator/provider refresh.');
INSERT INTO photos (id,place_id,usage_terms,photo_status) VALUES (430000005,430000005,'no-photo-available','no_match');
INSERT INTO place_tags (place_id,tag_id) SELECT 430000005,id FROM tags WHERE tag_name='Nature reserve';
COMMIT;
