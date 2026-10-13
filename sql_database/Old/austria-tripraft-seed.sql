-- ==========================================================================
-- TripRaft Places Seed : AUSTRIA (country-first broad coverage pass)
-- Generated: 2026-10-02
-- Country ID: 40 (ISO 3166-1 numeric 040 stored as integer; provisional until production reconciliation)
--
-- COVERAGE
--   * 9 Austrian federal states/provinces.
--   * 79 tourism city/destination rows across all provinces; variable coverage, no per-city quota.
--   * 475 stable named place records; operational details are omitted when not specifically verified.
--   * Every place has one opening_hours row, one photos row and >=1 place_tags row.
--   * google_place_id is NULL on every place by project rule.
--
-- DATA QUALITY RULES
--   * No unverified venue coordinates, hours, prices or ratings were guessed.
--   * City/venue coordinates are NULL in this pass; hours are blank with an explicit verification note.
--   * Photo rows use no_match rather than fabricated image/license metadata.
--   * verification_status is only 'verified' (UNESCO-confirmed property/component) or 'partial'.
--
-- BACKBONE SOURCES
--   Austria Tourism destinations: https://www.austria.info/en-gb/inspiration/destinations/
--   Austria Tourism cities: https://www.austria.info/en-gb/inspiration/cities/
--   Austria Tourism nine provinces: https://www.austria.info/en-gb/inspiration/provinces/
--   Austria Tourism small historic towns: https://www.austria.info/en-us/locations/small-historic-towns/
--   UNESCO Austria list: https://whc.unesco.org/en/statesparties/at/
--
-- PARENT SCHEMA ASSUMPTION
--   countries(id, country_name, created_at)
--   states(id, country_id, state_name, created_at)
-- Reconcile only this parent block if production uses different parent column names.
-- ==========================================================================

CREATE TABLE IF NOT EXISTS countries (id INTEGER PRIMARY KEY, country_name TEXT NOT NULL, created_at TEXT);
CREATE TABLE IF NOT EXISTS states (id INTEGER PRIMARY KEY, country_id INTEGER, state_name TEXT NOT NULL, created_at TEXT);
INSERT OR IGNORE INTO countries (id, country_name, created_at) VALUES (40, 'Austria', '2026-10-02 12:00:00');
INSERT OR IGNORE INTO states (id, country_id, state_name, created_at) VALUES
(4001, 40, 'Burgenland', '2026-10-02 12:00:00'),
(4002, 40, 'Carinthia', '2026-10-02 12:00:00'),
(4003, 40, 'Lower Austria', '2026-10-02 12:00:00'),
(4004, 40, 'Upper Austria', '2026-10-02 12:00:00'),
(4005, 40, 'Salzburg', '2026-10-02 12:00:00'),
(4006, 40, 'Styria', '2026-10-02 12:00:00'),
(4007, 40, 'Tyrol', '2026-10-02 12:00:00'),
(4008, 40, 'Vorarlberg', '2026-10-02 12:00:00'),
(4009, 40, 'Vienna', '2026-10-02 12:00:00');

-- ---- Cities: Austria ----
INSERT INTO cities (id, state_id, city_name, latitude, longitude, created_at, tier) VALUES
(400001, 4001, 'Eisenstadt', NULL, NULL, '2026-10-02 12:00:00', 2),
(400002, 4001, 'Rust', NULL, NULL, '2026-10-02 12:00:00', 3),
(400003, 4001, 'Neusiedl am See', NULL, NULL, '2026-10-02 12:00:00', 3),
(400004, 4001, 'Podersdorf am See', NULL, NULL, '2026-10-02 12:00:00', 3),
(400005, 4001, 'Mörbisch am See', NULL, NULL, '2026-10-02 12:00:00', 3),
(400006, 4001, 'Illmitz', NULL, NULL, '2026-10-02 12:00:00', 3),
(400007, 4001, 'Güssing', NULL, NULL, '2026-10-02 12:00:00', 3),
(400008, 4002, 'Klagenfurt', NULL, NULL, '2026-10-02 12:00:00', 1),
(400009, 4002, 'Villach', NULL, NULL, '2026-10-02 12:00:00', 2),
(400010, 4002, 'Velden am Wörthersee', NULL, NULL, '2026-10-02 12:00:00', 3),
(400011, 4002, 'Pörtschach am Wörthersee', NULL, NULL, '2026-10-02 12:00:00', 3),
(400012, 4002, 'Millstatt', NULL, NULL, '2026-10-02 12:00:00', 3),
(400013, 4002, 'Bad Kleinkirchheim', NULL, NULL, '2026-10-02 12:00:00', 3),
(400014, 4002, 'Heiligenblut', NULL, NULL, '2026-10-02 12:00:00', 2),
(400015, 4002, 'Spittal an der Drau', NULL, NULL, '2026-10-02 12:00:00', 3),
(400016, 4002, 'Wolfsberg', NULL, NULL, '2026-10-02 12:00:00', 3),
(400017, 4003, 'St. Pölten', NULL, NULL, '2026-10-02 12:00:00', 2),
(400018, 4003, 'Krems an der Donau', NULL, NULL, '2026-10-02 12:00:00', 2),
(400019, 4003, 'Melk', NULL, NULL, '2026-10-02 12:00:00', 2),
(400020, 4003, 'Dürnstein', NULL, NULL, '2026-10-02 12:00:00', 2),
(400021, 4003, 'Baden bei Wien', NULL, NULL, '2026-10-02 12:00:00', 2),
(400022, 4003, 'Wiener Neustadt', NULL, NULL, '2026-10-02 12:00:00', 2),
(400023, 4003, 'Klosterneuburg', NULL, NULL, '2026-10-02 12:00:00', 3),
(400024, 4003, 'Semmering', NULL, NULL, '2026-10-02 12:00:00', 2),
(400025, 4003, 'Petronell-Carnuntum', NULL, NULL, '2026-10-02 12:00:00', 3),
(400026, 4003, 'Hainburg an der Donau', NULL, NULL, '2026-10-02 12:00:00', 3),
(400027, 4003, 'Retz', NULL, NULL, '2026-10-02 12:00:00', 3),
(400028, 4003, 'Waidhofen an der Ybbs', NULL, NULL, '2026-10-02 12:00:00', 3),
(400029, 4004, 'Linz', NULL, NULL, '2026-10-02 12:00:00', 1),
(400030, 4004, 'Hallstatt', NULL, NULL, '2026-10-02 12:00:00', 1),
(400031, 4004, 'Bad Ischl', NULL, NULL, '2026-10-02 12:00:00', 2),
(400032, 4004, 'Steyr', NULL, NULL, '2026-10-02 12:00:00', 2),
(400033, 4004, 'Gmunden', NULL, NULL, '2026-10-02 12:00:00', 2),
(400034, 4004, 'St. Wolfgang im Salzkammergut', NULL, NULL, '2026-10-02 12:00:00', 2),
(400035, 4004, 'Mondsee', NULL, NULL, '2026-10-02 12:00:00', 3),
(400036, 4004, 'Schärding', NULL, NULL, '2026-10-02 12:00:00', 3),
(400037, 4004, 'Freistadt', NULL, NULL, '2026-10-02 12:00:00', 3),
(400038, 4004, 'Obertraun', NULL, NULL, '2026-10-02 12:00:00', 2),
(400039, 4004, 'Braunau am Inn', NULL, NULL, '2026-10-02 12:00:00', 3),
(400040, 4005, 'Salzburg', NULL, NULL, '2026-10-02 12:00:00', 1),
(400041, 4005, 'Zell am See', NULL, NULL, '2026-10-02 12:00:00', 1),
(400042, 4005, 'Kaprun', NULL, NULL, '2026-10-02 12:00:00', 2),
(400043, 4005, 'Bad Gastein', NULL, NULL, '2026-10-02 12:00:00', 2),
(400044, 4005, 'Hallein', NULL, NULL, '2026-10-02 12:00:00', 2),
(400045, 4005, 'Werfen', NULL, NULL, '2026-10-02 12:00:00', 3),
(400046, 4005, 'Radstadt', NULL, NULL, '2026-10-02 12:00:00', 3),
(400047, 4005, 'Mittersill', NULL, NULL, '2026-10-02 12:00:00', 3),
(400048, 4005, 'Saalbach-Hinterglemm', NULL, NULL, '2026-10-02 12:00:00', 2),
(400049, 4005, 'Obertauern', NULL, NULL, '2026-10-02 12:00:00', 2),
(400050, 4006, 'Graz', NULL, NULL, '2026-10-02 12:00:00', 1),
(400051, 4006, 'Schladming', NULL, NULL, '2026-10-02 12:00:00', 1),
(400052, 4006, 'Mariazell', NULL, NULL, '2026-10-02 12:00:00', 2),
(400053, 4006, 'Admont', NULL, NULL, '2026-10-02 12:00:00', 2),
(400054, 4006, 'Bad Aussee', NULL, NULL, '2026-10-02 12:00:00', 3),
(400055, 4006, 'Eisenerz', NULL, NULL, '2026-10-02 12:00:00', 3),
(400056, 4006, 'Bad Radkersburg', NULL, NULL, '2026-10-02 12:00:00', 3),
(400057, 4006, 'Fürstenfeld', NULL, NULL, '2026-10-02 12:00:00', 3),
(400058, 4006, 'Hartberg', NULL, NULL, '2026-10-02 12:00:00', 3),
(400059, 4006, 'Judenburg', NULL, NULL, '2026-10-02 12:00:00', 3),
(400060, 4007, 'Innsbruck', NULL, NULL, '2026-10-02 12:00:00', 1),
(400061, 4007, 'Kitzbühel', NULL, NULL, '2026-10-02 12:00:00', 1),
(400062, 4007, 'Kufstein', NULL, NULL, '2026-10-02 12:00:00', 2),
(400063, 4007, 'Seefeld in Tirol', NULL, NULL, '2026-10-02 12:00:00', 2),
(400064, 4007, 'Mayrhofen', NULL, NULL, '2026-10-02 12:00:00', 2),
(400065, 4007, 'St. Anton am Arlberg', NULL, NULL, '2026-10-02 12:00:00', 1),
(400066, 4007, 'Sölden', NULL, NULL, '2026-10-02 12:00:00', 1),
(400067, 4007, 'Lienz', NULL, NULL, '2026-10-02 12:00:00', 2),
(400068, 4007, 'Hall in Tirol', NULL, NULL, '2026-10-02 12:00:00', 3),
(400069, 4007, 'Alpbach', NULL, NULL, '2026-10-02 12:00:00', 2),
(400070, 4007, 'Ischgl', NULL, NULL, '2026-10-02 12:00:00', 2),
(400071, 4007, 'Pertisau am Achensee', NULL, NULL, '2026-10-02 12:00:00', 2),
(400072, 4008, 'Bregenz', NULL, NULL, '2026-10-02 12:00:00', 1),
(400073, 4008, 'Feldkirch', NULL, NULL, '2026-10-02 12:00:00', 2),
(400074, 4008, 'Dornbirn', NULL, NULL, '2026-10-02 12:00:00', 2),
(400075, 4008, 'Bludenz', NULL, NULL, '2026-10-02 12:00:00', 3),
(400076, 4008, 'Lech am Arlberg', NULL, NULL, '2026-10-02 12:00:00', 1),
(400077, 4008, 'Schruns', NULL, NULL, '2026-10-02 12:00:00', 2),
(400078, 4008, 'Bezau', NULL, NULL, '2026-10-02 12:00:00', 3),
(400079, 4009, 'Vienna', NULL, NULL, '2026-10-02 12:00:00', 1);

-- ---- Shared tag vocabulary (idempotent) ----
INSERT OR IGNORE INTO tags (tag_name) VALUES
('Abbey'),
('Adventure'),
('Archaeology'),
('Architecture'),
('Art'),
('Attraction'),
('Boating'),
('Cable Car'),
('Castle'),
('Cathedral'),
('Caves'),
('Church'),
('Culture'),
('Design'),
('Family'),
('Food'),
('Fortress'),
('Garden'),
('Heritage'),
('Hiking'),
('Historic Center'),
('History'),
('Industrial Heritage'),
('Lake'),
('Library'),
('Market'),
('Monastery'),
('Mountain'),
('Museum'),
('Music'),
('Nature'),
('Palace'),
('Park'),
('Photography'),
('Railway'),
('Religious'),
('River'),
('Scenic Drive'),
('Shopping'),
('Skiing'),
('Spa'),
('Transport'),
('UNESCO'),
('Viewpoint'),
('Walking'),
('Waterfall'),
('Wellness'),
('Wildlife'),
('Zoo');

-- ============================================================================
-- CITY 001 : EISENSTADT (id 400001) — 8 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000001, 400001, 'Esterházy Palace', 'Esterházy Palace', 'A major palace and architectural attraction in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Esterházy Palace, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000002, 400001, 'Haydn House Eisenstadt', 'Haydn House Eisenstadt', 'A museum and cultural attraction in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Haydn House Eisenstadt, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000003, 400001, 'Bergkirche (Haydn Church)', 'Bergkirche (Haydn Church)', 'A historic church and religious landmark in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bergkirche (Haydn Church), Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000004, 400001, 'Calvary Eisenstadt', 'Calvary Eisenstadt', 'A religious and cultural landmark in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Calvary Eisenstadt, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000005, 400001, 'Schlosspark Eisenstadt', 'Schlosspark Eisenstadt', 'An urban park and leisure attraction in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schlosspark Eisenstadt, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000006, 400001, 'Landesmuseum Burgenland', 'Landesmuseum Burgenland', 'A museum and cultural attraction in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Landesmuseum Burgenland, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000007, 400001, 'St. Martin’s Cathedral Eisenstadt', 'St. Martin’s Cathedral Eisenstadt', 'A cathedral and architectural landmark in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Martin’s Cathedral Eisenstadt, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000008, 400001, 'Austrian Jewish Museum Eisenstadt', 'Austrian Jewish Museum Eisenstadt', 'A museum and cultural attraction in Eisenstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Austrian Jewish Museum Eisenstadt, Eisenstadt, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Eisenstadt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000001, 40000001, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000002, 40000002, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000003, 40000003, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000004, 40000004, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000005, 40000005, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000006, 40000006, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000007, 40000007, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000008, 40000008, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Eisenstadt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000001, 40000001, 'Esterházy Palace Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000002, 40000002, 'Haydn House Eisenstadt Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000003, 40000003, 'Bergkirche (Haydn Church) Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000004, 40000004, 'Calvary Eisenstadt Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000005, 40000005, 'Schlosspark Eisenstadt Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000006, 40000006, 'Landesmuseum Burgenland Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000007, 40000007, 'St. Martin’s Cathedral Eisenstadt Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000008, 40000008, 'Austrian Jewish Museum Eisenstadt Eisenstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 002 : RUST (id 400002) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000009, 400002, 'Historic Centre of Rust', 'Historic Centre of Rust', 'A historic centre suited to walking and architecture in Rust, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Historic Centre of Rust, Rust, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000010, 400002, 'Fischerkirche Rust', 'Fischerkirche Rust', 'A historic church and religious landmark in Rust, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Fischerkirche Rust, Rust, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000011, 400002, 'Rathaus Rust', 'Rathaus Rust', 'A heritage landmark in Rust, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rathaus Rust, Rust, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000012, 400002, 'Kremayrhaus Stadtmuseum Rust', 'Kremayrhaus Stadtmuseum Rust', 'A museum and cultural attraction in Rust, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kremayrhaus Stadtmuseum Rust, Rust, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000013, 400002, 'Lake Neusiedl Waterfront Rust', 'Lake Neusiedl Waterfront Rust', 'A lake and outdoor recreation destination in Rust, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Neusiedl Waterfront Rust, Rust, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Rust ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000009, 40000009, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000010, 40000010, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000011, 40000011, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000012, 40000012, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000013, 40000013, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Rust ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000009, 40000009, 'Historic Centre of Rust Rust', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000010, 40000010, 'Fischerkirche Rust Rust', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000011, 40000011, 'Rathaus Rust Rust', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000012, 40000012, 'Kremayrhaus Stadtmuseum Rust Rust', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000013, 40000013, 'Lake Neusiedl Waterfront Rust Rust', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 003 : NEUSIEDL AM SEE (id 400003) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000014, 400003, 'Fertö / Neusiedlersee Cultural Landscape', 'Fertö / Neusiedlersee Cultural Landscape', 'A UNESCO World Heritage property or Austrian component in Neusiedl am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Fertö / Neusiedlersee Cultural Landscape, Neusiedl am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000015, 400003, 'Lake Neusiedl', 'Lake Neusiedl', 'A lake and outdoor recreation destination in Neusiedl am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Neusiedl, Neusiedl am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000016, 400003, 'Neusiedl am See Lakeside Promenade', 'Neusiedl am See Lakeside Promenade', 'A lake and outdoor recreation destination in Neusiedl am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Neusiedl am See Lakeside Promenade, Neusiedl am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000017, 400003, 'Tabor Ruin', 'Tabor Ruin', 'A heritage landmark in Neusiedl am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tabor Ruin, Neusiedl am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000018, 400003, 'St. Nicholas Parish Church Neusiedl', 'St. Nicholas Parish Church Neusiedl', 'A historic church and religious landmark in Neusiedl am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Nicholas Parish Church Neusiedl, Neusiedl am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Neusiedl am See ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000014, 40000014, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000015, 40000015, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000016, 40000016, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000017, 40000017, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000018, 40000018, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Neusiedl am See ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000014, 40000014, 'Fertö / Neusiedlersee Cultural Landscape Neusiedl am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000015, 40000015, 'Lake Neusiedl Neusiedl am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000016, 40000016, 'Neusiedl am See Lakeside Promenade Neusiedl am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000017, 40000017, 'Tabor Ruin Neusiedl am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000018, 40000018, 'St. Nicholas Parish Church Neusiedl Neusiedl am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 004 : PODERSDORF AM SEE (id 400004) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000019, 400004, 'Podersdorf Lighthouse', 'Podersdorf Lighthouse', 'A scenic viewpoint and photography stop in Podersdorf am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Podersdorf Lighthouse, Podersdorf am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000020, 400004, 'Seebad Podersdorf', 'Seebad Podersdorf', 'A lake and outdoor recreation destination in Podersdorf am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Seebad Podersdorf, Podersdorf am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000021, 400004, 'Podersdorf Windmill', 'Podersdorf Windmill', 'A heritage landmark in Podersdorf am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Podersdorf Windmill, Podersdorf am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000022, 400004, 'Lake Neusiedl at Podersdorf', 'Lake Neusiedl at Podersdorf', 'A lake and outdoor recreation destination in Podersdorf am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Neusiedl at Podersdorf, Podersdorf am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000023, 400004, 'Podersdorf Parish Church', 'Podersdorf Parish Church', 'A historic church and religious landmark in Podersdorf am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Podersdorf Parish Church, Podersdorf am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Podersdorf am See ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000019, 40000019, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000020, 40000020, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000021, 40000021, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000022, 40000022, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000023, 40000023, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Podersdorf am See ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000019, 40000019, 'Podersdorf Lighthouse Podersdorf am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000020, 40000020, 'Seebad Podersdorf Podersdorf am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000021, 40000021, 'Podersdorf Windmill Podersdorf am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000022, 40000022, 'Lake Neusiedl at Podersdorf Podersdorf am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000023, 40000023, 'Podersdorf Parish Church Podersdorf am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 005 : MÖRBISCH AM SEE (id 400005) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000024, 400005, 'Seebühne Mörbisch', 'Seebühne Mörbisch', 'A music and performing-arts attraction in Mörbisch am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Seebühne Mörbisch, Mörbisch am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000025, 400005, 'Mörbisch Lakeside', 'Mörbisch Lakeside', 'A lake and outdoor recreation destination in Mörbisch am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mörbisch Lakeside, Mörbisch am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000026, 400005, 'Heimathaus Mörbisch', 'Heimathaus Mörbisch', 'A museum and cultural attraction in Mörbisch am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Heimathaus Mörbisch, Mörbisch am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000027, 400005, 'St. Michael Parish Church Mörbisch', 'St. Michael Parish Church Mörbisch', 'A historic church and religious landmark in Mörbisch am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Michael Parish Church Mörbisch, Mörbisch am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000028, 400005, 'Mörbisch Wine Lanes', 'Mörbisch Wine Lanes', 'A food and regional-culture experience in Mörbisch am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mörbisch Wine Lanes, Mörbisch am See, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Mörbisch am See ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000024, 40000024, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000025, 40000025, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000026, 40000026, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000027, 40000027, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000028, 40000028, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Mörbisch am See ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000024, 40000024, 'Seebühne Mörbisch Mörbisch am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000025, 40000025, 'Mörbisch Lakeside Mörbisch am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000026, 40000026, 'Heimathaus Mörbisch Mörbisch am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000027, 40000027, 'St. Michael Parish Church Mörbisch Mörbisch am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000028, 40000028, 'Mörbisch Wine Lanes Mörbisch am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 006 : ILLMITZ (id 400006) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000029, 400006, 'Neusiedler See–Seewinkel National Park', 'Neusiedler See–Seewinkel National Park', 'A nature and outdoor recreation attraction in Illmitz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Neusiedler See–Seewinkel National Park, Illmitz, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000030, 400006, 'Lange Lacke', 'Lange Lacke', 'A nature and outdoor recreation attraction in Illmitz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lange Lacke, Illmitz, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000031, 400006, 'National Park Information Centre Illmitz', 'National Park Information Centre Illmitz', 'A museum and cultural attraction in Illmitz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'National Park Information Centre Illmitz, Illmitz, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000032, 400006, 'St. Bartholomew Church Illmitz', 'St. Bartholomew Church Illmitz', 'A historic church and religious landmark in Illmitz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Bartholomew Church Illmitz, Illmitz, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000033, 400006, 'Illmitz Wine Cellar District', 'Illmitz Wine Cellar District', 'A food and regional-culture experience in Illmitz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Illmitz Wine Cellar District, Illmitz, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Illmitz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000029, 40000029, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000030, 40000030, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000031, 40000031, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000032, 40000032, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000033, 40000033, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Illmitz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000029, 40000029, 'Neusiedler See–Seewinkel National Park Illmitz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000030, 40000030, 'Lange Lacke Illmitz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000031, 40000031, 'National Park Information Centre Illmitz Illmitz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000032, 40000032, 'St. Bartholomew Church Illmitz Illmitz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000033, 40000033, 'Illmitz Wine Cellar District Illmitz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 007 : GÜSSING (id 400007) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000034, 400007, 'Güssing Castle', 'Güssing Castle', 'A historic castle and heritage attraction in Güssing, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Güssing Castle, Güssing, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000035, 400007, 'Burgmuseum Güssing', 'Burgmuseum Güssing', 'A museum and cultural attraction in Güssing, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Burgmuseum Güssing, Güssing, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000036, 400007, 'Franciscan Monastery Güssing', 'Franciscan Monastery Güssing', 'A historic monastery and religious landmark in Güssing, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Franciscan Monastery Güssing, Güssing, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000037, 400007, 'Güssing Old Town', 'Güssing Old Town', 'A historic centre suited to walking and architecture in Güssing, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Burgenland', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Güssing Old Town, Güssing, Burgenland, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Güssing ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000034, 40000034, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000035, 40000035, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000036, 40000036, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000037, 40000037, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Güssing ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000034, 40000034, 'Güssing Castle Güssing', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000035, 40000035, 'Burgmuseum Güssing Güssing', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000036, 40000036, 'Franciscan Monastery Güssing Güssing', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000037, 40000037, 'Güssing Old Town Güssing', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 008 : KLAGENFURT (id 400008) — 10 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000038, 400008, 'Minimundus', 'Minimundus', 'A family-oriented visitor attraction in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Minimundus, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000039, 400008, 'Lake Wörthersee', 'Lake Wörthersee', 'A lake and outdoor recreation destination in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Wörthersee, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000040, 400008, 'Lindwurm Fountain', 'Lindwurm Fountain', 'A heritage landmark in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lindwurm Fountain, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000041, 400008, 'Landhaus Klagenfurt', 'Landhaus Klagenfurt', 'A heritage landmark in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Landhaus Klagenfurt, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000042, 400008, 'Neuer Platz', 'Neuer Platz', 'A historic centre suited to walking and architecture in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Neuer Platz, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000043, 400008, 'Klagenfurt Cathedral', 'Klagenfurt Cathedral', 'A cathedral and architectural landmark in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Klagenfurt Cathedral, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000044, 400008, 'Museum of Modern Art Carinthia', 'Museum of Modern Art Carinthia', 'A museum and cultural attraction in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum of Modern Art Carinthia, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000045, 400008, 'Reptilienzoo Happ', 'Reptilienzoo Happ', 'A wildlife and family attraction in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Reptilienzoo Happ, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000046, 400008, 'Europapark Klagenfurt', 'Europapark Klagenfurt', 'An urban park and leisure attraction in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Europapark Klagenfurt, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000047, 400008, 'Maria Loretto Castle', 'Maria Loretto Castle', 'A historic castle and heritage attraction in Klagenfurt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Maria Loretto Castle, Klagenfurt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Klagenfurt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000038, 40000038, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000039, 40000039, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000040, 40000040, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000041, 40000041, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000042, 40000042, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000043, 40000043, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000044, 40000044, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000045, 40000045, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000046, 40000046, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000047, 40000047, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Klagenfurt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000038, 40000038, 'Minimundus Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000039, 40000039, 'Lake Wörthersee Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000040, 40000040, 'Lindwurm Fountain Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000041, 40000041, 'Landhaus Klagenfurt Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000042, 40000042, 'Neuer Platz Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000043, 40000043, 'Klagenfurt Cathedral Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000044, 40000044, 'Museum of Modern Art Carinthia Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000045, 40000045, 'Reptilienzoo Happ Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000046, 40000046, 'Europapark Klagenfurt Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000047, 40000047, 'Maria Loretto Castle Klagenfurt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 009 : VILLACH (id 400009) — 9 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000048, 400009, 'Villach Hauptplatz', 'Villach Hauptplatz', 'A historic centre suited to walking and architecture in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Villach Hauptplatz, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000049, 400009, 'St. Jakob Parish Church', 'St. Jakob Parish Church', 'A historic church and religious landmark in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Jakob Parish Church, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000050, 400009, 'Villach City Museum', 'Villach City Museum', 'A museum and cultural attraction in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Villach City Museum, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000051, 400009, 'Villach Alpine Road', 'Villach Alpine Road', 'A scenic mountain driving route in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-5 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Villach Alpine Road, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000052, 400009, 'Dobratsch Nature Park', 'Dobratsch Nature Park', 'A nature and outdoor recreation attraction in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dobratsch Nature Park, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000053, 400009, 'Warmbad Villach', 'Warmbad Villach', 'A thermal spa and wellness attraction in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Warmbad Villach, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000054, 400009, 'Landskron Castle', 'Landskron Castle', 'A historic castle and heritage attraction in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Landskron Castle, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000055, 400009, 'Affenberg Landskron', 'Affenberg Landskron', 'A wildlife and family attraction in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Affenberg Landskron, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000056, 400009, 'Lake Faak', 'Lake Faak', 'A lake and outdoor recreation destination in Villach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Faak, Villach, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Villach ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000048, 40000048, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000049, 40000049, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000050, 40000050, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000051, 40000051, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000052, 40000052, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000053, 40000053, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000054, 40000054, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000055, 40000055, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000056, 40000056, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Villach ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000048, 40000048, 'Villach Hauptplatz Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000049, 40000049, 'St. Jakob Parish Church Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000050, 40000050, 'Villach City Museum Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000051, 40000051, 'Villach Alpine Road Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000052, 40000052, 'Dobratsch Nature Park Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000053, 40000053, 'Warmbad Villach Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000054, 40000054, 'Landskron Castle Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000055, 40000055, 'Affenberg Landskron Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000056, 40000056, 'Lake Faak Villach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 010 : VELDEN AM WÖRTHERSEE (id 400010) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000057, 400010, 'Schloss Velden', 'Schloss Velden', 'A major palace and architectural attraction in Velden am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Velden, Velden am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000058, 400010, 'Wörthersee Promenade Velden', 'Wörthersee Promenade Velden', 'A lake and outdoor recreation destination in Velden am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wörthersee Promenade Velden, Velden am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000059, 400010, 'Casino Velden', 'Casino Velden', 'A notable visitor attraction in Velden am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Casino Velden, Velden am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000060, 400010, 'Kurpark Velden', 'Kurpark Velden', 'An urban park and leisure attraction in Velden am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kurpark Velden, Velden am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000061, 400010, 'Velden Lakeside Beach', 'Velden Lakeside Beach', 'A lake and outdoor recreation destination in Velden am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Velden Lakeside Beach, Velden am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Velden am Wörthersee ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000057, 40000057, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000058, 40000058, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000059, 40000059, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000060, 40000060, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000061, 40000061, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Velden am Wörthersee ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000057, 40000057, 'Schloss Velden Velden am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000058, 40000058, 'Wörthersee Promenade Velden Velden am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000059, 40000059, 'Casino Velden Velden am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000060, 40000060, 'Kurpark Velden Velden am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000061, 40000061, 'Velden Lakeside Beach Velden am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 011 : PÖRTSCHACH AM WÖRTHERSEE (id 400011) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000062, 400011, 'Wörthersee Promenade Pörtschach', 'Wörthersee Promenade Pörtschach', 'A lake and outdoor recreation destination in Pörtschach am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wörthersee Promenade Pörtschach, Pörtschach am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000063, 400011, 'Werzer’s Badehaus', 'Werzer’s Badehaus', 'A heritage landmark in Pörtschach am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Werzer’s Badehaus, Pörtschach am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000064, 400011, 'Johannes Brahms Promenade', 'Johannes Brahms Promenade', 'An urban park and leisure attraction in Pörtschach am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Johannes Brahms Promenade, Pörtschach am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000065, 400011, 'Hohe Gloriette Viewpoint', 'Hohe Gloriette Viewpoint', 'A scenic viewpoint and photography stop in Pörtschach am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hohe Gloriette Viewpoint, Pörtschach am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000066, 400011, 'St. John Parish Church Pörtschach', 'St. John Parish Church Pörtschach', 'A historic church and religious landmark in Pörtschach am Wörthersee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. John Parish Church Pörtschach, Pörtschach am Wörthersee, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Pörtschach am Wörthersee ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000062, 40000062, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000063, 40000063, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000064, 40000064, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000065, 40000065, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000066, 40000066, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Pörtschach am Wörthersee ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000062, 40000062, 'Wörthersee Promenade Pörtschach Pörtschach am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000063, 40000063, 'Werzer’s Badehaus Pörtschach am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000064, 40000064, 'Johannes Brahms Promenade Pörtschach am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000065, 40000065, 'Hohe Gloriette Viewpoint Pörtschach am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000066, 40000066, 'St. John Parish Church Pörtschach Pörtschach am Wörthersee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 012 : MILLSTATT (id 400012) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000067, 400012, 'Millstatt Abbey', 'Millstatt Abbey', 'A historic abbey and cultural landmark in Millstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Millstatt Abbey, Millstatt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000068, 400012, 'Lake Millstatt', 'Lake Millstatt', 'A lake and outdoor recreation destination in Millstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Millstatt, Millstatt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000069, 400012, 'Stiftsmuseum Millstatt', 'Stiftsmuseum Millstatt', 'A museum and cultural attraction in Millstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stiftsmuseum Millstatt, Millstatt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000070, 400012, 'Millstatt Lakeside Promenade', 'Millstatt Lakeside Promenade', 'A lake and outdoor recreation destination in Millstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Millstatt Lakeside Promenade, Millstatt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000071, 400012, 'Millstätter Alpe', 'Millstätter Alpe', 'A nature and outdoor recreation attraction in Millstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Millstätter Alpe, Millstatt, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Millstatt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000067, 40000067, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000068, 40000068, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000069, 40000069, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000070, 40000070, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000071, 40000071, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Millstatt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000067, 40000067, 'Millstatt Abbey Millstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000068, 40000068, 'Lake Millstatt Millstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000069, 40000069, 'Stiftsmuseum Millstatt Millstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000070, 40000070, 'Millstatt Lakeside Promenade Millstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000071, 40000071, 'Millstätter Alpe Millstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 013 : BAD KLEINKIRCHHEIM (id 400013) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000072, 400013, 'Römerbad Thermal Spa', 'Römerbad Thermal Spa', 'A thermal spa and wellness attraction in Bad Kleinkirchheim, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Römerbad Thermal Spa, Bad Kleinkirchheim, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000073, 400013, 'St. Kathrein Thermal Spa', 'St. Kathrein Thermal Spa', 'A thermal spa and wellness attraction in Bad Kleinkirchheim, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Kathrein Thermal Spa, Bad Kleinkirchheim, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000074, 400013, 'Kaiserburgbahn', 'Kaiserburgbahn', 'A mountain cable-car experience and scenic access point in Bad Kleinkirchheim, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kaiserburgbahn, Bad Kleinkirchheim, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000075, 400013, 'Nockberge Biosphere Park Gateway', 'Nockberge Biosphere Park Gateway', 'A nature and outdoor recreation attraction in Bad Kleinkirchheim, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Nockberge Biosphere Park Gateway, Bad Kleinkirchheim, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000076, 400013, 'St. Kathrein Church Bad Kleinkirchheim', 'St. Kathrein Church Bad Kleinkirchheim', 'A historic church and religious landmark in Bad Kleinkirchheim, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Kathrein Church Bad Kleinkirchheim, Bad Kleinkirchheim, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bad Kleinkirchheim ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000072, 40000072, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000073, 40000073, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000074, 40000074, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000075, 40000075, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000076, 40000076, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bad Kleinkirchheim ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000072, 40000072, 'Römerbad Thermal Spa Bad Kleinkirchheim', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000073, 40000073, 'St. Kathrein Thermal Spa Bad Kleinkirchheim', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000074, 40000074, 'Kaiserburgbahn Bad Kleinkirchheim', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000075, 40000075, 'Nockberge Biosphere Park Gateway Bad Kleinkirchheim', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000076, 40000076, 'St. Kathrein Church Bad Kleinkirchheim Bad Kleinkirchheim', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 014 : HEILIGENBLUT (id 400014) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000077, 400014, 'Grossglockner High Alpine Road', 'Grossglockner High Alpine Road', 'A scenic mountain driving route in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-5 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Grossglockner High Alpine Road, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000078, 400014, 'St. Vincent Parish Church Heiligenblut', 'St. Vincent Parish Church Heiligenblut', 'A historic church and religious landmark in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Vincent Parish Church Heiligenblut, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000079, 400014, 'Schareck Cable Car', 'Schareck Cable Car', 'A mountain cable-car experience and scenic access point in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schareck Cable Car, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000080, 400014, 'Pasterze Glacier Viewpoint', 'Pasterze Glacier Viewpoint', 'A scenic viewpoint and photography stop in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pasterze Glacier Viewpoint, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000081, 400014, 'Hohe Tauern National Park', 'Hohe Tauern National Park', 'A nature and outdoor recreation attraction in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hohe Tauern National Park, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000082, 400014, 'Gamsgrubenweg', 'Gamsgrubenweg', 'A hiking and nature area in Heiligenblut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gamsgrubenweg, Heiligenblut, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Heiligenblut ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000077, 40000077, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000078, 40000078, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000079, 40000079, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000080, 40000080, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000081, 40000081, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000082, 40000082, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Heiligenblut ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000077, 40000077, 'Grossglockner High Alpine Road Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000078, 40000078, 'St. Vincent Parish Church Heiligenblut Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000079, 40000079, 'Schareck Cable Car Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000080, 40000080, 'Pasterze Glacier Viewpoint Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000081, 40000081, 'Hohe Tauern National Park Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000082, 40000082, 'Gamsgrubenweg Heiligenblut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 015 : SPITTAL AN DER DRAU (id 400015) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000083, 400015, 'Schloss Porcia', 'Schloss Porcia', 'A major palace and architectural attraction in Spittal an der Drau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Porcia, Spittal an der Drau, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000084, 400015, 'Museum für Volkskultur', 'Museum für Volkskultur', 'A museum and cultural attraction in Spittal an der Drau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum für Volkskultur, Spittal an der Drau, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000085, 400015, 'Stadtpark Spittal', 'Stadtpark Spittal', 'An urban park and leisure attraction in Spittal an der Drau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpark Spittal, Spittal an der Drau, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000086, 400015, 'Spittal Parish Church', 'Spittal Parish Church', 'A historic church and religious landmark in Spittal an der Drau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Spittal Parish Church, Spittal an der Drau, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000087, 400015, 'Goldeck Mountain', 'Goldeck Mountain', 'A mountain and alpine recreation attraction in Spittal an der Drau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Goldeck Mountain, Spittal an der Drau, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Spittal an der Drau ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000083, 40000083, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000084, 40000084, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000085, 40000085, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000086, 40000086, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000087, 40000087, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Spittal an der Drau ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000083, 40000083, 'Schloss Porcia Spittal an der Drau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000084, 40000084, 'Museum für Volkskultur Spittal an der Drau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000085, 40000085, 'Stadtpark Spittal Spittal an der Drau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000086, 40000086, 'Spittal Parish Church Spittal an der Drau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000087, 40000087, 'Goldeck Mountain Spittal an der Drau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 016 : WOLFSBERG (id 400016) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000088, 400016, 'Wolfsberg Castle', 'Wolfsberg Castle', 'A historic castle and heritage attraction in Wolfsberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wolfsberg Castle, Wolfsberg, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000089, 400016, 'Wolfsberg Old Town', 'Wolfsberg Old Town', 'A historic centre suited to walking and architecture in Wolfsberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wolfsberg Old Town, Wolfsberg, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000090, 400016, 'St. Mark’s Parish Church Wolfsberg', 'St. Mark’s Parish Church Wolfsberg', 'A historic church and religious landmark in Wolfsberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Mark’s Parish Church Wolfsberg, Wolfsberg, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000091, 400016, 'Museum im Lavanthaus', 'Museum im Lavanthaus', 'A museum and cultural attraction in Wolfsberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum im Lavanthaus, Wolfsberg, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000092, 400016, 'Koralpe', 'Koralpe', 'A mountain and alpine recreation attraction in Wolfsberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Carinthia', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Koralpe, Wolfsberg, Carinthia, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Wolfsberg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000088, 40000088, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000089, 40000089, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000090, 40000090, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000091, 40000091, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000092, 40000092, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Wolfsberg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000088, 40000088, 'Wolfsberg Castle Wolfsberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000089, 40000089, 'Wolfsberg Old Town Wolfsberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000090, 40000090, 'St. Mark’s Parish Church Wolfsberg Wolfsberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000091, 40000091, 'Museum im Lavanthaus Wolfsberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000092, 40000092, 'Koralpe Wolfsberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 017 : ST. PÖLTEN (id 400017) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000093, 400017, 'St. Pölten Cathedral', 'St. Pölten Cathedral', 'A cathedral and architectural landmark in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Pölten Cathedral, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000094, 400017, 'Rathausplatz St. Pölten', 'Rathausplatz St. Pölten', 'A historic centre suited to walking and architecture in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rathausplatz St. Pölten, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000095, 400017, 'Museum Niederösterreich', 'Museum Niederösterreich', 'A museum and cultural attraction in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum Niederösterreich, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000096, 400017, 'Festspielhaus St. Pölten', 'Festspielhaus St. Pölten', 'A music and performing-arts attraction in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Festspielhaus St. Pölten, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000097, 400017, 'Klangturm', 'Klangturm', 'A scenic viewpoint and photography stop in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Klangturm, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000098, 400017, 'Stadtmuseum St. Pölten', 'Stadtmuseum St. Pölten', 'A museum and cultural attraction in St. Pölten, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtmuseum St. Pölten, St. Pölten, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: St. Pölten ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000093, 40000093, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000094, 40000094, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000095, 40000095, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000096, 40000096, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000097, 40000097, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000098, 40000098, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: St. Pölten ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000093, 40000093, 'St. Pölten Cathedral St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000094, 40000094, 'Rathausplatz St. Pölten St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000095, 40000095, 'Museum Niederösterreich St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000096, 40000096, 'Festspielhaus St. Pölten St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000097, 40000097, 'Klangturm St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000098, 40000098, 'Stadtmuseum St. Pölten St. Pölten', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 018 : KREMS AN DER DONAU (id 400018) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000099, 400018, 'Steiner Tor', 'Steiner Tor', 'A heritage landmark in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Steiner Tor, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000100, 400018, 'Kunsthalle Krems', 'Kunsthalle Krems', 'A museum and cultural attraction in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kunsthalle Krems, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000101, 400018, 'Karikaturmuseum Krems', 'Karikaturmuseum Krems', 'A museum and cultural attraction in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Karikaturmuseum Krems, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000102, 400018, 'Krems Old Town', 'Krems Old Town', 'A historic centre suited to walking and architecture in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Krems Old Town, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000103, 400018, 'Piaristenkirche Krems', 'Piaristenkirche Krems', 'A historic church and religious landmark in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Piaristenkirche Krems, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000104, 400018, 'Wachau Cultural Landscape', 'Wachau Cultural Landscape', 'A UNESCO World Heritage property or Austrian component in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wachau Cultural Landscape, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000105, 400018, 'Göttweig Abbey', 'Göttweig Abbey', 'A historic abbey and cultural landmark in Krems an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Göttweig Abbey, Krems an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Krems an der Donau ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000099, 40000099, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000100, 40000100, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000101, 40000101, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000102, 40000102, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000103, 40000103, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000104, 40000104, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000105, 40000105, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Krems an der Donau ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000099, 40000099, 'Steiner Tor Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000100, 40000100, 'Kunsthalle Krems Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000101, 40000101, 'Karikaturmuseum Krems Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000102, 40000102, 'Krems Old Town Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000103, 40000103, 'Piaristenkirche Krems Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000104, 40000104, 'Wachau Cultural Landscape Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000105, 40000105, 'Göttweig Abbey Krems an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 019 : MELK (id 400019) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000106, 400019, 'Melk Abbey', 'Melk Abbey', 'A historic abbey and cultural landmark in Melk, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Melk Abbey, Melk, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000107, 400019, 'Melk Abbey Park', 'Melk Abbey Park', 'A landscaped garden and leisure attraction in Melk, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Melk Abbey Park, Melk, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000108, 400019, 'Melk Old Town', 'Melk Old Town', 'A historic centre suited to walking and architecture in Melk, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Melk Old Town, Melk, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000109, 400019, 'Schallaburg Castle', 'Schallaburg Castle', 'A historic castle and heritage attraction in Melk, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schallaburg Castle, Melk, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000110, 400019, 'Danube Promenade Melk', 'Danube Promenade Melk', 'A riverfront and outdoor recreation attraction in Melk, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Danube Promenade Melk, Melk, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Melk ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000106, 40000106, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000107, 40000107, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000108, 40000108, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000109, 40000109, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000110, 40000110, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Melk ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000106, 40000106, 'Melk Abbey Melk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000107, 40000107, 'Melk Abbey Park Melk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000108, 40000108, 'Melk Old Town Melk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000109, 40000109, 'Schallaburg Castle Melk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000110, 40000110, 'Danube Promenade Melk Melk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 020 : DÜRNSTEIN (id 400020) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000111, 400020, 'Dürnstein Abbey', 'Dürnstein Abbey', 'A historic abbey and cultural landmark in Dürnstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dürnstein Abbey, Dürnstein, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000112, 400020, 'Dürnstein Castle Ruins', 'Dürnstein Castle Ruins', 'A historic castle and heritage attraction in Dürnstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dürnstein Castle Ruins, Dürnstein, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000113, 400020, 'Dürnstein Old Town', 'Dürnstein Old Town', 'A historic centre suited to walking and architecture in Dürnstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dürnstein Old Town, Dürnstein, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000114, 400020, 'Danube Promenade Dürnstein', 'Danube Promenade Dürnstein', 'A riverfront and outdoor recreation attraction in Dürnstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Danube Promenade Dürnstein, Dürnstein, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000115, 400020, 'Wachau Vineyards at Dürnstein', 'Wachau Vineyards at Dürnstein', 'A nature and outdoor recreation attraction in Dürnstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wachau Vineyards at Dürnstein, Dürnstein, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Dürnstein ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000111, 40000111, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000112, 40000112, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000113, 40000113, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000114, 40000114, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000115, 40000115, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Dürnstein ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000111, 40000111, 'Dürnstein Abbey Dürnstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000112, 40000112, 'Dürnstein Castle Ruins Dürnstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000113, 40000113, 'Dürnstein Old Town Dürnstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000114, 40000114, 'Danube Promenade Dürnstein Dürnstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000115, 40000115, 'Wachau Vineyards at Dürnstein Dürnstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 021 : BADEN BEI WIEN (id 400021) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000116, 400021, 'Great Spa Towns of Europe – Baden bei Wien', 'Great Spa Towns of Europe – Baden bei Wien', 'A UNESCO World Heritage property or Austrian component in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Great Spa Towns of Europe – Baden bei Wien, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000117, 400021, 'Casino Baden', 'Casino Baden', 'A notable visitor attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Casino Baden, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000118, 400021, 'Kurpark Baden', 'Kurpark Baden', 'An urban park and leisure attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kurpark Baden, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000119, 400021, 'Römertherme Baden', 'Römertherme Baden', 'A thermal spa and wellness attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Römertherme Baden, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000120, 400021, 'Beethovenhaus Baden', 'Beethovenhaus Baden', 'A museum and cultural attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Beethovenhaus Baden, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000121, 400021, 'Arnulf Rainer Museum', 'Arnulf Rainer Museum', 'A museum and cultural attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Arnulf Rainer Museum, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000122, 400021, 'Doblhoffpark', 'Doblhoffpark', 'A landscaped garden and leisure attraction in Baden bei Wien, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Doblhoffpark, Baden bei Wien, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Baden bei Wien ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000116, 40000116, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000117, 40000117, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000118, 40000118, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000119, 40000119, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000120, 40000120, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000121, 40000121, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000122, 40000122, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Baden bei Wien ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000116, 40000116, 'Great Spa Towns of Europe – Baden bei Wien Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000117, 40000117, 'Casino Baden Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000118, 40000118, 'Kurpark Baden Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000119, 40000119, 'Römertherme Baden Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000120, 40000120, 'Beethovenhaus Baden Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000121, 40000121, 'Arnulf Rainer Museum Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000122, 40000122, 'Doblhoffpark Baden bei Wien', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 022 : WIENER NEUSTADT (id 400022) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000123, 400022, 'Wiener Neustadt Cathedral', 'Wiener Neustadt Cathedral', 'A cathedral and architectural landmark in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wiener Neustadt Cathedral, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000124, 400022, 'Reckturm', 'Reckturm', 'A heritage landmark in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Reckturm, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000125, 400022, 'Museum St. Peter an der Sperr', 'Museum St. Peter an der Sperr', 'A museum and cultural attraction in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum St. Peter an der Sperr, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000126, 400022, 'Wiener Neustadt Castle and Theresian Military Academy', 'Wiener Neustadt Castle and Theresian Military Academy', 'A historic castle and heritage attraction in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wiener Neustadt Castle and Theresian Military Academy, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000127, 400022, 'Kasematten Wiener Neustadt', 'Kasematten Wiener Neustadt', 'A heritage landmark in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kasematten Wiener Neustadt, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000128, 400022, 'Wiener Neustadt Water Tower', 'Wiener Neustadt Water Tower', 'A heritage landmark in Wiener Neustadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wiener Neustadt Water Tower, Wiener Neustadt, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Wiener Neustadt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000123, 40000123, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000124, 40000124, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000125, 40000125, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000126, 40000126, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000127, 40000127, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000128, 40000128, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Wiener Neustadt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000123, 40000123, 'Wiener Neustadt Cathedral Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000124, 40000124, 'Reckturm Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000125, 40000125, 'Museum St. Peter an der Sperr Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000126, 40000126, 'Wiener Neustadt Castle and Theresian Military Academy Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000127, 40000127, 'Kasematten Wiener Neustadt Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000128, 40000128, 'Wiener Neustadt Water Tower Wiener Neustadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 023 : KLOSTERNEUBURG (id 400023) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000129, 400023, 'Klosterneuburg Monastery', 'Klosterneuburg Monastery', 'A historic monastery and religious landmark in Klosterneuburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Klosterneuburg Monastery, Klosterneuburg, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000130, 400023, 'Verdun Altar', 'Verdun Altar', 'A heritage landmark in Klosterneuburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Verdun Altar, Klosterneuburg, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000131, 400023, 'Klosterneuburg Abbey Museum', 'Klosterneuburg Abbey Museum', 'A museum and cultural attraction in Klosterneuburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Klosterneuburg Abbey Museum, Klosterneuburg, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000132, 400023, 'Klosterneuburg Vineyards', 'Klosterneuburg Vineyards', 'A nature and outdoor recreation attraction in Klosterneuburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Klosterneuburg Vineyards, Klosterneuburg, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Klosterneuburg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000129, 40000129, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000130, 40000130, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000131, 40000131, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000132, 40000132, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Klosterneuburg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000129, 40000129, 'Klosterneuburg Monastery Klosterneuburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000130, 40000130, 'Verdun Altar Klosterneuburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000131, 40000131, 'Klosterneuburg Abbey Museum Klosterneuburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000132, 40000132, 'Klosterneuburg Vineyards Klosterneuburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 024 : SEMMERING (id 400024) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000133, 400024, 'Semmering Railway', 'Semmering Railway', 'A UNESCO World Heritage property or Austrian component in Semmering, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Semmering Railway, Semmering, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000134, 400024, '20-Schilling View', '20-Schilling View', 'A scenic viewpoint and photography stop in Semmering, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, '20-Schilling View, Semmering, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000135, 400024, 'Zauberberg Semmering', 'Zauberberg Semmering', 'An alpine skiing and mountain recreation area in Semmering, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Zauberberg Semmering, Semmering, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000136, 400024, 'Hirschenkogel', 'Hirschenkogel', 'A mountain and alpine recreation attraction in Semmering, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hirschenkogel, Semmering, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000137, 400024, 'Pinkenkogel Hiking Area', 'Pinkenkogel Hiking Area', 'A hiking and nature area in Semmering, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pinkenkogel Hiking Area, Semmering, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Semmering ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000133, 40000133, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000134, 40000134, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000135, 40000135, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000136, 40000136, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000137, 40000137, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Semmering ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000133, 40000133, 'Semmering Railway Semmering', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000134, 40000134, '20-Schilling View Semmering', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000135, 40000135, 'Zauberberg Semmering Semmering', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000136, 40000136, 'Hirschenkogel Semmering', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000137, 40000137, 'Pinkenkogel Hiking Area Semmering', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 025 : PETRONELL-CARNUNTUM (id 400025) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000138, 400025, 'Archaeological Park Carnuntum', 'Archaeological Park Carnuntum', 'An archaeological and ancient-history attraction in Petronell-Carnuntum, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Archaeological Park Carnuntum, Petronell-Carnuntum, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000139, 400025, 'Roman City Quarter Carnuntum', 'Roman City Quarter Carnuntum', 'An archaeological and ancient-history attraction in Petronell-Carnuntum, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Roman City Quarter Carnuntum, Petronell-Carnuntum, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000140, 400025, 'Carnuntum Amphitheatre', 'Carnuntum Amphitheatre', 'An archaeological and ancient-history attraction in Petronell-Carnuntum, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Carnuntum Amphitheatre, Petronell-Carnuntum, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000141, 400025, 'Heidentor', 'Heidentor', 'An archaeological and ancient-history attraction in Petronell-Carnuntum, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Heidentor, Petronell-Carnuntum, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000142, 400025, 'Frontiers of the Roman Empire – The Danube Limes (Western Segment)', 'Frontiers of the Roman Empire – The Danube Limes (Western Segment)', 'A UNESCO World Heritage property or Austrian component in Petronell-Carnuntum, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Frontiers of the Roman Empire – The Danube Limes (Western Segment), Petronell-Carnuntum, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02');

-- ---- HOURS: Petronell-Carnuntum ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000138, 40000138, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000139, 40000139, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000140, 40000140, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000141, 40000141, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000142, 40000142, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Petronell-Carnuntum ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000138, 40000138, 'Archaeological Park Carnuntum Petronell-Carnuntum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000139, 40000139, 'Roman City Quarter Carnuntum Petronell-Carnuntum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000140, 40000140, 'Carnuntum Amphitheatre Petronell-Carnuntum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000141, 40000141, 'Heidentor Petronell-Carnuntum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000142, 40000142, 'Frontiers of the Roman Empire – The Danube Limes (Western Segment) Petronell-Carnuntum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 026 : HAINBURG AN DER DONAU (id 400026) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000143, 400026, 'Hainburg City Walls', 'Hainburg City Walls', 'A heritage landmark in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hainburg City Walls, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000144, 400026, 'Wienertor', 'Wienertor', 'A heritage landmark in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wienertor, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000145, 400026, 'Ungartor', 'Ungartor', 'A heritage landmark in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ungartor, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000146, 400026, 'Braunsberg', 'Braunsberg', 'A scenic viewpoint and photography stop in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Braunsberg, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000147, 400026, 'St. Martin Parish Church Hainburg', 'St. Martin Parish Church Hainburg', 'A historic church and religious landmark in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Martin Parish Church Hainburg, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000148, 400026, 'Danube-Auen National Park Gateway Hainburg', 'Danube-Auen National Park Gateway Hainburg', 'A nature and outdoor recreation attraction in Hainburg an der Donau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Danube-Auen National Park Gateway Hainburg, Hainburg an der Donau, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Hainburg an der Donau ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000143, 40000143, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000144, 40000144, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000145, 40000145, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000146, 40000146, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000147, 40000147, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000148, 40000148, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Hainburg an der Donau ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000143, 40000143, 'Hainburg City Walls Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000144, 40000144, 'Wienertor Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000145, 40000145, 'Ungartor Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000146, 40000146, 'Braunsberg Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000147, 40000147, 'St. Martin Parish Church Hainburg Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000148, 40000148, 'Danube-Auen National Park Gateway Hainburg Hainburg an der Donau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 027 : RETZ (id 400027) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000149, 400027, 'Retz Adventure Cellar', 'Retz Adventure Cellar', 'A heritage landmark in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Retz Adventure Cellar, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000150, 400027, 'Retz Hauptplatz', 'Retz Hauptplatz', 'A historic centre suited to walking and architecture in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Retz Hauptplatz, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000151, 400027, 'Retz Windmill', 'Retz Windmill', 'A heritage landmark in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Retz Windmill, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000152, 400027, 'Verderberhaus', 'Verderberhaus', 'A heritage landmark in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Verderberhaus, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000153, 400027, 'Retz Town Hall Tower', 'Retz Town Hall Tower', 'A scenic viewpoint and photography stop in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Retz Town Hall Tower, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000154, 400027, 'Dominican Church Retz', 'Dominican Church Retz', 'A historic church and religious landmark in Retz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dominican Church Retz, Retz, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Retz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000149, 40000149, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000150, 40000150, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000151, 40000151, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000152, 40000152, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000153, 40000153, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000154, 40000154, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Retz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000149, 40000149, 'Retz Adventure Cellar Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000150, 40000150, 'Retz Hauptplatz Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000151, 40000151, 'Retz Windmill Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000152, 40000152, 'Verderberhaus Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000153, 40000153, 'Retz Town Hall Tower Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000154, 40000154, 'Dominican Church Retz Retz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 028 : WAIDHOFEN AN DER YBBS (id 400028) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000155, 400028, 'Rothschild Castle Waidhofen', 'Rothschild Castle Waidhofen', 'A historic castle and heritage attraction in Waidhofen an der Ybbs, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rothschild Castle Waidhofen, Waidhofen an der Ybbs, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000156, 400028, 'Waidhofen Old Town', 'Waidhofen Old Town', 'A historic centre suited to walking and architecture in Waidhofen an der Ybbs, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Waidhofen Old Town, Waidhofen an der Ybbs, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000157, 400028, 'Stadtpfarrkirche Waidhofen', 'Stadtpfarrkirche Waidhofen', 'A historic church and religious landmark in Waidhofen an der Ybbs, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpfarrkirche Waidhofen, Waidhofen an der Ybbs, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000158, 400028, 'Ybbsturm', 'Ybbsturm', 'A heritage landmark in Waidhofen an der Ybbs, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Lower Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ybbsturm, Waidhofen an der Ybbs, Lower Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Waidhofen an der Ybbs ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000155, 40000155, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000156, 40000156, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000157, 40000157, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000158, 40000158, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Waidhofen an der Ybbs ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000155, 40000155, 'Rothschild Castle Waidhofen Waidhofen an der Ybbs', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000156, 40000156, 'Waidhofen Old Town Waidhofen an der Ybbs', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000157, 40000157, 'Stadtpfarrkirche Waidhofen Waidhofen an der Ybbs', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000158, 40000158, 'Ybbsturm Waidhofen an der Ybbs', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 029 : LINZ (id 400029) — 12 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000159, 400029, 'Ars Electronica Center', 'Ars Electronica Center', 'A museum and cultural attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ars Electronica Center, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000160, 400029, 'Lentos Art Museum', 'Lentos Art Museum', 'A museum and cultural attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lentos Art Museum, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000161, 400029, 'Linz Castle Museum', 'Linz Castle Museum', 'A museum and cultural attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Linz Castle Museum, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000162, 400029, 'Mariendom Linz', 'Mariendom Linz', 'A cathedral and architectural landmark in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mariendom Linz, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000163, 400029, 'Hauptplatz Linz', 'Hauptplatz Linz', 'A historic centre suited to walking and architecture in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hauptplatz Linz, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000164, 400029, 'Pöstlingberg', 'Pöstlingberg', 'A scenic viewpoint and photography stop in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pöstlingberg, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000165, 400029, 'Pöstlingbergbahn', 'Pöstlingbergbahn', 'A scenic or heritage railway attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pöstlingbergbahn, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000166, 400029, 'Grottenbahn', 'Grottenbahn', 'A family-oriented visitor attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Grottenbahn, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000167, 400029, 'Mural Harbor', 'Mural Harbor', 'An art and design attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mural Harbor, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000168, 400029, 'Botanical Garden Linz', 'Botanical Garden Linz', 'A landscaped garden and leisure attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Botanical Garden Linz, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000169, 400029, 'voestalpine Stahlwelt', 'voestalpine Stahlwelt', 'A museum and cultural attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'voestalpine Stahlwelt, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000170, 400029, 'Donaulände Linz', 'Donaulände Linz', 'An urban park and leisure attraction in Linz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Donaulände Linz, Linz, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Linz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000159, 40000159, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000160, 40000160, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000161, 40000161, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000162, 40000162, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000163, 40000163, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000164, 40000164, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000165, 40000165, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000166, 40000166, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000167, 40000167, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000168, 40000168, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000169, 40000169, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000170, 40000170, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Linz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000159, 40000159, 'Ars Electronica Center Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000160, 40000160, 'Lentos Art Museum Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000161, 40000161, 'Linz Castle Museum Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000162, 40000162, 'Mariendom Linz Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000163, 40000163, 'Hauptplatz Linz Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000164, 40000164, 'Pöstlingberg Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000165, 40000165, 'Pöstlingbergbahn Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000166, 40000166, 'Grottenbahn Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000167, 40000167, 'Mural Harbor Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000168, 40000168, 'Botanical Garden Linz Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000169, 40000169, 'voestalpine Stahlwelt Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000170, 40000170, 'Donaulände Linz Linz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 030 : HALLSTATT (id 400030) — 8 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000171, 400030, 'Hallstatt-Dachstein / Salzkammergut Cultural Landscape', 'Hallstatt-Dachstein / Salzkammergut Cultural Landscape', 'A UNESCO World Heritage property or Austrian component in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt-Dachstein / Salzkammergut Cultural Landscape, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000172, 400030, 'Hallstatt Salt Mine', 'Hallstatt Salt Mine', 'A heritage landmark in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt Salt Mine, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000173, 400030, 'Hallstatt Skywalk', 'Hallstatt Skywalk', 'A scenic viewpoint and photography stop in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt Skywalk, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000174, 400030, 'Hallstatt Bone House', 'Hallstatt Bone House', 'A museum and cultural attraction in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt Bone House, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000175, 400030, 'Catholic Parish Church Hallstatt', 'Catholic Parish Church Hallstatt', 'A historic church and religious landmark in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Catholic Parish Church Hallstatt, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000176, 400030, 'Hallstatt Museum', 'Hallstatt Museum', 'A museum and cultural attraction in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt Museum, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000177, 400030, 'Lake Hallstatt', 'Lake Hallstatt', 'A lake and outdoor recreation destination in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Hallstatt, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000178, 400030, 'Hallstatt Market Square', 'Hallstatt Market Square', 'A historic centre suited to walking and architecture in Hallstatt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallstatt Market Square, Hallstatt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Hallstatt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000171, 40000171, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000172, 40000172, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000173, 40000173, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000174, 40000174, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000175, 40000175, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000176, 40000176, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000177, 40000177, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000178, 40000178, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Hallstatt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000171, 40000171, 'Hallstatt-Dachstein / Salzkammergut Cultural Landscape Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000172, 40000172, 'Hallstatt Salt Mine Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000173, 40000173, 'Hallstatt Skywalk Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000174, 40000174, 'Hallstatt Bone House Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000175, 40000175, 'Catholic Parish Church Hallstatt Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000176, 40000176, 'Hallstatt Museum Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000177, 40000177, 'Lake Hallstatt Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000178, 40000178, 'Hallstatt Market Square Hallstatt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 031 : BAD ISCHL (id 400031) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000179, 400031, 'Kaiservilla Bad Ischl', 'Kaiservilla Bad Ischl', 'A major palace and architectural attraction in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kaiservilla Bad Ischl, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000180, 400031, 'Marmorschlössl', 'Marmorschlössl', 'A museum and cultural attraction in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Marmorschlössl, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000181, 400031, 'Lehár Villa', 'Lehár Villa', 'A museum and cultural attraction in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lehár Villa, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000182, 400031, 'Katrin Cable Car', 'Katrin Cable Car', 'A mountain cable-car experience and scenic access point in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Katrin Cable Car, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000183, 400031, 'Siriuskogl Viewpoint', 'Siriuskogl Viewpoint', 'A scenic viewpoint and photography stop in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Siriuskogl Viewpoint, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000184, 400031, 'Trinkhalle Bad Ischl', 'Trinkhalle Bad Ischl', 'A heritage landmark in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Trinkhalle Bad Ischl, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000185, 400031, 'Museum der Stadt Bad Ischl', 'Museum der Stadt Bad Ischl', 'A museum and cultural attraction in Bad Ischl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum der Stadt Bad Ischl, Bad Ischl, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bad Ischl ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000179, 40000179, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000180, 40000180, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000181, 40000181, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000182, 40000182, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000183, 40000183, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000184, 40000184, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000185, 40000185, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bad Ischl ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000179, 40000179, 'Kaiservilla Bad Ischl Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000180, 40000180, 'Marmorschlössl Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000181, 40000181, 'Lehár Villa Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000182, 40000182, 'Katrin Cable Car Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000183, 40000183, 'Siriuskogl Viewpoint Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000184, 40000184, 'Trinkhalle Bad Ischl Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000185, 40000185, 'Museum der Stadt Bad Ischl Bad Ischl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 032 : STEYR (id 400032) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000186, 400032, 'Steyr Stadtplatz', 'Steyr Stadtplatz', 'A historic centre suited to walking and architecture in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Steyr Stadtplatz, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000187, 400032, 'Bummerlhaus', 'Bummerlhaus', 'A heritage landmark in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bummerlhaus, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000188, 400032, 'Schloss Lamberg', 'Schloss Lamberg', 'A historic castle and heritage attraction in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Lamberg, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000189, 400032, 'Stadtpfarrkirche Steyr', 'Stadtpfarrkirche Steyr', 'A historic church and religious landmark in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpfarrkirche Steyr, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000190, 400032, 'Museum Arbeitswelt', 'Museum Arbeitswelt', 'A museum and cultural attraction in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum Arbeitswelt, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000191, 400032, 'Zwischenbrücken', 'Zwischenbrücken', 'A historic centre suited to walking and architecture in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Zwischenbrücken, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000192, 400032, 'Christkindl Pilgrimage Church', 'Christkindl Pilgrimage Church', 'A historic church and religious landmark in Steyr, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Christkindl Pilgrimage Church, Steyr, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Steyr ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000186, 40000186, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000187, 40000187, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000188, 40000188, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000189, 40000189, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000190, 40000190, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000191, 40000191, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000192, 40000192, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Steyr ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000186, 40000186, 'Steyr Stadtplatz Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000187, 40000187, 'Bummerlhaus Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000188, 40000188, 'Schloss Lamberg Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000189, 40000189, 'Stadtpfarrkirche Steyr Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000190, 40000190, 'Museum Arbeitswelt Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000191, 40000191, 'Zwischenbrücken Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000192, 40000192, 'Christkindl Pilgrimage Church Steyr', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 033 : GMUNDEN (id 400033) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000193, 400033, 'Schloss Ort', 'Schloss Ort', 'A historic castle and heritage attraction in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Ort, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000194, 400033, 'Gmunden Town Hall', 'Gmunden Town Hall', 'A heritage landmark in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gmunden Town Hall, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000195, 400033, 'Gmunden Tramway', 'Gmunden Tramway', 'A scenic or heritage railway attraction in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gmunden Tramway, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000196, 400033, 'K-Hof Kammerhof Museum', 'K-Hof Kammerhof Museum', 'A museum and cultural attraction in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'K-Hof Kammerhof Museum, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000197, 400033, 'Grünberg Cable Car', 'Grünberg Cable Car', 'A mountain cable-car experience and scenic access point in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Grünberg Cable Car, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000198, 400033, 'Gmunden Esplanade', 'Gmunden Esplanade', 'A lake and outdoor recreation destination in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gmunden Esplanade, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000199, 400033, 'Lake Traunsee', 'Lake Traunsee', 'A lake and outdoor recreation destination in Gmunden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Traunsee, Gmunden, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Gmunden ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000193, 40000193, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000194, 40000194, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000195, 40000195, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000196, 40000196, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000197, 40000197, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000198, 40000198, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000199, 40000199, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Gmunden ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000193, 40000193, 'Schloss Ort Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000194, 40000194, 'Gmunden Town Hall Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000195, 40000195, 'Gmunden Tramway Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000196, 40000196, 'K-Hof Kammerhof Museum Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000197, 40000197, 'Grünberg Cable Car Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000198, 40000198, 'Gmunden Esplanade Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000199, 40000199, 'Lake Traunsee Gmunden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 034 : ST. WOLFGANG IM SALZKAMMERGUT (id 400034) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000200, 400034, 'Pilgrimage Church of St. Wolfgang', 'Pilgrimage Church of St. Wolfgang', 'A historic church and religious landmark in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pilgrimage Church of St. Wolfgang, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000201, 400034, 'Schafberg Railway', 'Schafberg Railway', 'A scenic or heritage railway attraction in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schafberg Railway, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000202, 400034, 'Lake Wolfgang', 'Lake Wolfgang', 'A lake and outdoor recreation destination in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Wolfgang, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000203, 400034, 'White Horse Inn', 'White Horse Inn', 'A heritage landmark in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'White Horse Inn, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000204, 400034, 'Michael Pacher Altar', 'Michael Pacher Altar', 'A heritage landmark in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Michael Pacher Altar, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000205, 400034, 'St. Wolfgang Lakeside Promenade', 'St. Wolfgang Lakeside Promenade', 'A lake and outdoor recreation destination in St. Wolfgang im Salzkammergut, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Wolfgang Lakeside Promenade, St. Wolfgang im Salzkammergut, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: St. Wolfgang im Salzkammergut ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000200, 40000200, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000201, 40000201, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000202, 40000202, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000203, 40000203, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000204, 40000204, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000205, 40000205, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: St. Wolfgang im Salzkammergut ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000200, 40000200, 'Pilgrimage Church of St. Wolfgang St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000201, 40000201, 'Schafberg Railway St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000202, 40000202, 'Lake Wolfgang St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000203, 40000203, 'White Horse Inn St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000204, 40000204, 'Michael Pacher Altar St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000205, 40000205, 'St. Wolfgang Lakeside Promenade St. Wolfgang im Salzkammergut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 035 : MONDSEE (id 400035) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000206, 400035, 'Basilica St. Michael Mondsee', 'Basilica St. Michael Mondsee', 'A historic church and religious landmark in Mondsee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Basilica St. Michael Mondsee, Mondsee, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000207, 400035, 'Lake Mondsee', 'Lake Mondsee', 'A lake and outdoor recreation destination in Mondsee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Mondsee, Mondsee, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000208, 400035, 'Museum Mondseeland', 'Museum Mondseeland', 'A museum and cultural attraction in Mondsee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum Mondseeland, Mondsee, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000209, 400035, 'Alpenseebad Mondsee', 'Alpenseebad Mondsee', 'A lake and outdoor recreation destination in Mondsee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Alpenseebad Mondsee, Mondsee, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000210, 400035, 'Drachenwand', 'Drachenwand', 'A mountain and alpine recreation attraction in Mondsee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Drachenwand, Mondsee, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Mondsee ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000206, 40000206, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000207, 40000207, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000208, 40000208, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000209, 40000209, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000210, 40000210, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Mondsee ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000206, 40000206, 'Basilica St. Michael Mondsee Mondsee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000207, 40000207, 'Lake Mondsee Mondsee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000208, 40000208, 'Museum Mondseeland Mondsee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000209, 40000209, 'Alpenseebad Mondsee Mondsee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000210, 40000210, 'Drachenwand Mondsee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 036 : SCHÄRDING (id 400036) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000211, 400036, 'Silberzeile', 'Silberzeile', 'A historic centre suited to walking and architecture in Schärding, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Silberzeile, Schärding, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000212, 400036, 'Schärding Stadtplatz', 'Schärding Stadtplatz', 'A historic centre suited to walking and architecture in Schärding, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schärding Stadtplatz, Schärding, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000213, 400036, 'Schlosspark Schärding', 'Schlosspark Schärding', 'An urban park and leisure attraction in Schärding, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schlosspark Schärding, Schärding, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000214, 400036, 'St. George Church Schärding', 'St. George Church Schärding', 'A historic church and religious landmark in Schärding, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. George Church Schärding, Schärding, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000215, 400036, 'Inn Promenade Schärding', 'Inn Promenade Schärding', 'A riverfront and outdoor recreation attraction in Schärding, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Inn Promenade Schärding, Schärding, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Schärding ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000211, 40000211, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000212, 40000212, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000213, 40000213, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000214, 40000214, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000215, 40000215, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Schärding ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000211, 40000211, 'Silberzeile Schärding', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000212, 40000212, 'Schärding Stadtplatz Schärding', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000213, 40000213, 'Schlosspark Schärding Schärding', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000214, 40000214, 'St. George Church Schärding Schärding', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000215, 40000215, 'Inn Promenade Schärding Schärding', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 037 : FREISTADT (id 400037) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000216, 400037, 'Böhmertor', 'Böhmertor', 'A heritage landmark in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Böhmertor, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000217, 400037, 'Linzertor', 'Linzertor', 'A heritage landmark in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Linzertor, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000218, 400037, 'Freistadt Castle', 'Freistadt Castle', 'A historic castle and heritage attraction in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Freistadt Castle, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000219, 400037, 'Mühlviertler Schlossmuseum', 'Mühlviertler Schlossmuseum', 'A museum and cultural attraction in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mühlviertler Schlossmuseum, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000220, 400037, 'Stadtpfarrkirche Freistadt', 'Stadtpfarrkirche Freistadt', 'A historic church and religious landmark in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpfarrkirche Freistadt, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000221, 400037, 'Freistadt City Walls', 'Freistadt City Walls', 'A heritage landmark in Freistadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Freistadt City Walls, Freistadt, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Freistadt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000216, 40000216, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000217, 40000217, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000218, 40000218, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000219, 40000219, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000220, 40000220, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000221, 40000221, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Freistadt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000216, 40000216, 'Böhmertor Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000217, 40000217, 'Linzertor Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000218, 40000218, 'Freistadt Castle Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000219, 40000219, 'Mühlviertler Schlossmuseum Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000220, 40000220, 'Stadtpfarrkirche Freistadt Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000221, 40000221, 'Freistadt City Walls Freistadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 038 : OBERTRAUN (id 400038) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000222, 400038, 'Dachstein Krippenstein', 'Dachstein Krippenstein', 'A mountain and alpine recreation attraction in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dachstein Krippenstein, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000223, 400038, 'Five Fingers Viewing Platform', 'Five Fingers Viewing Platform', 'A scenic viewpoint and photography stop in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Five Fingers Viewing Platform, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000224, 400038, 'Dachstein Giant Ice Cave', 'Dachstein Giant Ice Cave', 'A cave and geological attraction in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dachstein Giant Ice Cave, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000225, 400038, 'Mammoth Cave Dachstein', 'Mammoth Cave Dachstein', 'A cave and geological attraction in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mammoth Cave Dachstein, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000226, 400038, 'Lake Hallstatt at Obertraun', 'Lake Hallstatt at Obertraun', 'A lake and outdoor recreation destination in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Hallstatt at Obertraun, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000227, 400038, 'Koppenbrüller Cave', 'Koppenbrüller Cave', 'A cave and geological attraction in Obertraun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Koppenbrüller Cave, Obertraun, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Obertraun ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000222, 40000222, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000223, 40000223, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000224, 40000224, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000225, 40000225, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000226, 40000226, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000227, 40000227, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Obertraun ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000222, 40000222, 'Dachstein Krippenstein Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000223, 40000223, 'Five Fingers Viewing Platform Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000224, 40000224, 'Dachstein Giant Ice Cave Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000225, 40000225, 'Mammoth Cave Dachstein Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000226, 40000226, 'Lake Hallstatt at Obertraun Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000227, 40000227, 'Koppenbrüller Cave Obertraun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 039 : BRAUNAU AM INN (id 400039) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000228, 400039, 'Braunau Stadtplatz', 'Braunau Stadtplatz', 'A historic centre suited to walking and architecture in Braunau am Inn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Braunau Stadtplatz, Braunau am Inn, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000229, 400039, 'St. Stephen Parish Church Braunau', 'St. Stephen Parish Church Braunau', 'A historic church and religious landmark in Braunau am Inn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Stephen Parish Church Braunau, Braunau am Inn, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000230, 400039, 'Bezirksmuseum Herzogsburg', 'Bezirksmuseum Herzogsburg', 'A museum and cultural attraction in Braunau am Inn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bezirksmuseum Herzogsburg, Braunau am Inn, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000231, 400039, 'Inn River Promenade Braunau', 'Inn River Promenade Braunau', 'A riverfront and outdoor recreation attraction in Braunau am Inn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Upper Austria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Inn River Promenade Braunau, Braunau am Inn, Upper Austria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Braunau am Inn ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000228, 40000228, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000229, 40000229, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000230, 40000230, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000231, 40000231, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Braunau am Inn ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000228, 40000228, 'Braunau Stadtplatz Braunau am Inn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000229, 40000229, 'St. Stephen Parish Church Braunau Braunau am Inn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000230, 40000230, 'Bezirksmuseum Herzogsburg Braunau am Inn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000231, 40000231, 'Inn River Promenade Braunau Braunau am Inn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 040 : SALZBURG (id 400040) — 15 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000232, 400040, 'Historic Centre of the City of Salzburg', 'Historic Centre of the City of Salzburg', 'A UNESCO World Heritage property or Austrian component in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Historic Centre of the City of Salzburg, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000233, 400040, 'Hohensalzburg Fortress', 'Hohensalzburg Fortress', 'A historic fortress and panoramic heritage attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hohensalzburg Fortress, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000234, 400040, 'Mirabell Palace and Gardens', 'Mirabell Palace and Gardens', 'A major palace and architectural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mirabell Palace and Gardens, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000235, 400040, 'Salzburg Cathedral', 'Salzburg Cathedral', 'A cathedral and architectural landmark in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Salzburg Cathedral, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000236, 400040, 'Mozart’s Birthplace', 'Mozart’s Birthplace', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mozart’s Birthplace, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000237, 400040, 'Mozart Residence', 'Mozart Residence', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mozart Residence, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000238, 400040, 'Getreidegasse', 'Getreidegasse', 'A historic centre suited to walking and architecture in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Getreidegasse, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000239, 400040, 'St. Peter’s Abbey Salzburg', 'St. Peter’s Abbey Salzburg', 'A historic abbey and cultural landmark in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Peter’s Abbey Salzburg, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000240, 400040, 'DomQuartier Salzburg', 'DomQuartier Salzburg', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'DomQuartier Salzburg, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000241, 400040, 'Hellbrunn Palace', 'Hellbrunn Palace', 'A major palace and architectural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hellbrunn Palace, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000242, 400040, 'Salzburg Museum', 'Salzburg Museum', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Salzburg Museum, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000243, 400040, 'Museum der Moderne Mönchsberg', 'Museum der Moderne Mönchsberg', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum der Moderne Mönchsberg, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000244, 400040, 'Mönchsberg', 'Mönchsberg', 'A scenic viewpoint and photography stop in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mönchsberg, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000245, 400040, 'Nonnberg Abbey', 'Nonnberg Abbey', 'A historic abbey and cultural landmark in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Nonnberg Abbey, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000246, 400040, 'Hangar-7', 'Hangar-7', 'A museum and cultural attraction in Salzburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hangar-7, Salzburg, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Salzburg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000232, 40000232, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000233, 40000233, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000234, 40000234, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000235, 40000235, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000236, 40000236, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000237, 40000237, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000238, 40000238, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000239, 40000239, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000240, 40000240, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000241, 40000241, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000242, 40000242, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000243, 40000243, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000244, 40000244, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000245, 40000245, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000246, 40000246, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Salzburg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000232, 40000232, 'Historic Centre of the City of Salzburg Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000233, 40000233, 'Hohensalzburg Fortress Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000234, 40000234, 'Mirabell Palace and Gardens Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000235, 40000235, 'Salzburg Cathedral Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000236, 40000236, 'Mozart’s Birthplace Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000237, 40000237, 'Mozart Residence Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000238, 40000238, 'Getreidegasse Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000239, 40000239, 'St. Peter’s Abbey Salzburg Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000240, 40000240, 'DomQuartier Salzburg Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000241, 40000241, 'Hellbrunn Palace Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000242, 40000242, 'Salzburg Museum Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000243, 40000243, 'Museum der Moderne Mönchsberg Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000244, 40000244, 'Mönchsberg Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000245, 40000245, 'Nonnberg Abbey Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000246, 40000246, 'Hangar-7 Salzburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 041 : ZELL AM SEE (id 400041) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000247, 400041, 'Lake Zell', 'Lake Zell', 'A lake and outdoor recreation destination in Zell am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Zell, Zell am See, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000248, 400041, 'Schmittenhöhe', 'Schmittenhöhe', 'A mountain and alpine recreation attraction in Zell am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schmittenhöhe, Zell am See, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000249, 400041, 'Schmittenhöhebahn', 'Schmittenhöhebahn', 'A mountain cable-car experience and scenic access point in Zell am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schmittenhöhebahn, Zell am See, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000250, 400041, 'St. Hippolyt Church Zell am See', 'St. Hippolyt Church Zell am See', 'A historic church and religious landmark in Zell am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Hippolyt Church Zell am See, Zell am See, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000251, 400041, 'Zell am See Esplanade', 'Zell am See Esplanade', 'A lake and outdoor recreation destination in Zell am See, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Zell am See Esplanade, Zell am See, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Zell am See ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000247, 40000247, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000248, 40000248, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000249, 40000249, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000250, 40000250, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000251, 40000251, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Zell am See ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000247, 40000247, 'Lake Zell Zell am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000248, 40000248, 'Schmittenhöhe Zell am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000249, 40000249, 'Schmittenhöhebahn Zell am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000250, 40000250, 'St. Hippolyt Church Zell am See Zell am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000251, 40000251, 'Zell am See Esplanade Zell am See', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 042 : KAPRUN (id 400042) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000252, 400042, 'Kitzsteinhorn', 'Kitzsteinhorn', 'A mountain and alpine recreation attraction in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kitzsteinhorn, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000253, 400042, 'Gipfelwelt 3000', 'Gipfelwelt 3000', 'A scenic viewpoint and photography stop in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gipfelwelt 3000, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000254, 400042, 'Sigmund Thun Gorge', 'Sigmund Thun Gorge', 'A nature and outdoor recreation attraction in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Sigmund Thun Gorge, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000255, 400042, 'Kaprun Castle', 'Kaprun Castle', 'A historic castle and heritage attraction in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kaprun Castle, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000256, 400042, 'TAUERN SPA Zell am See-Kaprun', 'TAUERN SPA Zell am See-Kaprun', 'A thermal spa and wellness attraction in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'TAUERN SPA Zell am See-Kaprun, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000257, 400042, 'Kaprun High Mountain Reservoirs', 'Kaprun High Mountain Reservoirs', 'A nature and outdoor recreation attraction in Kaprun, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kaprun High Mountain Reservoirs, Kaprun, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Kaprun ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000252, 40000252, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000253, 40000253, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000254, 40000254, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000255, 40000255, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000256, 40000256, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000257, 40000257, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Kaprun ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000252, 40000252, 'Kitzsteinhorn Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000253, 40000253, 'Gipfelwelt 3000 Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000254, 40000254, 'Sigmund Thun Gorge Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000255, 40000255, 'Kaprun Castle Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000256, 40000256, 'TAUERN SPA Zell am See-Kaprun Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000257, 40000257, 'Kaprun High Mountain Reservoirs Kaprun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 043 : BAD GASTEIN (id 400043) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000258, 400043, 'Bad Gastein Waterfall', 'Bad Gastein Waterfall', 'A waterfall and nature attraction in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bad Gastein Waterfall, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000259, 400043, 'Stubnerkogel Suspension Bridge', 'Stubnerkogel Suspension Bridge', 'A scenic viewpoint and photography stop in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stubnerkogel Suspension Bridge, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000260, 400043, 'Felsentherme Bad Gastein', 'Felsentherme Bad Gastein', 'A thermal spa and wellness attraction in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Felsentherme Bad Gastein, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000261, 400043, 'Gastein Healing Gallery', 'Gastein Healing Gallery', 'A thermal spa and wellness attraction in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gastein Healing Gallery, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000262, 400043, 'Historic Centre of Bad Gastein', 'Historic Centre of Bad Gastein', 'A historic centre suited to walking and architecture in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Historic Centre of Bad Gastein, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000263, 400043, 'Graukogel', 'Graukogel', 'A mountain and alpine recreation attraction in Bad Gastein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Graukogel, Bad Gastein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bad Gastein ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000258, 40000258, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000259, 40000259, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000260, 40000260, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000261, 40000261, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000262, 40000262, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000263, 40000263, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bad Gastein ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000258, 40000258, 'Bad Gastein Waterfall Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000259, 40000259, 'Stubnerkogel Suspension Bridge Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000260, 40000260, 'Felsentherme Bad Gastein Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000261, 40000261, 'Gastein Healing Gallery Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000262, 40000262, 'Historic Centre of Bad Gastein Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000263, 40000263, 'Graukogel Bad Gastein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 044 : HALLEIN (id 400044) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000264, 400044, 'Salzwelten Salzburg', 'Salzwelten Salzburg', 'A heritage landmark in Hallein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Salzwelten Salzburg, Hallein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000265, 400044, 'Keltenmuseum Hallein', 'Keltenmuseum Hallein', 'A museum and cultural attraction in Hallein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Keltenmuseum Hallein, Hallein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000266, 400044, 'Hallein Old Town', 'Hallein Old Town', 'A historic centre suited to walking and architecture in Hallein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hallein Old Town, Hallein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000267, 400044, 'Silent Night Museum Hallein', 'Silent Night Museum Hallein', 'A museum and cultural attraction in Hallein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Silent Night Museum Hallein, Hallein, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Hallein ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000264, 40000264, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000265, 40000265, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000266, 40000266, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000267, 40000267, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Hallein ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000264, 40000264, 'Salzwelten Salzburg Hallein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000265, 40000265, 'Keltenmuseum Hallein Hallein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000266, 40000266, 'Hallein Old Town Hallein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000267, 40000267, 'Silent Night Museum Hallein Hallein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 045 : WERFEN (id 400045) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000268, 400045, 'Hohenwerfen Fortress', 'Hohenwerfen Fortress', 'A historic fortress and panoramic heritage attraction in Werfen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hohenwerfen Fortress, Werfen, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000269, 400045, 'Eisriesenwelt Ice Cave', 'Eisriesenwelt Ice Cave', 'A cave and geological attraction in Werfen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Eisriesenwelt Ice Cave, Werfen, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000270, 400045, 'Werfen Parish Church', 'Werfen Parish Church', 'A historic church and religious landmark in Werfen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Werfen Parish Church, Werfen, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000271, 400045, 'Gschwandtanger Viewpoint', 'Gschwandtanger Viewpoint', 'A scenic viewpoint and photography stop in Werfen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gschwandtanger Viewpoint, Werfen, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Werfen ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000268, 40000268, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000269, 40000269, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000270, 40000270, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000271, 40000271, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Werfen ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000268, 40000268, 'Hohenwerfen Fortress Werfen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000269, 40000269, 'Eisriesenwelt Ice Cave Werfen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000270, 40000270, 'Werfen Parish Church Werfen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000271, 40000271, 'Gschwandtanger Viewpoint Werfen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 046 : RADSTADT (id 400046) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000272, 400046, 'Radstadt City Walls', 'Radstadt City Walls', 'A heritage landmark in Radstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Radstadt City Walls, Radstadt, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000273, 400046, 'Schloss Lerchen', 'Schloss Lerchen', 'A historic castle and heritage attraction in Radstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Lerchen, Radstadt, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000274, 400046, 'Heimatmuseum Schloss Lerchen', 'Heimatmuseum Schloss Lerchen', 'A museum and cultural attraction in Radstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Heimatmuseum Schloss Lerchen, Radstadt, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000275, 400046, 'Radstadt Parish Church', 'Radstadt Parish Church', 'A historic church and religious landmark in Radstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Radstadt Parish Church, Radstadt, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000276, 400046, 'Rossbrand Mountain', 'Rossbrand Mountain', 'A mountain and alpine recreation attraction in Radstadt, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rossbrand Mountain, Radstadt, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Radstadt ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000272, 40000272, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000273, 40000273, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000274, 40000274, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000275, 40000275, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000276, 40000276, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Radstadt ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000272, 40000272, 'Radstadt City Walls Radstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000273, 40000273, 'Schloss Lerchen Radstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000274, 40000274, 'Heimatmuseum Schloss Lerchen Radstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000275, 40000275, 'Radstadt Parish Church Radstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000276, 40000276, 'Rossbrand Mountain Radstadt', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 047 : MITTERSILL (id 400047) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000277, 400047, 'Nationalparkzentrum Hohe Tauern', 'Nationalparkzentrum Hohe Tauern', 'A museum and cultural attraction in Mittersill, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Nationalparkzentrum Hohe Tauern, Mittersill, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000278, 400047, 'Felberturm Museum', 'Felberturm Museum', 'A museum and cultural attraction in Mittersill, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Felberturm Museum, Mittersill, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000279, 400047, 'Mittersill Castle', 'Mittersill Castle', 'A historic castle and heritage attraction in Mittersill, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mittersill Castle, Mittersill, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000280, 400047, 'Hohe Tauern Panorama Mittersill', 'Hohe Tauern Panorama Mittersill', 'A scenic viewpoint and photography stop in Mittersill, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hohe Tauern Panorama Mittersill, Mittersill, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Mittersill ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000277, 40000277, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000278, 40000278, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000279, 40000279, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000280, 40000280, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Mittersill ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000277, 40000277, 'Nationalparkzentrum Hohe Tauern Mittersill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000278, 40000278, 'Felberturm Museum Mittersill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000279, 40000279, 'Mittersill Castle Mittersill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000280, 40000280, 'Hohe Tauern Panorama Mittersill Mittersill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 048 : SAALBACH-HINTERGLEMM (id 400048) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000281, 400048, 'Schattberg X-press', 'Schattberg X-press', 'A mountain cable-car experience and scenic access point in Saalbach-Hinterglemm, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schattberg X-press, Saalbach-Hinterglemm, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000282, 400048, 'Kohlmaisbahn', 'Kohlmaisbahn', 'A mountain cable-car experience and scenic access point in Saalbach-Hinterglemm, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kohlmaisbahn, Saalbach-Hinterglemm, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000283, 400048, 'Reiterkogelbahn', 'Reiterkogelbahn', 'A mountain cable-car experience and scenic access point in Saalbach-Hinterglemm, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Reiterkogelbahn, Saalbach-Hinterglemm, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000284, 400048, 'Treetop Trail and Golden Gate Bridge of the Alps', 'Treetop Trail and Golden Gate Bridge of the Alps', 'An outdoor adventure attraction in Saalbach-Hinterglemm, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Treetop Trail and Golden Gate Bridge of the Alps, Saalbach-Hinterglemm, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Saalbach-Hinterglemm ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000281, 40000281, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000282, 40000282, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000283, 40000283, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000284, 40000284, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Saalbach-Hinterglemm ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000281, 40000281, 'Schattberg X-press Saalbach-Hinterglemm', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000282, 40000282, 'Kohlmaisbahn Saalbach-Hinterglemm', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000283, 40000283, 'Reiterkogelbahn Saalbach-Hinterglemm', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000284, 40000284, 'Treetop Trail and Golden Gate Bridge of the Alps Saalbach-Hinterglemm', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 049 : OBERTAUERN (id 400049) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000285, 400049, 'Obertauern Ski Area', 'Obertauern Ski Area', 'An alpine skiing and mountain recreation area in Obertauern, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Obertauern Ski Area, Obertauern, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000286, 400049, 'Gamsleiten 2', 'Gamsleiten 2', 'An alpine skiing and mountain recreation area in Obertauern, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gamsleiten 2, Obertauern, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000287, 400049, 'Johannes Waterfall', 'Johannes Waterfall', 'A waterfall and nature attraction in Obertauern, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Johannes Waterfall, Obertauern, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000288, 400049, 'Grünwaldkopfbahn', 'Grünwaldkopfbahn', 'A mountain cable-car experience and scenic access point in Obertauern, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Grünwaldkopfbahn, Obertauern, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000289, 400049, 'Beatles Monument Obertauern', 'Beatles Monument Obertauern', 'A heritage landmark in Obertauern, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Salzburg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Beatles Monument Obertauern, Obertauern, Salzburg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Obertauern ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000285, 40000285, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000286, 40000286, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000287, 40000287, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000288, 40000288, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000289, 40000289, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Obertauern ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000285, 40000285, 'Obertauern Ski Area Obertauern', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000286, 40000286, 'Gamsleiten 2 Obertauern', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000287, 40000287, 'Johannes Waterfall Obertauern', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000288, 40000288, 'Grünwaldkopfbahn Obertauern', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000289, 40000289, 'Beatles Monument Obertauern Obertauern', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 050 : GRAZ (id 400050) — 11 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000290, 400050, 'City of Graz – Historic Centre and Schloss Eggenberg', 'City of Graz – Historic Centre and Schloss Eggenberg', 'A UNESCO World Heritage property or Austrian component in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'City of Graz – Historic Centre and Schloss Eggenberg, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000291, 400050, 'Schlossberg and Clock Tower', 'Schlossberg and Clock Tower', 'A scenic viewpoint and photography stop in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schlossberg and Clock Tower, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000292, 400050, 'Kunsthaus Graz', 'Kunsthaus Graz', 'A museum and cultural attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kunsthaus Graz, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000293, 400050, 'Styrian Armoury', 'Styrian Armoury', 'A museum and cultural attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Styrian Armoury, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000294, 400050, 'Schloss Eggenberg', 'Schloss Eggenberg', 'A major palace and architectural attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Eggenberg, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000295, 400050, 'Graz Cathedral', 'Graz Cathedral', 'A cathedral and architectural landmark in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Graz Cathedral, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000296, 400050, 'Mausoleum of Emperor Ferdinand II', 'Mausoleum of Emperor Ferdinand II', 'A heritage landmark in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mausoleum of Emperor Ferdinand II, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000297, 400050, 'Murinsel', 'Murinsel', 'An architecture and design attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Murinsel, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000298, 400050, 'Hauptplatz Graz', 'Hauptplatz Graz', 'A historic centre suited to walking and architecture in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hauptplatz Graz, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000299, 400050, 'Joanneumsviertel', 'Joanneumsviertel', 'A museum and cultural attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Joanneumsviertel, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000300, 400050, 'Graz Botanical Garden', 'Graz Botanical Garden', 'A landscaped garden and leisure attraction in Graz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Graz Botanical Garden, Graz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Graz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000290, 40000290, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000291, 40000291, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000292, 40000292, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000293, 40000293, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000294, 40000294, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000295, 40000295, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000296, 40000296, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000297, 40000297, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000298, 40000298, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000299, 40000299, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000300, 40000300, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Graz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000290, 40000290, 'City of Graz – Historic Centre and Schloss Eggenberg Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000291, 40000291, 'Schlossberg and Clock Tower Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000292, 40000292, 'Kunsthaus Graz Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000293, 40000293, 'Styrian Armoury Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000294, 40000294, 'Schloss Eggenberg Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000295, 40000295, 'Graz Cathedral Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000296, 40000296, 'Mausoleum of Emperor Ferdinand II Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000297, 40000297, 'Murinsel Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000298, 40000298, 'Hauptplatz Graz Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000299, 40000299, 'Joanneumsviertel Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000300, 40000300, 'Graz Botanical Garden Graz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 051 : SCHLADMING (id 400051) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000301, 400051, 'Planai', 'Planai', 'A mountain and alpine recreation attraction in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Planai, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000302, 400051, 'Planai Cable Car', 'Planai Cable Car', 'A mountain cable-car experience and scenic access point in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Planai Cable Car, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000303, 400051, 'Dachstein Glacier', 'Dachstein Glacier', 'A mountain and alpine recreation attraction in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dachstein Glacier, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000304, 400051, 'Dachstein Skywalk', 'Dachstein Skywalk', 'A scenic viewpoint and photography stop in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Dachstein Skywalk, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000305, 400051, 'Wilde Wasser', 'Wilde Wasser', 'A nature and outdoor recreation attraction in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wilde Wasser, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000306, 400051, 'Schladming Old Town', 'Schladming Old Town', 'A historic centre suited to walking and architecture in Schladming, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schladming Old Town, Schladming, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Schladming ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000301, 40000301, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000302, 40000302, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000303, 40000303, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000304, 40000304, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000305, 40000305, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000306, 40000306, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Schladming ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000301, 40000301, 'Planai Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000302, 40000302, 'Planai Cable Car Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000303, 40000303, 'Dachstein Glacier Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000304, 40000304, 'Dachstein Skywalk Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000305, 40000305, 'Wilde Wasser Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000306, 40000306, 'Schladming Old Town Schladming', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 052 : MARIAZELL (id 400052) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000307, 400052, 'Mariazell Basilica', 'Mariazell Basilica', 'A basilica and pilgrimage landmark in Mariazell, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mariazell Basilica, Mariazell, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000308, 400052, 'Bürgeralpe', 'Bürgeralpe', 'A mountain and alpine recreation attraction in Mariazell, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bürgeralpe, Mariazell, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000309, 400052, 'Museumstramway Mariazell', 'Museumstramway Mariazell', 'A scenic or heritage railway attraction in Mariazell, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museumstramway Mariazell, Mariazell, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000310, 400052, 'Erlaufsee', 'Erlaufsee', 'A lake and outdoor recreation destination in Mariazell, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Erlaufsee, Mariazell, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000311, 400052, 'Mariazell Old Town', 'Mariazell Old Town', 'A historic centre suited to walking and architecture in Mariazell, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mariazell Old Town, Mariazell, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Mariazell ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000307, 40000307, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000308, 40000308, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000309, 40000309, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000310, 40000310, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000311, 40000311, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Mariazell ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000307, 40000307, 'Mariazell Basilica Mariazell', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000308, 40000308, 'Bürgeralpe Mariazell', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000309, 40000309, 'Museumstramway Mariazell Mariazell', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000310, 40000310, 'Erlaufsee Mariazell', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000311, 40000311, 'Mariazell Old Town Mariazell', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 053 : ADMONT (id 400053) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000312, 400053, 'Admont Abbey', 'Admont Abbey', 'A historic abbey and cultural landmark in Admont, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Admont Abbey, Admont, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000313, 400053, 'Admont Abbey Library', 'Admont Abbey Library', 'A historic library and cultural attraction in Admont, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Admont Abbey Library, Admont, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000314, 400053, 'Admont Abbey Museum', 'Admont Abbey Museum', 'A museum and cultural attraction in Admont, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Admont Abbey Museum, Admont, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000315, 400053, 'Gesäuse National Park', 'Gesäuse National Park', 'A nature and outdoor recreation attraction in Admont, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gesäuse National Park, Admont, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000316, 400053, 'Admont Abbey Church', 'Admont Abbey Church', 'A historic church and religious landmark in Admont, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Admont Abbey Church, Admont, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Admont ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000312, 40000312, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000313, 40000313, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000314, 40000314, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000315, 40000315, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000316, 40000316, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Admont ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000312, 40000312, 'Admont Abbey Admont', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000313, 40000313, 'Admont Abbey Library Admont', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000314, 40000314, 'Admont Abbey Museum Admont', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000315, 40000315, 'Gesäuse National Park Admont', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000316, 40000316, 'Admont Abbey Church Admont', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 054 : BAD AUSSEE (id 400054) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000317, 400054, 'Kammerhof Museum', 'Kammerhof Museum', 'A museum and cultural attraction in Bad Aussee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kammerhof Museum, Bad Aussee, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000318, 400054, 'Kurpark Bad Aussee', 'Kurpark Bad Aussee', 'An urban park and leisure attraction in Bad Aussee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kurpark Bad Aussee, Bad Aussee, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000319, 400054, 'Traun Confluence Bad Aussee', 'Traun Confluence Bad Aussee', 'A riverfront and outdoor recreation attraction in Bad Aussee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Traun Confluence Bad Aussee, Bad Aussee, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000320, 400054, 'Grundlsee', 'Grundlsee', 'A lake and outdoor recreation destination in Bad Aussee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Grundlsee, Bad Aussee, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bad Aussee ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000317, 40000317, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000318, 40000318, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000319, 40000319, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000320, 40000320, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bad Aussee ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000317, 40000317, 'Kammerhof Museum Bad Aussee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000318, 40000318, 'Kurpark Bad Aussee Bad Aussee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000319, 40000319, 'Traun Confluence Bad Aussee Bad Aussee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000320, 40000320, 'Grundlsee Bad Aussee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 055 : EISENERZ (id 400055) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000321, 400055, 'Erzberg Mine', 'Erzberg Mine', 'An industrial-heritage attraction in Eisenerz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Erzberg Mine, Eisenerz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000322, 400055, 'Leopoldsteiner See', 'Leopoldsteiner See', 'A lake and outdoor recreation destination in Eisenerz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Leopoldsteiner See, Eisenerz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000323, 400055, 'St. Oswald Church Eisenerz', 'St. Oswald Church Eisenerz', 'A historic church and religious landmark in Eisenerz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Oswald Church Eisenerz, Eisenerz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000324, 400055, 'Erzbergbahn Heritage Railway', 'Erzbergbahn Heritage Railway', 'A scenic or heritage railway attraction in Eisenerz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Erzbergbahn Heritage Railway, Eisenerz, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Eisenerz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000321, 40000321, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000322, 40000322, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000323, 40000323, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000324, 40000324, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Eisenerz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000321, 40000321, 'Erzberg Mine Eisenerz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000322, 40000322, 'Leopoldsteiner See Eisenerz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000323, 40000323, 'St. Oswald Church Eisenerz Eisenerz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000324, 40000324, 'Erzbergbahn Heritage Railway Eisenerz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 056 : BAD RADKERSBURG (id 400056) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000325, 400056, 'Bad Radkersburg Old Town', 'Bad Radkersburg Old Town', 'A historic centre suited to walking and architecture in Bad Radkersburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bad Radkersburg Old Town, Bad Radkersburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000326, 400056, 'Bad Radkersburg Town Walls', 'Bad Radkersburg Town Walls', 'A heritage landmark in Bad Radkersburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bad Radkersburg Town Walls, Bad Radkersburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000327, 400056, 'Parktherme Bad Radkersburg', 'Parktherme Bad Radkersburg', 'A thermal spa and wellness attraction in Bad Radkersburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Parktherme Bad Radkersburg, Bad Radkersburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000328, 400056, 'Rathaus Bad Radkersburg', 'Rathaus Bad Radkersburg', 'A heritage landmark in Bad Radkersburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rathaus Bad Radkersburg, Bad Radkersburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000329, 400056, 'Frauenkirche Bad Radkersburg', 'Frauenkirche Bad Radkersburg', 'A historic church and religious landmark in Bad Radkersburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Frauenkirche Bad Radkersburg, Bad Radkersburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bad Radkersburg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000325, 40000325, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000326, 40000326, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000327, 40000327, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000328, 40000328, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000329, 40000329, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bad Radkersburg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000325, 40000325, 'Bad Radkersburg Old Town Bad Radkersburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000326, 40000326, 'Bad Radkersburg Town Walls Bad Radkersburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000327, 40000327, 'Parktherme Bad Radkersburg Bad Radkersburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000328, 40000328, 'Rathaus Bad Radkersburg Bad Radkersburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000329, 40000329, 'Frauenkirche Bad Radkersburg Bad Radkersburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 057 : FÜRSTENFELD (id 400057) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000330, 400057, 'Fürstenfeld Fortress Walls', 'Fürstenfeld Fortress Walls', 'A heritage landmark in Fürstenfeld, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Fürstenfeld Fortress Walls, Fürstenfeld, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000331, 400057, 'Pfeilburg Museum', 'Pfeilburg Museum', 'A museum and cultural attraction in Fürstenfeld, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pfeilburg Museum, Fürstenfeld, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000332, 400057, 'Fürstenfeld Parish Church', 'Fürstenfeld Parish Church', 'A historic church and religious landmark in Fürstenfeld, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Fürstenfeld Parish Church, Fürstenfeld, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000333, 400057, 'Stadtpark Fürstenfeld', 'Stadtpark Fürstenfeld', 'An urban park and leisure attraction in Fürstenfeld, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpark Fürstenfeld, Fürstenfeld, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Fürstenfeld ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000330, 40000330, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000331, 40000331, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000332, 40000332, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000333, 40000333, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Fürstenfeld ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000330, 40000330, 'Fürstenfeld Fortress Walls Fürstenfeld', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000331, 40000331, 'Pfeilburg Museum Fürstenfeld', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000332, 40000332, 'Fürstenfeld Parish Church Fürstenfeld', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000333, 40000333, 'Stadtpark Fürstenfeld Fürstenfeld', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 058 : HARTBERG (id 400058) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000334, 400058, 'Stadtmuseum Hartberg', 'Stadtmuseum Hartberg', 'A museum and cultural attraction in Hartberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtmuseum Hartberg, Hartberg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000335, 400058, 'Hartberg Castle', 'Hartberg Castle', 'A historic castle and heritage attraction in Hartberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hartberg Castle, Hartberg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000336, 400058, 'Hartberg Karner', 'Hartberg Karner', 'A heritage landmark in Hartberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hartberg Karner, Hartberg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000337, 400058, 'Stadtpfarrkirche Hartberg', 'Stadtpfarrkirche Hartberg', 'A historic church and religious landmark in Hartberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Stadtpfarrkirche Hartberg, Hartberg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000338, 400058, 'Hartberg Ring Wall', 'Hartberg Ring Wall', 'A heritage landmark in Hartberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hartberg Ring Wall, Hartberg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Hartberg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000334, 40000334, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000335, 40000335, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000336, 40000336, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000337, 40000337, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000338, 40000338, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Hartberg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000334, 40000334, 'Stadtmuseum Hartberg Hartberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000335, 40000335, 'Hartberg Castle Hartberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000336, 40000336, 'Hartberg Karner Hartberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000337, 40000337, 'Stadtpfarrkirche Hartberg Hartberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000338, 40000338, 'Hartberg Ring Wall Hartberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 059 : JUDENBURG (id 400059) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000339, 400059, 'Judenburg City Tower', 'Judenburg City Tower', 'A scenic viewpoint and photography stop in Judenburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Judenburg City Tower, Judenburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000340, 400059, 'Sternenturm Planetarium', 'Sternenturm Planetarium', 'A museum and cultural attraction in Judenburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Sternenturm Planetarium, Judenburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000341, 400059, 'Puch Museum Judenburg', 'Puch Museum Judenburg', 'A museum and cultural attraction in Judenburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Puch Museum Judenburg, Judenburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000342, 400059, 'Hauptplatz Judenburg', 'Hauptplatz Judenburg', 'A historic centre suited to walking and architecture in Judenburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hauptplatz Judenburg, Judenburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000343, 400059, 'Magdalena Church Judenburg', 'Magdalena Church Judenburg', 'A historic church and religious landmark in Judenburg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Styria', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Magdalena Church Judenburg, Judenburg, Styria, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Judenburg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000339, 40000339, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000340, 40000340, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000341, 40000341, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000342, 40000342, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000343, 40000343, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Judenburg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000339, 40000339, 'Judenburg City Tower Judenburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000340, 40000340, 'Sternenturm Planetarium Judenburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000341, 40000341, 'Puch Museum Judenburg Judenburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000342, 40000342, 'Hauptplatz Judenburg Judenburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000343, 40000343, 'Magdalena Church Judenburg Judenburg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 060 : INNSBRUCK (id 400060) — 14 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000344, 400060, 'Golden Roof', 'Golden Roof', 'A heritage landmark in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Golden Roof, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000345, 400060, 'Imperial Palace Innsbruck', 'Imperial Palace Innsbruck', 'A major palace and architectural attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Imperial Palace Innsbruck, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000346, 400060, 'Court Church Innsbruck', 'Court Church Innsbruck', 'A historic church and religious landmark in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Court Church Innsbruck, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000347, 400060, 'Nordkette', 'Nordkette', 'A mountain and alpine recreation attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Nordkette, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000348, 400060, 'Bergisel Ski Jump', 'Bergisel Ski Jump', 'A scenic viewpoint and photography stop in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bergisel Ski Jump, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000349, 400060, 'Ambras Castle', 'Ambras Castle', 'A historic castle and heritage attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ambras Castle, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000350, 400060, 'Alpine Zoo Innsbruck', 'Alpine Zoo Innsbruck', 'A wildlife and family attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Alpine Zoo Innsbruck, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000351, 400060, 'Maria-Theresien-Strasse', 'Maria-Theresien-Strasse', 'A historic centre suited to walking and architecture in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Maria-Theresien-Strasse, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000352, 400060, 'Innsbruck Cathedral', 'Innsbruck Cathedral', 'A cathedral and architectural landmark in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Innsbruck Cathedral, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000353, 400060, 'Tyrol Panorama Museum', 'Tyrol Panorama Museum', 'A museum and cultural attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tyrol Panorama Museum, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000354, 400060, 'Swarovski Crystal Worlds', 'Swarovski Crystal Worlds', 'A museum and cultural attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Swarovski Crystal Worlds, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000355, 400060, 'Hungerburg Funicular', 'Hungerburg Funicular', 'A scenic or heritage railway attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hungerburg Funicular, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000356, 400060, 'Innsbruck Old Town', 'Innsbruck Old Town', 'A historic centre suited to walking and architecture in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Innsbruck Old Town, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000357, 400060, 'Hofgarten Innsbruck', 'Hofgarten Innsbruck', 'A landscaped garden and leisure attraction in Innsbruck, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hofgarten Innsbruck, Innsbruck, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Innsbruck ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000344, 40000344, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000345, 40000345, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000346, 40000346, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000347, 40000347, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000348, 40000348, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000349, 40000349, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000350, 40000350, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000351, 40000351, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000352, 40000352, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000353, 40000353, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000354, 40000354, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000355, 40000355, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000356, 40000356, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000357, 40000357, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Innsbruck ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000344, 40000344, 'Golden Roof Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000345, 40000345, 'Imperial Palace Innsbruck Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000346, 40000346, 'Court Church Innsbruck Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000347, 40000347, 'Nordkette Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000348, 40000348, 'Bergisel Ski Jump Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000349, 40000349, 'Ambras Castle Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000350, 40000350, 'Alpine Zoo Innsbruck Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000351, 40000351, 'Maria-Theresien-Strasse Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000352, 40000352, 'Innsbruck Cathedral Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000353, 40000353, 'Tyrol Panorama Museum Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000354, 40000354, 'Swarovski Crystal Worlds Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000355, 40000355, 'Hungerburg Funicular Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000356, 40000356, 'Innsbruck Old Town Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000357, 40000357, 'Hofgarten Innsbruck Innsbruck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 061 : KITZBÜHEL (id 400061) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000358, 400061, 'Hahnenkamm', 'Hahnenkamm', 'A mountain and alpine recreation attraction in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hahnenkamm, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000359, 400061, 'Hahnenkammbahn', 'Hahnenkammbahn', 'A mountain cable-car experience and scenic access point in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hahnenkammbahn, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000360, 400061, 'Kitzbühel Old Town', 'Kitzbühel Old Town', 'A historic centre suited to walking and architecture in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kitzbühel Old Town, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000361, 400061, 'Museum Kitzbühel', 'Museum Kitzbühel', 'A museum and cultural attraction in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum Kitzbühel, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000362, 400061, 'Schwarzsee', 'Schwarzsee', 'A lake and outdoor recreation destination in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schwarzsee, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000363, 400061, 'St. Catherine Church Kitzbühel', 'St. Catherine Church Kitzbühel', 'A historic church and religious landmark in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Catherine Church Kitzbühel, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000364, 400061, 'Kitzbüheler Horn', 'Kitzbüheler Horn', 'A mountain and alpine recreation attraction in Kitzbühel, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kitzbüheler Horn, Kitzbühel, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Kitzbühel ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000358, 40000358, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000359, 40000359, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000360, 40000360, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000361, 40000361, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000362, 40000362, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000363, 40000363, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000364, 40000364, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Kitzbühel ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000358, 40000358, 'Hahnenkamm Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000359, 40000359, 'Hahnenkammbahn Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000360, 40000360, 'Kitzbühel Old Town Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000361, 40000361, 'Museum Kitzbühel Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000362, 40000362, 'Schwarzsee Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000363, 40000363, 'St. Catherine Church Kitzbühel Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000364, 40000364, 'Kitzbüheler Horn Kitzbühel', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 062 : KUFSTEIN (id 400062) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000365, 400062, 'Kufstein Fortress', 'Kufstein Fortress', 'A historic fortress and panoramic heritage attraction in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kufstein Fortress, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000366, 400062, 'Römerhofgasse', 'Römerhofgasse', 'A historic centre suited to walking and architecture in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Römerhofgasse, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000367, 400062, 'Heroes’ Organ', 'Heroes’ Organ', 'A music and performing-arts attraction in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Heroes’ Organ, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000368, 400062, 'Riedel Glass Factory and Museum', 'Riedel Glass Factory and Museum', 'A museum and cultural attraction in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Riedel Glass Factory and Museum, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000369, 400062, 'Hechtsee', 'Hechtsee', 'A lake and outdoor recreation destination in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hechtsee, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000370, 400062, 'St. Vitus Church Kufstein', 'St. Vitus Church Kufstein', 'A historic church and religious landmark in Kufstein, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Vitus Church Kufstein, Kufstein, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Kufstein ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000365, 40000365, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000366, 40000366, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000367, 40000367, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000368, 40000368, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000369, 40000369, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000370, 40000370, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Kufstein ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000365, 40000365, 'Kufstein Fortress Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000366, 40000366, 'Römerhofgasse Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000367, 40000367, 'Heroes’ Organ Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000368, 40000368, 'Riedel Glass Factory and Museum Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000369, 40000369, 'Hechtsee Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000370, 40000370, 'St. Vitus Church Kufstein Kufstein', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 063 : SEEFELD IN TIROL (id 400063) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000371, 400063, 'Seekirchl', 'Seekirchl', 'A historic church and religious landmark in Seefeld in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Seekirchl, Seefeld in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000372, 400063, 'Wildsee Seefeld', 'Wildsee Seefeld', 'A lake and outdoor recreation destination in Seefeld in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wildsee Seefeld, Seefeld in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000373, 400063, 'Rosshütte', 'Rosshütte', 'A mountain and alpine recreation attraction in Seefeld in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rosshütte, Seefeld in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000374, 400063, 'Seefeld Plateau Trails', 'Seefeld Plateau Trails', 'A hiking and nature area in Seefeld in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Seefeld Plateau Trails, Seefeld in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000375, 400063, 'St. Oswald Parish Church Seefeld', 'St. Oswald Parish Church Seefeld', 'A historic church and religious landmark in Seefeld in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Oswald Parish Church Seefeld, Seefeld in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Seefeld in Tirol ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000371, 40000371, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000372, 40000372, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000373, 40000373, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000374, 40000374, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000375, 40000375, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Seefeld in Tirol ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000371, 40000371, 'Seekirchl Seefeld in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000372, 40000372, 'Wildsee Seefeld Seefeld in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000373, 40000373, 'Rosshütte Seefeld in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000374, 40000374, 'Seefeld Plateau Trails Seefeld in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000375, 40000375, 'St. Oswald Parish Church Seefeld Seefeld in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 064 : MAYRHOFEN (id 400064) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000376, 400064, 'Penkenbahn', 'Penkenbahn', 'A mountain cable-car experience and scenic access point in Mayrhofen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Penkenbahn, Mayrhofen, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000377, 400064, 'Ahornbahn', 'Ahornbahn', 'A mountain cable-car experience and scenic access point in Mayrhofen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ahornbahn, Mayrhofen, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000378, 400064, 'Zillertal Alps Nature Park', 'Zillertal Alps Nature Park', 'A nature and outdoor recreation attraction in Mayrhofen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Zillertal Alps Nature Park, Mayrhofen, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000379, 400064, 'ErlebnisSennerei Zillertal', 'ErlebnisSennerei Zillertal', 'A food and regional-culture experience in Mayrhofen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'ErlebnisSennerei Zillertal, Mayrhofen, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000380, 400064, 'Mayrhofen Main Street', 'Mayrhofen Main Street', 'A historic centre suited to walking and architecture in Mayrhofen, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mayrhofen Main Street, Mayrhofen, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Mayrhofen ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000376, 40000376, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000377, 40000377, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000378, 40000378, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000379, 40000379, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000380, 40000380, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Mayrhofen ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000376, 40000376, 'Penkenbahn Mayrhofen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000377, 40000377, 'Ahornbahn Mayrhofen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000378, 40000378, 'Zillertal Alps Nature Park Mayrhofen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000379, 40000379, 'ErlebnisSennerei Zillertal Mayrhofen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000380, 40000380, 'Mayrhofen Main Street Mayrhofen', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 065 : ST. ANTON AM ARLBERG (id 400065) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000381, 400065, 'Galzigbahn', 'Galzigbahn', 'A mountain cable-car experience and scenic access point in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Galzigbahn, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000382, 400065, 'Valluga', 'Valluga', 'A mountain and alpine recreation attraction in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Valluga, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000383, 400065, 'Museum St. Anton am Arlberg', 'Museum St. Anton am Arlberg', 'A museum and cultural attraction in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Museum St. Anton am Arlberg, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000384, 400065, 'Ski Arlberg', 'Ski Arlberg', 'An alpine skiing and mountain recreation area in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ski Arlberg, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000385, 400065, 'Verwall Valley', 'Verwall Valley', 'A nature and outdoor recreation attraction in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Verwall Valley, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000386, 400065, 'St. Anton Parish Church', 'St. Anton Parish Church', 'A historic church and religious landmark in St. Anton am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Anton Parish Church, St. Anton am Arlberg, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: St. Anton am Arlberg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000381, 40000381, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000382, 40000382, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000383, 40000383, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000384, 40000384, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000385, 40000385, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000386, 40000386, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: St. Anton am Arlberg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000381, 40000381, 'Galzigbahn St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000382, 40000382, 'Valluga St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000383, 40000383, 'Museum St. Anton am Arlberg St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000384, 40000384, 'Ski Arlberg St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000385, 40000385, 'Verwall Valley St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000386, 40000386, 'St. Anton Parish Church St. Anton am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 066 : SÖLDEN (id 400066) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000387, 400066, 'Gaislachkogl', 'Gaislachkogl', 'A mountain and alpine recreation attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gaislachkogl, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000388, 400066, '007 ELEMENTS', '007 ELEMENTS', 'A museum and cultural attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, '007 ELEMENTS, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000389, 400066, 'ice Q', 'ice Q', 'An architecture and design attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'ice Q, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000390, 400066, 'Rettenbach Glacier', 'Rettenbach Glacier', 'A nature and outdoor recreation attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rettenbach Glacier, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000391, 400066, 'Tiefenbach Glacier', 'Tiefenbach Glacier', 'A nature and outdoor recreation attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tiefenbach Glacier, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000392, 400066, 'Freizeit Arena Sölden', 'Freizeit Arena Sölden', 'A thermal spa and wellness attraction in Sölden, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Freizeit Arena Sölden, Sölden, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Sölden ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000387, 40000387, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000388, 40000388, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000389, 40000389, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000390, 40000390, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000391, 40000391, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000392, 40000392, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Sölden ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000387, 40000387, 'Gaislachkogl Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000388, 40000388, '007 ELEMENTS Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000389, 40000389, 'ice Q Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000390, 40000390, 'Rettenbach Glacier Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000391, 40000391, 'Tiefenbach Glacier Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000392, 40000392, 'Freizeit Arena Sölden Sölden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 067 : LIENZ (id 400067) — 7 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000393, 400067, 'Schloss Bruck', 'Schloss Bruck', 'A historic castle and heritage attraction in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schloss Bruck, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000394, 400067, 'Hauptplatz Lienz', 'Hauptplatz Lienz', 'A historic centre suited to walking and architecture in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hauptplatz Lienz, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000395, 400067, 'Liebburg', 'Liebburg', 'A heritage landmark in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Liebburg, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000396, 400067, 'Zettersfeld', 'Zettersfeld', 'A mountain and alpine recreation attraction in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Zettersfeld, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000397, 400067, 'Hochstein', 'Hochstein', 'A mountain and alpine recreation attraction in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hochstein, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000398, 400067, 'Aguntum Roman Archaeological Park', 'Aguntum Roman Archaeological Park', 'An archaeological and ancient-history attraction in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Aguntum Roman Archaeological Park, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000399, 400067, 'Tristacher See', 'Tristacher See', 'A lake and outdoor recreation destination in Lienz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tristacher See, Lienz, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Lienz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000393, 40000393, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000394, 40000394, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000395, 40000395, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000396, 40000396, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000397, 40000397, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000398, 40000398, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000399, 40000399, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Lienz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000393, 40000393, 'Schloss Bruck Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000394, 40000394, 'Hauptplatz Lienz Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000395, 40000395, 'Liebburg Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000396, 40000396, 'Zettersfeld Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000397, 40000397, 'Hochstein Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000398, 40000398, 'Aguntum Roman Archaeological Park Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000399, 40000399, 'Tristacher See Lienz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 068 : HALL IN TIROL (id 400068) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000400, 400068, 'Hall in Tirol Old Town', 'Hall in Tirol Old Town', 'A historic centre suited to walking and architecture in Hall in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hall in Tirol Old Town, Hall in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000401, 400068, 'Mint Museum Hall', 'Mint Museum Hall', 'A museum and cultural attraction in Hall in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Mint Museum Hall, Hall in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000402, 400068, 'Hasegg Castle', 'Hasegg Castle', 'A historic castle and heritage attraction in Hall in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hasegg Castle, Hall in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000403, 400068, 'St. Nicholas Parish Church Hall', 'St. Nicholas Parish Church Hall', 'A historic church and religious landmark in Hall in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Nicholas Parish Church Hall, Hall in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000404, 400068, 'Oberer Stadtplatz Hall', 'Oberer Stadtplatz Hall', 'A historic centre suited to walking and architecture in Hall in Tirol, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Oberer Stadtplatz Hall, Hall in Tirol, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Hall in Tirol ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000400, 40000400, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000401, 40000401, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000402, 40000402, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000403, 40000403, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000404, 40000404, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Hall in Tirol ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000400, 40000400, 'Hall in Tirol Old Town Hall in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000401, 40000401, 'Mint Museum Hall Hall in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000402, 40000402, 'Hasegg Castle Hall in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000403, 40000403, 'St. Nicholas Parish Church Hall Hall in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000404, 40000404, 'Oberer Stadtplatz Hall Hall in Tirol', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 069 : ALPBACH (id 400069) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000405, 400069, 'Alpbach Village Centre', 'Alpbach Village Centre', 'A historic centre suited to walking and architecture in Alpbach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Alpbach Village Centre, Alpbach, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000406, 400069, 'Congress Centrum Alpbach', 'Congress Centrum Alpbach', 'An architecture and design attraction in Alpbach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Congress Centrum Alpbach, Alpbach, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000407, 400069, 'Wiedersbergerhornbahn', 'Wiedersbergerhornbahn', 'A mountain cable-car experience and scenic access point in Alpbach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wiedersbergerhornbahn, Alpbach, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000408, 400069, 'Ski Juwel Alpbachtal Wildschönau', 'Ski Juwel Alpbachtal Wildschönau', 'An alpine skiing and mountain recreation area in Alpbach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ski Juwel Alpbachtal Wildschönau, Alpbach, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000409, 400069, 'St. Oswald Church Alpbach', 'St. Oswald Church Alpbach', 'A historic church and religious landmark in Alpbach, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Oswald Church Alpbach, Alpbach, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Alpbach ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000405, 40000405, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000406, 40000406, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000407, 40000407, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000408, 40000408, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000409, 40000409, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Alpbach ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000405, 40000405, 'Alpbach Village Centre Alpbach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000406, 40000406, 'Congress Centrum Alpbach Alpbach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000407, 40000407, 'Wiedersbergerhornbahn Alpbach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000408, 40000408, 'Ski Juwel Alpbachtal Wildschönau Alpbach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000409, 40000409, 'St. Oswald Church Alpbach Alpbach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 070 : ISCHGL (id 400070) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000410, 400070, 'Silvretta Arena', 'Silvretta Arena', 'An alpine skiing and mountain recreation area in Ischgl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Silvretta Arena, Ischgl, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000411, 400070, 'Silvrettabahn', 'Silvrettabahn', 'A mountain cable-car experience and scenic access point in Ischgl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Silvrettabahn, Ischgl, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000412, 400070, 'Pardatschgratbahn', 'Pardatschgratbahn', 'A mountain cable-car experience and scenic access point in Ischgl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pardatschgratbahn, Ischgl, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000413, 400070, 'Seilbahnmuseum Ischgl', 'Seilbahnmuseum Ischgl', 'A museum and cultural attraction in Ischgl, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Seilbahnmuseum Ischgl, Ischgl, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Ischgl ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000410, 40000410, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000411, 40000411, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000412, 40000412, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000413, 40000413, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Ischgl ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000410, 40000410, 'Silvretta Arena Ischgl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000411, 40000411, 'Silvrettabahn Ischgl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000412, 40000412, 'Pardatschgratbahn Ischgl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000413, 40000413, 'Seilbahnmuseum Ischgl Ischgl', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 071 : PERTISAU AM ACHENSEE (id 400071) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000414, 400071, 'Lake Achensee', 'Lake Achensee', 'A lake and outdoor recreation destination in Pertisau am Achensee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Achensee, Pertisau am Achensee, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000415, 400071, 'Karwendel Cable Car', 'Karwendel Cable Car', 'A mountain cable-car experience and scenic access point in Pertisau am Achensee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Karwendel Cable Car, Pertisau am Achensee, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000416, 400071, 'Achensee Shipping', 'Achensee Shipping', 'A lake or river boat experience in Pertisau am Achensee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Achensee Shipping, Pertisau am Achensee, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000417, 400071, 'Tiroler Steinöl Vitalberg', 'Tiroler Steinöl Vitalberg', 'A museum and cultural attraction in Pertisau am Achensee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tiroler Steinöl Vitalberg, Pertisau am Achensee, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000418, 400071, 'Falzthurn Valley', 'Falzthurn Valley', 'A nature and outdoor recreation attraction in Pertisau am Achensee, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Tyrol', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Falzthurn Valley, Pertisau am Achensee, Tyrol, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Pertisau am Achensee ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000414, 40000414, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000415, 40000415, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000416, 40000416, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000417, 40000417, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000418, 40000418, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Pertisau am Achensee ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000414, 40000414, 'Lake Achensee Pertisau am Achensee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000415, 40000415, 'Karwendel Cable Car Pertisau am Achensee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000416, 40000416, 'Achensee Shipping Pertisau am Achensee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000417, 40000417, 'Tiroler Steinöl Vitalberg Pertisau am Achensee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000418, 40000418, 'Falzthurn Valley Pertisau am Achensee', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 072 : BREGENZ (id 400072) — 8 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000419, 400072, 'Bregenz Festival Floating Stage', 'Bregenz Festival Floating Stage', 'A music and performing-arts attraction in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bregenz Festival Floating Stage, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000420, 400072, 'Kunsthaus Bregenz', 'Kunsthaus Bregenz', 'A museum and cultural attraction in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kunsthaus Bregenz, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000421, 400072, 'Pfänder', 'Pfänder', 'A mountain and alpine recreation attraction in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Pfänder, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000422, 400072, 'Vorarlberg Museum', 'Vorarlberg Museum', 'A museum and cultural attraction in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Vorarlberg Museum, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000423, 400072, 'Martinsturm', 'Martinsturm', 'A heritage landmark in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Martinsturm, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000424, 400072, 'Bregenz Upper Town', 'Bregenz Upper Town', 'A historic centre suited to walking and architecture in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bregenz Upper Town, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000425, 400072, 'Lake Constance Promenade Bregenz', 'Lake Constance Promenade Bregenz', 'A lake and outdoor recreation destination in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Lake Constance Promenade Bregenz, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000426, 400072, 'Herz-Jesu-Kirche Bregenz', 'Herz-Jesu-Kirche Bregenz', 'A historic church and religious landmark in Bregenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Herz-Jesu-Kirche Bregenz, Bregenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bregenz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000419, 40000419, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000420, 40000420, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000421, 40000421, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000422, 40000422, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000423, 40000423, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000424, 40000424, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000425, 40000425, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000426, 40000426, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bregenz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000419, 40000419, 'Bregenz Festival Floating Stage Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000420, 40000420, 'Kunsthaus Bregenz Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000421, 40000421, 'Pfänder Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000422, 40000422, 'Vorarlberg Museum Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000423, 40000423, 'Martinsturm Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000424, 40000424, 'Bregenz Upper Town Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000425, 40000425, 'Lake Constance Promenade Bregenz Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000426, 40000426, 'Herz-Jesu-Kirche Bregenz Bregenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 073 : FELDKIRCH (id 400073) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000427, 400073, 'Schattenburg Castle', 'Schattenburg Castle', 'A historic castle and heritage attraction in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Schattenburg Castle, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000428, 400073, 'Marktgasse Feldkirch', 'Marktgasse Feldkirch', 'A historic centre suited to walking and architecture in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Marktgasse Feldkirch, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000429, 400073, 'Katzenturm', 'Katzenturm', 'A heritage landmark in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Katzenturm, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000430, 400073, 'St. Nicholas Cathedral Feldkirch', 'St. Nicholas Cathedral Feldkirch', 'A cathedral and architectural landmark in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Nicholas Cathedral Feldkirch, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000431, 400073, 'Wildpark Feldkirch', 'Wildpark Feldkirch', 'A wildlife and family attraction in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wildpark Feldkirch, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000432, 400073, 'Feldkirch Old Town', 'Feldkirch Old Town', 'A historic centre suited to walking and architecture in Feldkirch, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Feldkirch Old Town, Feldkirch, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Feldkirch ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000427, 40000427, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000428, 40000428, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000429, 40000429, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000430, 40000430, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000431, 40000431, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000432, 40000432, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Feldkirch ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000427, 40000427, 'Schattenburg Castle Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000428, 40000428, 'Marktgasse Feldkirch Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000429, 40000429, 'Katzenturm Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000430, 40000430, 'St. Nicholas Cathedral Feldkirch Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000431, 40000431, 'Wildpark Feldkirch Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000432, 40000432, 'Feldkirch Old Town Feldkirch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 074 : DORNBIRN (id 400074) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000433, 400074, 'inatura', 'inatura', 'A museum and cultural attraction in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'inatura, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000434, 400074, 'Karren Cable Car', 'Karren Cable Car', 'A mountain cable-car experience and scenic access point in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Karren Cable Car, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000435, 400074, 'Rappenloch Gorge', 'Rappenloch Gorge', 'A nature and outdoor recreation attraction in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rappenloch Gorge, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000436, 400074, 'Rolls-Royce Museum Dornbirn', 'Rolls-Royce Museum Dornbirn', 'A museum and cultural attraction in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rolls-Royce Museum Dornbirn, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000437, 400074, 'Marktplatz Dornbirn', 'Marktplatz Dornbirn', 'A historic centre suited to walking and architecture in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Marktplatz Dornbirn, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000438, 400074, 'Bödele', 'Bödele', 'A mountain and alpine recreation attraction in Dornbirn, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '3-6 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bödele, Dornbirn, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Dornbirn ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000433, 40000433, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000434, 40000434, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000435, 40000435, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000436, 40000436, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000437, 40000437, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000438, 40000438, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Dornbirn ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000433, 40000433, 'inatura Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000434, 40000434, 'Karren Cable Car Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000435, 40000435, 'Rappenloch Gorge Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000436, 40000436, 'Rolls-Royce Museum Dornbirn Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000437, 40000437, 'Marktplatz Dornbirn Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000438, 40000438, 'Bödele Dornbirn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 075 : BLUDENZ (id 400075) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000439, 400075, 'Bludenz Old Town', 'Bludenz Old Town', 'A historic centre suited to walking and architecture in Bludenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bludenz Old Town, Bludenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000440, 400075, 'St. Laurentius Church Bludenz', 'St. Laurentius Church Bludenz', 'A historic church and religious landmark in Bludenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Laurentius Church Bludenz, Bludenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000441, 400075, 'Gayenhofen Castle', 'Gayenhofen Castle', 'A historic castle and heritage attraction in Bludenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Gayenhofen Castle, Bludenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000442, 400075, 'Muttersberg Cable Car', 'Muttersberg Cable Car', 'A mountain cable-car experience and scenic access point in Bludenz, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Muttersberg Cable Car, Bludenz, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bludenz ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000439, 40000439, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000440, 40000440, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000441, 40000441, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000442, 40000442, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bludenz ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000439, 40000439, 'Bludenz Old Town Bludenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000440, 40000440, 'St. Laurentius Church Bludenz Bludenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000441, 40000441, 'Gayenhofen Castle Bludenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000442, 40000442, 'Muttersberg Cable Car Bludenz', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 076 : LECH AM ARLBERG (id 400076) — 6 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000443, 400076, 'Ski Arlberg Lech', 'Ski Arlberg Lech', 'An alpine skiing and mountain recreation area in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Ski Arlberg Lech, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000444, 400076, 'Rüfikopf Cable Car', 'Rüfikopf Cable Car', 'A mountain cable-car experience and scenic access point in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Rüfikopf Cable Car, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000445, 400076, 'Skyspace Lech', 'Skyspace Lech', 'An art and design attraction in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Skyspace Lech, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000446, 400076, 'Huber-Hus Museum', 'Huber-Hus Museum', 'A museum and cultural attraction in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Huber-Hus Museum, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000447, 400076, 'Formarinsee', 'Formarinsee', 'A lake and outdoor recreation destination in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Formarinsee, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000448, 400076, 'Körbersee', 'Körbersee', 'A lake and outdoor recreation destination in Lech am Arlberg, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Körbersee, Lech am Arlberg, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Lech am Arlberg ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000443, 40000443, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000444, 40000444, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000445, 40000445, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000446, 40000446, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000447, 40000447, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000448, 40000448, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Lech am Arlberg ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000443, 40000443, 'Ski Arlberg Lech Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000444, 40000444, 'Rüfikopf Cable Car Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000445, 40000445, 'Skyspace Lech Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000446, 40000446, 'Huber-Hus Museum Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000447, 40000447, 'Formarinsee Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000448, 40000448, 'Körbersee Lech am Arlberg', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 077 : SCHRUNS (id 400077) — 4 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000449, 400077, 'Montafoner Heimatmuseum', 'Montafoner Heimatmuseum', 'A museum and cultural attraction in Schruns, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Montafoner Heimatmuseum, Schruns, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000450, 400077, 'Hochjochbahn', 'Hochjochbahn', 'A mountain cable-car experience and scenic access point in Schruns, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hochjochbahn, Schruns, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000451, 400077, 'Silvretta Montafon', 'Silvretta Montafon', 'An alpine skiing and mountain recreation area in Schruns, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', 'Half day or full day', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Silvretta Montafon, Schruns, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000452, 400077, 'Litz Promenade Schruns', 'Litz Promenade Schruns', 'A riverfront and outdoor recreation attraction in Schruns, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Litz Promenade Schruns, Schruns, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Schruns ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000449, 40000449, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000450, 40000450, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000451, 40000451, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000452, 40000452, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Schruns ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000449, 40000449, 'Montafoner Heimatmuseum Schruns', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000450, 40000450, 'Hochjochbahn Schruns', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000451, 40000451, 'Silvretta Montafon Schruns', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000452, 40000452, 'Litz Promenade Schruns Schruns', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 078 : BEZAU (id 400078) — 5 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000453, 400078, 'Bezau Cable Car', 'Bezau Cable Car', 'A mountain cable-car experience and scenic access point in Bezau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bezau Cable Car, Bezau, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000454, 400078, 'Bregenzerwald Museum Bezau', 'Bregenzerwald Museum Bezau', 'A museum and cultural attraction in Bezau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bregenzerwald Museum Bezau, Bezau, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000455, 400078, 'Wälderbähnle Heritage Railway', 'Wälderbähnle Heritage Railway', 'A scenic or heritage railway attraction in Bezau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Wälderbähnle Heritage Railway, Bezau, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000456, 400078, 'St. Jodok Parish Church Bezau', 'St. Jodok Parish Church Bezau', 'A historic church and religious landmark in Bezau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Jodok Parish Church Bezau, Bezau, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000457, 400078, 'Bezau Architecture Trail', 'Bezau Architecture Trail', 'An architecture and design attraction in Bezau, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vorarlberg', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Bezau Architecture Trail, Bezau, Vorarlberg, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Bezau ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000453, 40000453, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000454, 40000454, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000455, 40000455, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000456, 40000456, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000457, 40000457, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Bezau ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000453, 40000453, 'Bezau Cable Car Bezau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000454, 40000454, 'Bregenzerwald Museum Bezau Bezau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000455, 40000455, 'Wälderbähnle Heritage Railway Bezau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000456, 40000456, 'St. Jodok Parish Church Bezau Bezau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000457, 40000457, 'Bezau Architecture Trail Bezau', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ============================================================================
-- CITY 079 : VIENNA (id 400079) — 18 places
-- ============================================================================
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
(40000458, 400079, 'Historic Centre of Vienna', 'Historic Centre of Vienna', 'A UNESCO World Heritage property or Austrian component in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Historic Centre of Vienna, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000459, 400079, 'Palace and Gardens of Schönbrunn', 'Palace and Gardens of Schönbrunn', 'A UNESCO World Heritage property or Austrian component in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-4 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Palace and Gardens of Schönbrunn, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'verified', 'UNESCO World Heritage Centre lists this property or Austrian serial component; precise venue coordinates, hours and prices are intentionally omitted until venue-level verification.', '2026-10-02'),
(40000460, 400079, 'Hofburg Palace', 'Hofburg Palace', 'A major palace and architectural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hofburg Palace, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000461, 400079, 'St. Stephen’s Cathedral', 'St. Stephen’s Cathedral', 'A cathedral and architectural landmark in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'St. Stephen’s Cathedral, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000462, 400079, 'Belvedere Palace', 'Belvedere Palace', 'A major palace and architectural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Belvedere Palace, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000463, 400079, 'Kunsthistorisches Museum Vienna', 'Kunsthistorisches Museum Vienna', 'A museum and cultural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Kunsthistorisches Museum Vienna, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000464, 400079, 'Albertina', 'Albertina', 'A museum and cultural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Albertina, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000465, 400079, 'Vienna State Opera', 'Vienna State Opera', 'A music and performing-arts attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Vienna State Opera, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000466, 400079, 'Prater and Giant Ferris Wheel', 'Prater and Giant Ferris Wheel', 'A family-oriented visitor attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Prater and Giant Ferris Wheel, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000467, 400079, 'MuseumsQuartier Vienna', 'MuseumsQuartier Vienna', 'A museum and cultural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'MuseumsQuartier Vienna, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'museum', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000468, 400079, 'Austrian National Library', 'Austrian National Library', 'A historic library and cultural attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Austrian National Library, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000469, 400079, 'Karlskirche', 'Karlskirche', 'A historic church and religious landmark in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Karlskirche, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000470, 400079, 'Naschmarkt', 'Naschmarkt', 'A market and food-culture attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Naschmarkt, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000471, 400079, 'Hundertwasser House', 'Hundertwasser House', 'An architecture and design attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1 hour', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Hundertwasser House, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000472, 400079, 'Danube Tower', 'Danube Tower', 'A scenic viewpoint and photography stop in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '45-90 minutes', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Danube Tower, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000473, 400079, 'Tiergarten Schönbrunn', 'Tiergarten Schönbrunn', 'A wildlife and family attraction in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '2-3 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Tiergarten Schönbrunn, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000474, 400079, 'Spanish Riding School', 'Spanish Riding School', 'A heritage landmark in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Spanish Riding School, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02'),
(40000475, 400079, 'Vienna City Hall', 'Vienna City Hall', 'A heritage landmark in Vienna, included in TripRaft''s Austria seed for itinerary planning and destination discovery.', '1-2 hours', '', 'Check the venue or destination official source before travel; operational details are intentionally not guessed in this seed.', '', 'Vienna', NULL, NULL, '', '', '', NULL, NULL, NULL, NULL, 'Vienna City Hall, Vienna, Vienna, Austria', '', NULL, '2026-10-02 12:00:00', NULL, 'attraction', NULL, NULL, NULL, 'own', '2026-10-02 12:00:00', 'partial', 'Place identity/city association included in the Austria tourism coverage pass; precise venue coordinates, hours, prices, ratings and official URL are intentionally omitted rather than guessed.', '2026-10-02');

-- ---- HOURS: Vienna ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
(40000458, 40000458, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000459, 40000459, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000460, 40000460, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000461, 40000461, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000462, 40000462, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000463, 40000463, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000464, 40000464, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000465, 40000465, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000466, 40000466, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000467, 40000467, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000468, 40000468, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000469, 40000469, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000470, 40000470, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000471, 40000471, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000472, 40000472, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000473, 40000473, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000474, 40000474, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.'),
(40000475, 40000475, '', '', '', '', '', '', '', 'Hours intentionally left blank: verify from the official venue/destination source before publishing.');

-- ---- PHOTOS: Vienna ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
(40000458, 40000458, 'Historic Centre of Vienna Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000459, 40000459, 'Palace and Gardens of Schönbrunn Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000460, 40000460, 'Hofburg Palace Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000461, 40000461, 'St. Stephen’s Cathedral Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000462, 40000462, 'Belvedere Palace Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000463, 40000463, 'Kunsthistorisches Museum Vienna Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000464, 40000464, 'Albertina Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000465, 40000465, 'Vienna State Opera Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000466, 40000466, 'Prater and Giant Ferris Wheel Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000467, 40000467, 'MuseumsQuartier Vienna Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000468, 40000468, 'Austrian National Library Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000469, 40000469, 'Karlskirche Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000470, 40000470, 'Naschmarkt Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000471, 40000471, 'Hundertwasser House Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000472, 40000472, 'Danube Tower Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000473, 40000473, 'Tiergarten Schönbrunn Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000474, 40000474, 'Spanish Riding School Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
(40000475, 40000475, 'Vienna City Hall Vienna', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 40000001, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000001, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000001, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000002, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000002, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000003, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000003, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000003, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000004, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000004, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000005, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000005, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000005, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000006, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000006, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000007, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000007, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000007, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000007, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000008, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000008, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000009, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000009, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000009, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000010, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000010, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000010, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000011, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000011, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000012, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000012, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000013, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000013, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000013, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000014, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000014, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000014, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000015, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000015, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000015, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000016, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000016, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000016, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000017, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000017, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000018, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000018, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000018, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000019, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000019, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000020, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000020, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000020, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000021, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000021, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000022, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000022, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000022, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000023, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000023, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000023, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000024, id FROM tags WHERE tag_name = 'Music';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000024, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000025, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000025, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000025, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000026, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000026, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000027, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000027, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000027, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000028, id FROM tags WHERE tag_name = 'Food';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000028, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000029, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000029, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000030, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000030, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000031, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000031, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000032, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000032, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000032, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000033, id FROM tags WHERE tag_name = 'Food';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000033, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000034, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000034, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000034, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000035, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000035, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000036, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000036, id FROM tags WHERE tag_name = 'Monastery';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000036, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000037, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000037, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000037, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000038, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000038, id FROM tags WHERE tag_name = 'Attraction';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000039, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000039, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000039, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000040, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000040, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000041, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000041, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000042, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000042, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000042, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000043, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000043, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000043, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000043, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000044, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000044, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000045, id FROM tags WHERE tag_name = 'Zoo';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000045, id FROM tags WHERE tag_name = 'Wildlife';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000045, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000046, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000046, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000046, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000047, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000047, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000047, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000048, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000048, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000048, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000049, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000049, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000049, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000050, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000050, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000051, id FROM tags WHERE tag_name = 'Scenic Drive';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000051, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000051, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000052, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000052, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000053, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000053, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000054, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000054, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000054, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000055, id FROM tags WHERE tag_name = 'Zoo';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000055, id FROM tags WHERE tag_name = 'Wildlife';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000055, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000056, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000056, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000056, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000057, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000057, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000057, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000058, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000058, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000058, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000059, id FROM tags WHERE tag_name = 'Attraction';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000059, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000060, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000060, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000060, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000061, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000061, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000061, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000062, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000062, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000062, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000063, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000063, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000064, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000064, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000064, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000065, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000065, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000066, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000066, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000066, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000067, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000067, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000067, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000068, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000068, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000068, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000069, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000069, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000070, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000070, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000070, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000071, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000071, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000072, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000072, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000073, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000073, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000074, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000074, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000074, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000075, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000075, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000076, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000076, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000076, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000077, id FROM tags WHERE tag_name = 'Scenic Drive';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000077, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000077, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000078, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000078, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000078, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000079, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000079, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000079, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000080, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000080, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000081, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000081, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000082, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000082, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000082, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000083, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000083, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000083, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000084, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000084, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000085, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000085, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000085, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000086, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000086, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000086, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000087, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000087, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000087, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000087, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000088, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000088, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000088, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000089, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000089, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000089, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000090, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000090, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000090, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000091, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000091, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000092, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000092, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000092, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000092, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000093, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000093, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000093, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000093, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000094, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000094, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000094, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000095, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000095, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000096, id FROM tags WHERE tag_name = 'Music';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000096, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000097, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000097, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000098, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000098, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000099, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000099, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000100, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000100, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000101, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000101, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000102, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000102, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000102, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000103, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000103, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000103, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000104, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000104, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000104, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000105, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000105, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000105, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000106, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000106, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000106, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000107, id FROM tags WHERE tag_name = 'Garden';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000107, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000107, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000108, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000108, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000108, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000109, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000109, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000109, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000110, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000110, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000110, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000111, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000111, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000111, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000112, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000112, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000112, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000113, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000113, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000113, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000114, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000114, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000114, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000115, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000115, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000116, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000116, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000116, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000117, id FROM tags WHERE tag_name = 'Attraction';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000117, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000118, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000118, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000118, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000119, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000119, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000120, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000120, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000121, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000121, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000122, id FROM tags WHERE tag_name = 'Garden';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000122, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000122, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000123, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000123, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000123, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000123, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000124, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000124, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000125, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000125, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000126, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000126, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000126, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000127, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000127, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000128, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000128, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000129, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000129, id FROM tags WHERE tag_name = 'Monastery';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000129, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000130, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000130, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000131, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000131, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000132, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000132, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000133, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000133, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000133, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000134, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000134, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000135, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000135, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000135, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000136, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000136, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000136, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000136, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000137, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000137, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000137, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000138, id FROM tags WHERE tag_name = 'Archaeology';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000138, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000138, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000139, id FROM tags WHERE tag_name = 'Archaeology';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000139, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000139, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000140, id FROM tags WHERE tag_name = 'Archaeology';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000140, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000140, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000141, id FROM tags WHERE tag_name = 'Archaeology';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000141, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000141, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000142, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000142, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000142, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000143, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000143, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000144, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000144, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000145, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000145, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000146, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000146, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000147, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000147, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000147, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000148, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000148, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000149, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000149, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000150, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000150, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000150, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000151, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000151, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000152, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000152, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000153, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000153, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000154, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000154, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000154, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000155, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000155, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000155, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000156, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000156, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000156, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000157, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000157, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000157, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000158, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000158, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000159, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000159, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000160, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000160, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000161, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000161, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000162, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000162, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000162, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000162, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000163, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000163, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000163, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000164, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000164, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000165, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000165, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000165, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000166, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000166, id FROM tags WHERE tag_name = 'Attraction';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000167, id FROM tags WHERE tag_name = 'Art';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000167, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000168, id FROM tags WHERE tag_name = 'Garden';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000168, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000168, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000169, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000169, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000170, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000170, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000170, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000171, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000171, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000171, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000172, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000172, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000173, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000173, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000174, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000174, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000175, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000175, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000175, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000176, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000176, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000177, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000177, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000177, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000178, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000178, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000178, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000179, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000179, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000179, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000180, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000180, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000181, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000181, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000182, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000182, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000182, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000183, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000183, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000184, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000184, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000185, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000185, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000186, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000186, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000186, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000187, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000187, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000188, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000188, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000188, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000189, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000189, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000189, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000190, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000190, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000191, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000191, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000191, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000192, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000192, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000192, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000193, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000193, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000193, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000194, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000194, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000195, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000195, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000195, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000196, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000196, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000197, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000197, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000197, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000198, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000198, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000198, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000199, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000199, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000199, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000200, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000200, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000200, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000201, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000201, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000201, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000202, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000202, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000202, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000203, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000203, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000204, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000204, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000205, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000205, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000205, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000206, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000206, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000206, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000207, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000207, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000207, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000208, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000208, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000209, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000209, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000209, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000210, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000210, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000210, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000210, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000211, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000211, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000211, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000212, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000212, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000212, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000213, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000213, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000213, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000214, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000214, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000214, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000215, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000215, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000215, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000216, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000216, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000217, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000217, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000218, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000218, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000218, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000219, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000219, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000220, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000220, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000220, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000221, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000221, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000222, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000222, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000222, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000222, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000223, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000223, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000224, id FROM tags WHERE tag_name = 'Caves';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000224, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000224, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000225, id FROM tags WHERE tag_name = 'Caves';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000225, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000225, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000226, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000226, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000226, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000227, id FROM tags WHERE tag_name = 'Caves';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000227, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000227, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000228, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000228, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000228, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000229, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000229, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000229, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000230, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000230, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000231, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000231, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000231, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000232, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000232, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000232, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000233, id FROM tags WHERE tag_name = 'Fortress';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000233, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000233, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000234, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000234, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000234, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000235, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000235, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000235, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000235, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000236, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000236, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000237, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000237, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000238, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000238, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000238, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000239, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000239, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000239, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000240, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000240, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000241, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000241, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000241, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000242, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000242, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000243, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000243, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000244, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000244, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000245, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000245, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000245, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000246, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000246, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000247, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000247, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000247, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000248, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000248, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000248, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000248, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000249, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000249, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000249, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000250, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000250, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000250, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000251, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000251, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000251, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000252, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000252, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000252, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000252, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000253, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000253, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000254, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000254, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000255, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000255, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000255, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000256, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000256, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000257, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000257, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000258, id FROM tags WHERE tag_name = 'Waterfall';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000258, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000258, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000259, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000259, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000260, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000260, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000261, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000261, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000262, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000262, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000262, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000263, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000263, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000263, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000263, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000264, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000264, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000265, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000265, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000266, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000266, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000266, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000267, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000267, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000268, id FROM tags WHERE tag_name = 'Fortress';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000268, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000268, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000269, id FROM tags WHERE tag_name = 'Caves';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000269, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000269, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000270, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000270, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000270, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000271, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000271, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000272, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000272, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000273, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000273, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000273, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000274, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000274, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000275, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000275, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000275, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000276, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000276, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000276, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000276, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000277, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000277, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000278, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000278, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000279, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000279, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000279, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000280, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000280, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000281, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000281, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000281, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000282, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000282, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000282, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000283, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000283, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000283, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000284, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000284, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000284, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000285, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000285, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000285, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000286, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000286, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000286, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000287, id FROM tags WHERE tag_name = 'Waterfall';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000287, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000287, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000288, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000288, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000288, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000289, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000289, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000290, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000290, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000290, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000291, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000291, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000292, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000292, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000293, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000293, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000294, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000294, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000294, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000295, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000295, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000295, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000295, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000296, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000296, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000297, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000297, id FROM tags WHERE tag_name = 'Design';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000298, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000298, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000298, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000299, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000299, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000300, id FROM tags WHERE tag_name = 'Garden';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000300, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000300, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000301, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000301, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000301, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000301, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000302, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000302, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000302, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000303, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000303, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000303, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000303, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000304, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000304, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000305, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000305, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000306, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000306, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000306, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000307, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000307, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000307, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000308, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000308, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000308, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000308, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000309, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000309, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000309, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000310, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000310, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000310, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000311, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000311, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000311, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000312, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000312, id FROM tags WHERE tag_name = 'Abbey';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000312, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000313, id FROM tags WHERE tag_name = 'Library';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000313, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000313, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000314, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000314, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000315, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000315, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000316, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000316, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000316, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000317, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000317, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000318, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000318, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000318, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000319, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000319, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000319, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000320, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000320, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000320, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000321, id FROM tags WHERE tag_name = 'Industrial Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000321, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000321, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000322, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000322, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000322, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000323, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000323, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000323, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000324, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000324, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000324, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000325, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000325, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000325, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000326, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000326, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000327, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000327, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000328, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000328, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000329, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000329, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000329, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000330, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000330, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000331, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000331, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000332, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000332, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000332, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000333, id FROM tags WHERE tag_name = 'Park';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000333, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000333, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000334, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000334, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000335, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000335, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000335, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000336, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000336, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000337, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000337, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000337, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000338, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000338, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000339, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000339, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000340, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000340, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000341, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000341, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000342, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000342, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000342, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000343, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000343, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000343, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000344, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000344, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000345, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000345, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000345, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000346, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000346, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000346, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000347, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000347, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000347, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000347, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000348, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000348, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000349, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000349, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000349, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000350, id FROM tags WHERE tag_name = 'Zoo';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000350, id FROM tags WHERE tag_name = 'Wildlife';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000350, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000351, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000351, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000351, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000352, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000352, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000352, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000352, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000353, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000353, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000354, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000354, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000355, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000355, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000355, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000356, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000356, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000356, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000357, id FROM tags WHERE tag_name = 'Garden';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000357, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000357, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000358, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000358, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000358, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000358, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000359, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000359, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000359, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000360, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000360, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000360, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000361, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000361, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000362, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000362, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000362, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000363, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000363, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000363, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000364, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000364, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000364, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000364, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000365, id FROM tags WHERE tag_name = 'Fortress';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000365, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000365, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000366, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000366, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000366, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000367, id FROM tags WHERE tag_name = 'Music';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000367, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000368, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000368, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000369, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000369, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000369, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000370, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000370, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000370, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000371, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000371, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000371, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000372, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000372, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000372, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000373, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000373, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000373, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000373, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000374, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000374, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000374, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000375, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000375, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000375, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000376, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000376, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000376, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000377, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000377, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000377, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000378, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000378, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000379, id FROM tags WHERE tag_name = 'Food';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000379, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000380, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000380, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000380, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000381, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000381, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000381, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000382, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000382, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000382, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000382, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000383, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000383, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000384, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000384, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000384, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000385, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000385, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000386, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000386, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000386, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000387, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000387, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000387, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000387, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000388, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000388, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000389, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000389, id FROM tags WHERE tag_name = 'Design';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000390, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000390, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000391, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000391, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000392, id FROM tags WHERE tag_name = 'Spa';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000392, id FROM tags WHERE tag_name = 'Wellness';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000393, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000393, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000393, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000394, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000394, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000394, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000395, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000395, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000396, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000396, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000396, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000396, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000397, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000397, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000397, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000397, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000398, id FROM tags WHERE tag_name = 'Archaeology';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000398, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000398, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000399, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000399, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000399, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000400, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000400, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000400, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000401, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000401, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000402, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000402, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000402, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000403, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000403, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000403, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000404, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000404, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000404, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000405, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000405, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000405, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000406, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000406, id FROM tags WHERE tag_name = 'Design';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000407, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000407, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000407, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000408, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000408, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000408, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000409, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000409, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000409, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000410, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000410, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000410, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000411, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000411, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000411, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000412, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000412, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000412, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000413, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000413, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000414, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000414, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000414, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000415, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000415, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000415, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000416, id FROM tags WHERE tag_name = 'Boating';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000416, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000416, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000417, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000417, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000418, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000418, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000419, id FROM tags WHERE tag_name = 'Music';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000419, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000420, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000420, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000421, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000421, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000421, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000421, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000422, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000422, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000423, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000423, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000424, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000424, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000424, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000425, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000425, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000425, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000426, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000426, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000426, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000427, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000427, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000427, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000428, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000428, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000428, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000429, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000429, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000430, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000430, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000430, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000430, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000431, id FROM tags WHERE tag_name = 'Zoo';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000431, id FROM tags WHERE tag_name = 'Wildlife';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000431, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000432, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000432, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000432, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000433, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000433, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000434, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000434, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000434, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000435, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000435, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000436, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000436, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000437, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000437, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000437, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000438, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000438, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000438, id FROM tags WHERE tag_name = 'Hiking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000438, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000439, id FROM tags WHERE tag_name = 'Historic Center';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000439, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000439, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000440, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000440, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000440, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000441, id FROM tags WHERE tag_name = 'Castle';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000441, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000441, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000442, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000442, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000442, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000443, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000443, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000443, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000444, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000444, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000444, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000445, id FROM tags WHERE tag_name = 'Art';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000445, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000446, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000446, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000447, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000447, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000447, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000448, id FROM tags WHERE tag_name = 'Lake';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000448, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000448, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000449, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000449, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000450, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000450, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000450, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000451, id FROM tags WHERE tag_name = 'Skiing';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000451, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000451, id FROM tags WHERE tag_name = 'Adventure';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000452, id FROM tags WHERE tag_name = 'River';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000452, id FROM tags WHERE tag_name = 'Nature';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000452, id FROM tags WHERE tag_name = 'Walking';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000453, id FROM tags WHERE tag_name = 'Cable Car';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000453, id FROM tags WHERE tag_name = 'Mountain';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000453, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000454, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000454, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000455, id FROM tags WHERE tag_name = 'Railway';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000455, id FROM tags WHERE tag_name = 'Transport';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000455, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000456, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000456, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000456, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000457, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000457, id FROM tags WHERE tag_name = 'Design';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000458, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000458, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000458, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000459, id FROM tags WHERE tag_name = 'UNESCO';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000459, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000459, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000460, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000460, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000460, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000461, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000461, id FROM tags WHERE tag_name = 'Cathedral';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000461, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000461, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000462, id FROM tags WHERE tag_name = 'Palace';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000462, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000462, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000463, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000463, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000464, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000464, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000465, id FROM tags WHERE tag_name = 'Music';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000465, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000466, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000466, id FROM tags WHERE tag_name = 'Attraction';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000467, id FROM tags WHERE tag_name = 'Museum';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000467, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000468, id FROM tags WHERE tag_name = 'Library';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000468, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000468, id FROM tags WHERE tag_name = 'Culture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000469, id FROM tags WHERE tag_name = 'Religious';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000469, id FROM tags WHERE tag_name = 'Church';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000469, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000470, id FROM tags WHERE tag_name = 'Market';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000470, id FROM tags WHERE tag_name = 'Food';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000470, id FROM tags WHERE tag_name = 'Shopping';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000471, id FROM tags WHERE tag_name = 'Architecture';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000471, id FROM tags WHERE tag_name = 'Design';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000472, id FROM tags WHERE tag_name = 'Viewpoint';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000472, id FROM tags WHERE tag_name = 'Photography';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000473, id FROM tags WHERE tag_name = 'Zoo';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000473, id FROM tags WHERE tag_name = 'Wildlife';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000473, id FROM tags WHERE tag_name = 'Family';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000474, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000474, id FROM tags WHERE tag_name = 'History';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000475, id FROM tags WHERE tag_name = 'Heritage';
INSERT INTO place_tags (place_id, tag_id) SELECT 40000475, id FROM tags WHERE tag_name = 'History';

CREATE TABLE IF NOT EXISTS festivals (
  id INTEGER PRIMARY KEY,
  state_id INTEGER,
  city_id INTEGER,
  place_id INTEGER,
  festival_name TEXT NOT NULL,
  timing_label TEXT,
  lunar_note TEXT,
  duration_label TEXT,
  description TEXT,
  source TEXT DEFAULT 'own',
  updated_at TEXT
);
INSERT INTO festivals (id, state_id, city_id, place_id, festival_name, timing_label, lunar_note, duration_label, description, source, updated_at) VALUES
(40900001, 4009, 400079, NULL, 'Vienna New Year’s Concert', 'January 1', 'Annual event; programme and access vary yearly', '1 day', 'Major recurring cultural, sporting or seasonal event associated with Vienna; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900002, 4009, 400079, NULL, 'Vienna Opera Ball', 'February', 'Annual date varies', '1 evening', 'Major recurring cultural, sporting or seasonal event associated with Vienna; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900003, 4009, 400079, NULL, 'Vienna Festival (Wiener Festwochen)', 'May-June', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Vienna; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900004, 4009, 400079, NULL, 'Donauinselfest', 'June', 'Annual dates vary', '3 days', 'Major recurring cultural, sporting or seasonal event associated with Vienna; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900005, 4009, 400079, NULL, 'Vienna Christmas Markets', 'November-December', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Vienna; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900006, 4005, 400040, NULL, 'Salzburg Festival', 'July-August', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Salzburg; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900007, 4005, 400040, NULL, 'Mozart Week Salzburg', 'January-February', 'Annual dates vary', 'About 1 week', 'Major recurring cultural, sporting or seasonal event associated with Salzburg; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900008, 4005, 400040, NULL, 'Rupertikirtag Salzburg', 'September', 'Annual dates vary', 'Several days', 'Major recurring cultural, sporting or seasonal event associated with Salzburg; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900009, 4008, 400072, NULL, 'Bregenz Festival', 'July-August', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Bregenz; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900010, 4006, 400050, NULL, 'Styriarte', 'June-July', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Graz; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900011, 4006, 400050, NULL, 'Aufsteirern', 'September', 'Annual dates vary', 'Weekend', 'Major recurring cultural, sporting or seasonal event associated with Graz; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900012, 4004, 400029, NULL, 'Ars Electronica Festival', 'September', 'Annual dates vary', 'Several days', 'Major recurring cultural, sporting or seasonal event associated with Linz; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900013, 4004, 400029, NULL, 'Linzer Klangwolke', 'September', 'Annual dates vary', '1-3 days', 'Major recurring cultural, sporting or seasonal event associated with Linz; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900014, 4002, 400009, NULL, 'Villacher Kirchtag', 'July-August', 'Annual dates vary', 'About 1 week', 'Major recurring cultural, sporting or seasonal event associated with Villach; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900015, 4002, 400009, NULL, 'Villach Carnival', 'February-March', 'Depends on carnival calendar', 'Several days', 'Major recurring cultural, sporting or seasonal event associated with Villach; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900016, 4004, 400031, NULL, 'Lehár Festival Bad Ischl', 'July-August', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Bad Ischl; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900017, 4004, 400031, NULL, 'Kaiser Days Bad Ischl', 'August', 'Annual dates vary', 'Several days', 'Major recurring cultural, sporting or seasonal event associated with Bad Ischl; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900018, 4007, 400061, NULL, 'Hahnenkamm Races', 'January', 'Annual dates vary', 'Several days', 'Major recurring cultural, sporting or seasonal event associated with Kitzbühel; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900019, 4006, 400051, NULL, 'Schladming Night Race', 'January', 'Annual date varies', '1-2 days', 'Major recurring cultural, sporting or seasonal event associated with Schladming; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900020, 4005, 400041, NULL, 'IRONMAN 70.3 Zell am See-Kaprun', 'August-September', 'Annual date varies', 'Weekend', 'Major recurring cultural, sporting or seasonal event associated with Zell am See; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900021, 4003, 400018, NULL, 'Wachau Marathon', 'September', 'Annual date varies', '1 day', 'Major recurring cultural, sporting or seasonal event associated with Krems an der Donau; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900022, 4001, 400005, NULL, 'Seefestspiele Mörbisch', 'July-August', 'Annual programme and dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Mörbisch am See; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900023, 4007, 400060, NULL, 'Innsbruck Festival of Early Music', 'July-August', 'Annual dates vary', 'Several weeks', 'Major recurring cultural, sporting or seasonal event associated with Innsbruck; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00'),
(40900024, 4006, 400052, NULL, 'Mariazell Advent', 'November-December', 'Annual dates vary', 'Several weekends', 'Major recurring cultural, sporting or seasonal event associated with Mariazell; exact programme and dates should be rechecked each year before publishing.', 'own', '2026-10-02 12:00:00');

-- ---- QA QUERIES (safe read-only checks after import) ----
-- SELECT id, COUNT(*) FROM cities WHERE id BETWEEN 400001 AND 400999 GROUP BY id HAVING COUNT(*) > 1;
-- SELECT id, COUNT(*) FROM places WHERE id BETWEEN 40000001 AND 40899999 GROUP BY id HAVING COUNT(*) > 1;
-- SELECT p.id FROM places p LEFT JOIN cities c ON c.id=p.city_id WHERE p.id BETWEEN 40000001 AND 40899999 AND c.id IS NULL;
-- SELECT p.id FROM places p LEFT JOIN opening_hours h ON h.place_id=p.id WHERE p.id BETWEEN 40000001 AND 40899999 AND h.place_id IS NULL;
-- SELECT p.id FROM places p LEFT JOIN photos ph ON ph.place_id=p.id WHERE p.id BETWEEN 40000001 AND 40899999 AND ph.place_id IS NULL;
-- SELECT p.id FROM places p LEFT JOIN place_tags pt ON pt.place_id=p.id WHERE p.id BETWEEN 40000001 AND 40899999 GROUP BY p.id HAVING COUNT(pt.tag_id)=0;
-- SELECT id FROM places WHERE id BETWEEN 40000001 AND 40899999 AND google_place_id IS NOT NULL;
-- SELECT id FROM places WHERE id BETWEEN 40000001 AND 40899999 AND verification_status NOT IN ('verified','partial');
