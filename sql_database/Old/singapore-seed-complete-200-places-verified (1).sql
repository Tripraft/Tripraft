-- ============================================================================
-- TripRaft Places Seed : SINGAPORE — COMPLETE CORE (1 CITY-STATE / 200 PLACES)
-- Generated: 2026-10-01
-- Reference structure: Thailand complete seed / Andhra Pradesh verified seed
-- --------------------------------------------------------------------------
-- WHAT THIS FILE DOES
--   1. Registers Singapore as a single tier-1 city in cities.
--   2. Seeds 200 core places across 10 internal visitor-area batches.
--   3. Adds matching opening_hours, photo placeholders, place_tags and 12 festival/event rows.
--   4. Keeps google_place_id NULL, matching the owner decision in earlier TripRaft seeds.
--
-- IMPORTANT — state_id MAPPING
-- The supplied TripRaft schema exposes cities.state_id but not the states/countries table schema.
-- This file RESERVES state_id 9101 for Singapore. Replace it before import if already occupied.
--
-- VERIFICATION (2026-10-01)
-- Current official/government/operator sources were used where available.
-- Dynamic/private venues are marked partial rather than treating changeable hours/prices as permanent.
--
-- PHOTOS
-- Photo rows use photo_status='no_match' pending a dedicated licensed-image pass.
-- ============================================================================

INSERT INTO cities (id, state_id, city_name, latitude, longitude, created_at, tier) VALUES
(3001, 9101, 'Singapore', 1.3521, 103.8198, '2026-10-01 17:45:00', 1);

-- ---- Shared tag vocabulary (idempotent) ----
INSERT OR IGNORE INTO tags (tag_name) VALUES
('Adventure'),
('Aquarium'),
('Architecture'),
('Art'),
('Beach'),
('Bird Watching'),
('Boardwalk'),
('Bridge'),
('Cable Car'),
('Coast'),
('Community'),
('Contemporary'),
('Cycling'),
('Design'),
('Family'),
('Farm'),
('Fine Dining'),
('Fishing'),
('Food'),
('Fort'),
('Garden'),
('Hawker Centre'),
('Heritage'),
('Hot Spring'),
('Immersive Experience'),
('Indoor Attraction'),
('Interactive'),
('Island'),
('Lake'),
('Landmark'),
('Local Culture'),
('Malay Culture'),
('Mangrove'),
('Marine Life'),
('Market'),
('Mosque'),
('Museum'),
('Natural History'),
('Nature'),
('Nature Reserve'),
('Nightlife'),
('Observation Deck'),
('Park'),
('Peranakan'),
('Performing Arts'),
('Photography'),
('Playground'),
('Quarry'),
('Railway'),
('Religious'),
('Ride'),
('River'),
('Riverfront'),
('Science'),
('Shopping'),
('Show'),
('Street Art'),
('Street Food'),
('Temple'),
('Theme Park'),
('Trek'),
('UNESCO'),
('Urban Planning'),
('Vegetarian'),
('Viewpoint'),
('War History'),
('Water Park'),
('Waterfall'),
('Waterfront'),
('Wetland'),
('Wildlife'),
('Workshop'),
('Zoo');

-- ============================================================================
-- BATCH 1 — MARINA BAY & CIVIC DISTRICT — places 300001-300020
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300001', '3001', 'Merlion Park', 'Merlion Park', 'Waterfront landmark at Marina Bay featuring Singapore’s iconic Merlion statue and skyline views.', '30-60 minutes', 'Early Morning', 'Visit early or after dark for cooler temperatures and skyline photography.', '', 'Singapore', 0, 0, '', '', 'Free', 5.0, 4.6, 1.2868, 103.8545, '1 Fullerton Road, Singapore 049213', NULL, 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public waterfront landmark; open access around the clock.', '2026-10-01'),
('300002', '3001', 'Gardens by the Bay Outdoor Gardens', 'Gardens by the Bay Outdoor Gardens', 'Free outdoor gardens around Marina Bay including Supertree Grove, Heritage Gardens, lakes and landscaped spaces.', '2-4 hours', 'Late Afternoon', 'Stay through evening for Garden Rhapsody and cooler temperatures.', '', 'Singapore', 0, 0, '', '', 'Free', 5.0, 4.9, 1.2816, 103.8636, '18 Marina Gardens Drive, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official Gardens by the Bay site lists Outdoor Gardens daily 5:00 AM-2:00 AM.', '2026-10-01'),
('300003', '3001', 'Flower Dome', 'Flower Dome', 'Climate-controlled conservatory showcasing plants and floral displays from Mediterranean and semi-arid regions.', '1-2 hours', 'Afternoon', 'Check monthly maintenance closure dates before booking.', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction; rates vary by resident/tourist bundle', 4.9, 4.8, 1.2843, 103.8641, '18 Marina Gardens Drive, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 9:00 AM-9:00 PM; last entry 8:30 PM; monthly maintenance closures apply.', '2026-10-01'),
('300004', '3001', 'Cloud Forest', 'Cloud Forest', 'Mist-filled conservatory with a tall indoor waterfall, mountain vegetation and elevated walkways.', '1.5-2 hours', 'Afternoon', 'Bring a light layer because the conservatory is cool.', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction; rates vary by package', 5.0, 4.9, 1.2847, 103.8643, '18 Marina Gardens Drive, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 9:00 AM-9:00 PM; last admission 8:00 PM.', '2026-10-01'),
('300005', '3001', 'OCBC Skyway', 'OCBC Skyway', 'Elevated walkway between Supertrees offering views across Gardens by the Bay and Marina Bay.', '30-45 minutes', 'Sunset', 'Time entry before sunset for day-to-night views.', '', 'Singapore', 0, 1, '', '', 'Ticketed attraction', 4.8, 4.7, 1.2819, 103.8636, 'Supertree Grove, Gardens by the Bay, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 9:00 AM-9:00 PM; last admission 8:30 PM.', '2026-10-01'),
('300006', '3001', 'Supertree Observatory', 'Supertree Observatory', 'Observation deck at the tallest Supertree with elevated views over the gardens and city skyline.', '45-60 minutes', 'Sunset', 'Check weather before going up because views are best in clear conditions.', '', 'Singapore', 0, 1, '', '', 'Ticketed attraction', 4.8, 4.7, 1.2815, 103.8637, 'Supertree Grove, Gardens by the Bay, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 9:00 AM-9:00 PM; last admission 8:30 PM.', '2026-10-01'),
('300007', '3001', 'Floral Fantasy', 'Floral Fantasy', 'Indoor floral attraction combining themed gardens, suspended arrangements and multimedia elements.', '1-2 hours', 'Afternoon', 'Pair with the conservatories if you want a full Gardens by the Bay day.', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.5, 4.5, 1.2821, 103.865, 'Bayfront Plaza, Gardens by the Bay, Singapore 018953', 'https://www.gardensbythebay.com.sg/en/plan-your-visit/opening-hours.html', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 10:00 AM-9:00 PM; last admission 8:30 PM.', '2026-10-01'),
('300008', '3001', 'ArtScience Museum', 'ArtScience Museum', 'Lotus-shaped museum at Marina Bay Sands presenting exhibitions blending art, science, technology and culture.', '2-3 hours', 'Afternoon', 'Exhibitions are separately ticketed; check what is running before purchase.', '', 'Singapore', 0, 0, '', '', 'Exhibition pricing varies', 4.9, 4.8, 1.2863, 103.8593, '6 Bayfront Avenue, Singapore 018974', 'https://www.marinabaysands.com/museum.html', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official current schedule: Sun-Thu 10 AM-7 PM, Fri-Sat 10 AM-9 PM.', '2026-10-01'),
('300009', '3001', 'Marina Bay Sands SkyPark Observation Deck', 'Marina Bay Sands SkyPark Observation Deck', 'High observation deck atop Marina Bay Sands with panoramic views over Marina Bay and central Singapore.', '1-2 hours', 'Sunset', 'Book a timed slot for sunset or nighttime skyline views.', 'Advance booking recommended', 'Singapore', 0, 1, '', '', 'Ticketed attraction; dynamic pricing may apply', 5.0, 4.8, 1.2834, 103.8607, '10 Bayfront Avenue, Singapore 018956', 'https://www.marinabaysands.com/attractions/sands-skypark.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Opening hours and ticket prices are date-dependent and should be refreshed.', '2026-10-01'),
('300010', '3001', 'Spectra – A Light & Water Show', 'Spectra – A Light & Water Show', 'Free nightly multimedia show on the Marina Bay Sands waterfront combining fountains, projections, light and music.', '15-30 minutes', 'Evening', 'Arrive early for an unobstructed waterfront viewing spot.', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.7, 1.284, 103.8605, 'Event Plaza, Marina Bay Sands, Singapore 018972', 'https://www.marinabaysands.com/attractions/spectra.html', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Show times can change for events and maintenance; refresh nightly schedule.', '2026-10-01'),
('300011', '3001', 'Helix Bridge', 'Helix Bridge', 'Pedestrian bridge linking Marina Centre and Marina Bay Sands, designed with a double-helix structural motif.', '20-40 minutes', 'Evening', 'Walk it after dark when the bridge and skyline are illuminated.', '', 'Singapore', 0, 0, '', '', 'Free', 4.7, 4.6, 1.2876, 103.86, 'Bayfront Avenue, Singapore', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public pedestrian bridge with continuous access.', '2026-10-01'),
('300012', '3001', 'Marina Barrage', 'Marina Barrage', 'Dam and public rooftop lawn overlooking the city, popular for picnics, kites and skyline views.', '1-2 hours', 'Late Afternoon', 'Bring water and sun protection; the rooftop lawn is exposed.', '', 'Singapore', 0, 0, '', '', 'Free', 4.7, 4.7, 1.2802, 103.8708, '8 Marina Gardens Drive, Singapore 018951', 'https://www.pub.gov.sg/marinabarrage', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Public facility and rooftop area; gallery/facility hours differ from outdoor access.', '2026-10-01'),
('300013', '3001', 'National Gallery Singapore', 'National Gallery Singapore', 'Major art museum occupying the former Supreme Court and City Hall, focused on Singapore and Southeast Asian art.', '2-4 hours', 'Morning', 'Allow extra time for the historic architecture as well as exhibitions.', '', 'Singapore', 0, 0, '', '', 'General Admission: S$20 tourist/foreign resident; free for Singapore Citizens/PRs', 5.0, 4.9, 1.2903, 103.8519, '1 St Andrew''s Road, Singapore 178957', 'https://www.nationalgallery.sg/', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official opening daily 10:00 AM-7:00 PM; admission and ticket sales end 30 minutes before closing.', '2026-10-01'),
('300014', '3001', 'National Museum of Singapore', 'National Museum of Singapore', 'Singapore’s oldest museum, presenting national history and culture through permanent and changing exhibitions.', '2-3 hours', 'Morning', 'Check which galleries are open because restoration and gallery refreshes can affect exhibits.', '', 'Singapore', 0, 0, '', '', 'Permanent galleries free for Singapore Citizens/PRs; tourist rates vary by exhibition', 4.9, 4.8, 1.2966, 103.8485, '93 Stamford Road, Singapore 178897', 'https://www.nhb.gov.sg/nationalmuseum', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official site lists daily 10:00 AM-7:00 PM. Singapore History Gallery reopens in October 2026 after revamp.', '2026-10-01'),
('300015', '3001', 'Asian Civilisations Museum', 'Asian Civilisations Museum', 'Museum in the historic Empress Place Building exploring Asian cultures, trade and artistic connections.', '2-3 hours', 'Afternoon', 'Pair with the Singapore River, Victoria Theatre and National Gallery.', '', 'Singapore', 0, 0, '', '', 'Ticketed for tourists; Singapore Citizen/PR concessions apply', 4.8, 4.8, 1.2875, 103.851, '1 Empress Place, Singapore 179555', 'https://www.nhb.gov.sg/acm', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 10:00 AM-7:00 PM, Friday 10:00 AM-9:00 PM.', '2026-10-01'),
('300016', '3001', 'Peranakan Museum', 'Peranakan Museum', 'Museum exploring Peranakan cultures through material culture, fashion, religion, food and family histories.', '1.5-2.5 hours', 'Afternoon', 'A strong companion to Katong/Joo Chiat if you want deeper Peranakan context.', '', 'Singapore', 0, 0, '', '', 'Permanent galleries free for Singapore Citizens/PRs; tourist admission applies', 4.8, 4.8, 1.2942, 103.849, '39 Armenian Street, Singapore 179941', 'https://www.nhb.gov.sg/peranakanmuseum', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official hours daily 10:00 AM-7:00 PM, Friday until 9:00 PM.', '2026-10-01'),
('300017', '3001', 'Victoria Theatre and Victoria Concert Hall', 'Victoria Theatre and Victoria Concert Hall', 'Historic performing-arts complex facing the Singapore River and Empress Place.', '30-60 minutes', 'Late Afternoon', 'Public interiors are best experienced when attending a performance or tour.', '', 'Singapore', 0, 0, '', '', 'Exterior/public-area viewing free; events ticketed', 4.4, 4.4, 1.2887, 103.8513, '9 Empress Place, Singapore 179556', 'https://www.vtvch.com/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Event venue; public-access hours depend on performances and programmes.', '2026-10-01'),
('300018', '3001', 'Esplanade – Theatres on the Bay', 'Esplanade – Theatres on the Bay', 'Singapore’s major performing-arts centre with theatres, waterfront spaces, free performances and distinctive durian-like architecture.', '1-2 hours', 'Evening', 'Check the free concourse and outdoor theatre programme before visiting.', '', 'Singapore', 0, 0, '', '', 'Public areas/free events available; ticketed shows vary', 4.7, 4.7, 1.2897, 103.8552, '1 Esplanade Drive, Singapore 038981', 'https://www.esplanade.com/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Major public arts venue; individual performance venues follow event schedules.', '2026-10-01'),
('300019', '3001', 'Fort Canning Park', 'Fort Canning Park', 'Historic hill park with archaeological sites, colonial-era landmarks, gardens and walking routes.', '1.5-3 hours', 'Morning', 'Combine the Spice Garden, Fort Gate and Sang Nila Utama Garden on one loop.', '', 'Singapore', 0, 0, '', '', 'Free', 4.7, 4.7, 1.2953, 103.8474, 'River Valley Road, Singapore 179037', 'https://www.nparks.gov.sg/visit/parks/fort-canning-park', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks lists Fort Canning Park as open 24 hours.', '2026-10-01'),
('300020', '3001', 'Old Hill Street Police Station', 'Old Hill Street Police Station', 'Colourful colonial-era former police station and national monument known for its many rainbow-painted windows.', '20-40 minutes', 'Late Afternoon', 'Best viewed from across Hill Street; interior access is limited because it is an office building.', '', 'Singapore', 0, 0, '', '', 'Exterior viewing free', 4.5, 4.4, 1.2904, 103.8482, '140 Hill Street, Singapore 179369', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'National-monument office building; exterior viewable from public streets.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300001', '300001', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300002', '300002', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', '5:00 AM - 2:00 AM', ''),
('300003', '300003', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', ''),
('300004', '300004', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', ''),
('300005', '300005', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', ''),
('300006', '300006', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', '9:00 AM - 9:00 PM', ''),
('300007', '300007', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', ''),
('300008', '300008', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 7:00 PM', ''),
('300009', '300009', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', ''),
('300010', '300010', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', ''),
('300011', '300011', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300012', '300012', 'Daylight / facility-dependent', 'Daylight / facility-dependent', 'Daylight / facility-dependent', 'Daylight / facility-dependent', 'Daylight / facility-dependent', 'Daylight / facility-dependent', 'Daylight / facility-dependent', ''),
('300013', '300013', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', ''),
('300014', '300014', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', ''),
('300015', '300015', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', ''),
('300016', '300016', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', ''),
('300017', '300017', 'Event-dependent', 'Event-dependent', 'Event-dependent', 'Event-dependent', 'Event-dependent', 'Event-dependent', 'Event-dependent', ''),
('300018', '300018', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300019', '300019', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300020', '300020', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300001', '300001', 'Merlion Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300002', '300002', 'Gardens by the Bay Outdoor Gardens', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300003', '300003', 'Flower Dome', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300004', '300004', 'Cloud Forest', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300005', '300005', 'OCBC Skyway', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300006', '300006', 'Supertree Observatory', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300007', '300007', 'Floral Fantasy', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300008', '300008', 'ArtScience Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300009', '300009', 'Marina Bay Sands SkyPark Observation Deck', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300010', '300010', 'Spectra – A Light & Water Show', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300011', '300011', 'Helix Bridge', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300012', '300012', 'Marina Barrage', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300013', '300013', 'National Gallery Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300014', '300014', 'National Museum of Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300015', '300015', 'Asian Civilisations Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300016', '300016', 'Peranakan Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300017', '300017', 'Victoria Theatre and Victoria Concert Hall', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300018', '300018', 'Esplanade – Theatres on the Bay', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300019', '300019', 'Fort Canning Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300020', '300020', 'Old Hill Street Police Station', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300001, id FROM tags WHERE tag_name IN ('Landmark', 'Waterfront', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300002, id FROM tags WHERE tag_name IN ('Garden', 'Park', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300003, id FROM tags WHERE tag_name IN ('Garden', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300004, id FROM tags WHERE tag_name IN ('Garden', 'Waterfall', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300005, id FROM tags WHERE tag_name IN ('Observation Deck', 'Viewpoint', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300006, id FROM tags WHERE tag_name IN ('Observation Deck', 'Viewpoint', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300007, id FROM tags WHERE tag_name IN ('Garden', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300008, id FROM tags WHERE tag_name IN ('Museum', 'Art', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300009, id FROM tags WHERE tag_name IN ('Observation Deck', 'Viewpoint', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300010, id FROM tags WHERE tag_name IN ('Show', 'Waterfront', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300011, id FROM tags WHERE tag_name IN ('Architecture', 'Waterfront', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300012, id FROM tags WHERE tag_name IN ('Park', 'Viewpoint', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300013, id FROM tags WHERE tag_name IN ('Museum', 'Art', 'Heritage', 'Architecture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300014, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300015, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Art');
INSERT INTO place_tags (place_id, tag_id) SELECT 300016, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300017, id FROM tags WHERE tag_name IN ('Architecture', 'Heritage', 'Performing Arts');
INSERT INTO place_tags (place_id, tag_id) SELECT 300018, id FROM tags WHERE tag_name IN ('Performing Arts', 'Architecture', 'Waterfront', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300019, id FROM tags WHERE tag_name IN ('Park', 'Heritage', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300020, id FROM tags WHERE tag_name IN ('Architecture', 'Heritage', 'Photography');

-- ============================================================================
-- BATCH 2 — SINGAPORE RIVER, CHINATOWN & CBD — places 300021-300040
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300021', '3001', 'Clarke Quay', 'Clarke Quay', 'Restored riverside warehouse district with restaurants, bars and nightlife along the Singapore River.', '1-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public district; dining extra', 4.5, 4.4, 1.2906, 103.8465, '3 River Valley Road, Singapore 179024', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public riverfront precinct; individual venues keep separate hours.', '2026-10-01'),
('300022', '3001', 'Boat Quay', 'Boat Quay', 'Historic riverfront row of shophouses opposite the Civic District, now packed with restaurants and bars.', '1-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public district; dining extra', 4.5, 4.4, 1.2878, 103.8497, 'Boat Quay, Singapore 049800', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public riverfront precinct; individual venues keep separate hours.', '2026-10-01'),
('300023', '3001', 'Robertson Quay', 'Robertson Quay', 'Quieter upriver dining and residential district with promenades and outdoor restaurants.', '1-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public district; dining extra', 4.5, 4.4, 1.29, 103.837, 'Robertson Quay, Singapore 238251', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public riverfront precinct; individual venues keep separate hours.', '2026-10-01'),
('300024', '3001', 'Chinatown Street Market', 'Chinatown Street Market', 'Pedestrian shopping streets around Pagoda, Trengganu and Sago Streets selling souvenirs, snacks and seasonal goods.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; purchases extra', 4.7, 4.4, 1.2839, 103.8435, 'Pagoda Street, Singapore 059190', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Market-stall opening times vary by vendor and festival period.', '2026-10-01'),
('300025', '3001', 'Buddha Tooth Relic Temple & Museum', 'Buddha Tooth Relic Temple & Museum', 'Tang-style Buddhist temple and museum in Chinatown housing sacred objects, religious art and a rooftop garden.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.9, 4.7, 1.2815, 103.8442, '288 South Bridge Road, Singapore 058840', 'https://www.btrts.org.sg/', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active temple and museum; current detailed floor hours should be refreshed.', '2026-10-01'),
('300026', '3001', 'Sri Mariamman Temple', 'Sri Mariamman Temple', 'Singapore’s oldest Hindu temple, known for its ornate gopuram and central role in Chinatown’s religious landscape.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.7, 4.6, 1.2826, 103.845, '244 South Bridge Road, Singapore 058793', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Active national-monument temple; worship hours can include midday closures.', '2026-10-01'),
('300027', '3001', 'Thian Hock Keng Temple', 'Thian Hock Keng Temple', 'Historic Hokkien temple dedicated to Mazu, built when the waterfront lay much closer to Telok Ayer Street.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.7, 4.7, 1.2809, 103.8474, '158 Telok Ayer Street, Singapore 068613', 'https://thianhockkeng.com.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active historic temple; current visitor schedule should be refreshed.', '2026-10-01'),
('300028', '3001', 'Chinatown Heritage Centre', 'Chinatown Heritage Centre', 'Interpretive attraction in restored Chinatown shophouses focusing on early migrant living and working conditions.', '1-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed when open', 4.4, 4.4, 1.2837, 103.843, '48 Pagoda Street, Singapore 059207', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Operating status and hours should be refreshed before production publication.', '2026-10-01'),
('300029', '3001', 'Singapore City Gallery', 'Singapore City Gallery', 'URA gallery explaining Singapore’s planning, architecture and urban transformation through maps and models.', '1-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.2797, 103.8451, '45 Maxwell Road, The URA Centre, Singapore 069118', 'https://www.ura.gov.sg/Corporate/Singapore-City-Gallery', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Government planning gallery; current visitor schedule should be refreshed.', '2026-10-01'),
('300030', '3001', 'Maxwell Food Centre', 'Maxwell Food Centre', 'Major Singapore hawker centre known for a wide range of local food stalls.', '1-1.5 hours', 'Lunch', 'Individual stall hours vary; arrive before peak meal time.', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.9, 4.6, 1.2804, 103.8447, '1 Kadayanallur Street, Singapore 069184', NULL, 0.94, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Multi-cuisine', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Public hawker centre; individual stall hours and cleaning days vary.', '2026-10-01'),
('300031', '3001', 'Lau Pa Sat', 'Lau Pa Sat', 'Major Singapore hawker centre known for a wide range of local food stalls.', '1-1.5 hours', 'Lunch', 'Individual stall hours vary; arrive before peak meal time.', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.8, 4.6, 1.2806, 103.8505, '18 Raffles Quay, Singapore 048582', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Multi-cuisine', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Public hawker centre; individual stall hours and cleaning days vary.', '2026-10-01'),
('300032', '3001', 'Hong Lim Market & Food Centre', 'Hong Lim Market & Food Centre', 'Major Singapore hawker centre known for a wide range of local food stalls.', '1-1.5 hours', 'Lunch', 'Individual stall hours vary; arrive before peak meal time.', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.6, 4.6, 1.2854, 103.8451, '531A Upper Cross Street, Singapore 051531', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Public hawker centre; individual stall hours and cleaning days vary.', '2026-10-01'),
('300033', '3001', 'Chinatown Complex Food Centre', 'Chinatown Complex Food Centre', 'Major Singapore hawker centre known for a wide range of local food stalls.', '1-1.5 hours', 'Lunch', 'Individual stall hours vary; arrive before peak meal time.', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.8, 4.6, 1.2823, 103.8432, '335 Smith Street, Singapore 050335', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Chinese', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Public hawker centre; individual stall hours and cleaning days vary.', '2026-10-01'),
('300034', '3001', 'Amoy Street Food Centre', 'Amoy Street Food Centre', 'Major Singapore hawker centre known for a wide range of local food stalls.', '1-1.5 hours', 'Lunch', 'Individual stall hours vary; arrive before peak meal time.', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.6, 4.6, 1.2792, 103.8466, '7 Maxwell Road, Singapore 069111', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Multi-cuisine', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Public hawker centre; individual stall hours and cleaning days vary.', '2026-10-01'),
('300035', '3001', 'Ann Siang Hill & Club Street', 'Ann Siang Hill & Club Street', 'Historic shophouse streets climbing from Chinatown toward Telok Ayer, now filled with restaurants and boutiques.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public streets; dining extra', 4.4, 4.5, 1.2814, 103.8462, 'Ann Siang Road and Club Street, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public heritage streets.', '2026-10-01'),
('300036', '3001', 'Telok Ayer Street', 'Telok Ayer Street', 'Historic street linking Chinese temples, mosques, old clan buildings and modern CBD architecture.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public street', 4.4, 4.5, 1.281, 103.8479, 'Telok Ayer Street, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public street with independent venue hours.', '2026-10-01'),
('300037', '3001', 'Fuk Tak Chi Museum', 'Fuk Tak Chi Museum', 'Small former Chinese temple turned museum documenting early Chinese migrant and Telok Ayer history.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.2813, 103.8493, '76 Telok Ayer Street, Singapore 048464', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Small museum; current opening schedule should be refreshed.', '2026-10-01'),
('300038', '3001', 'Singapore Chinese Cultural Centre', 'Singapore Chinese Cultural Centre', 'Cultural centre with exhibitions and programmes exploring Singapore Chinese identity and heritage.', '1-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Many exhibitions free; programmes vary', 4.3, 4.4, 1.2757, 103.8487, '1 Straits Boulevard, Singapore 018906', 'https://singaporeccc.org.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Exhibition and programme hours can differ by day.', '2026-10-01'),
('300039', '3001', 'Song Fa Bak Kut Teh – New Bridge Road', 'Song Fa Bak Kut Teh – New Bridge Road', 'Long-running restaurant famous for peppery Teochew-style pork-rib soup, rice and side dishes.', '1 hour', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Mid-range casual dining', 4.7, 4.6, 1.2889, 103.8474, '11 New Bridge Road, Singapore 059383', 'https://songfa.com.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Teochew / Bak Kut Teh', 'mid', 'limited', 'own', '2026-10-01 17:45:00', 'partial', 'Official brand exists; outlet hours should be refreshed before production.', '2026-10-01'),
('300040', '3001', 'JUMBO Seafood – Riverside Point', 'JUMBO Seafood – Riverside Point', 'Singapore seafood restaurant known for chilli crab, black pepper crab and riverfront dining.', '1.5-2 hours', 'Dinner', '', 'Reservation recommended', 'Singapore', 0, 0, '', '', 'Premium seafood dining', 4.7, 4.6, 1.2901, 103.8447, '30 Merchant Road, #01-01/02 Riverside Point, Singapore 058282', 'https://www.jumboseafood.com.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Seafood', 'premium', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Major official brand; outlet hours/reservation slots are dynamic.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300021', '300021', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300022', '300022', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300023', '300023', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300024', '300024', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300025', '300025', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', '7:00 AM - 5:00 PM', ''),
('300026', '300026', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', ''),
('300027', '300027', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', '7:30 AM - 5:30 PM', ''),
('300028', '300028', 'Status-dependent', 'Status-dependent', 'Status-dependent', 'Status-dependent', 'Status-dependent', 'Status-dependent', 'Status-dependent', ''),
('300029', '300029', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', 'Closed', ''),
('300030', '300030', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300031', '300031', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300032', '300032', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300033', '300033', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300034', '300034', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300035', '300035', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300036', '300036', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300037', '300037', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300038', '300038', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', ''),
('300039', '300039', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', '11:00 AM - 9:00 PM', ''),
('300040', '300040', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300021', '300021', 'Clarke Quay', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300022', '300022', 'Boat Quay', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300023', '300023', 'Robertson Quay', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300024', '300024', 'Chinatown Street Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300025', '300025', 'Buddha Tooth Relic Temple & Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300026', '300026', 'Sri Mariamman Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300027', '300027', 'Thian Hock Keng Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300028', '300028', 'Chinatown Heritage Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300029', '300029', 'Singapore City Gallery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300030', '300030', 'Maxwell Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300031', '300031', 'Lau Pa Sat', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300032', '300032', 'Hong Lim Market & Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300033', '300033', 'Chinatown Complex Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300034', '300034', 'Amoy Street Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300035', '300035', 'Ann Siang Hill & Club Street', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300036', '300036', 'Telok Ayer Street', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300037', '300037', 'Fuk Tak Chi Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300038', '300038', 'Singapore Chinese Cultural Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300039', '300039', 'Song Fa Bak Kut Teh – New Bridge Road', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300040', '300040', 'JUMBO Seafood – Riverside Point', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300021, id FROM tags WHERE tag_name IN ('Riverfront', 'Food', 'Nightlife', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300022, id FROM tags WHERE tag_name IN ('Riverfront', 'Heritage', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300023, id FROM tags WHERE tag_name IN ('Riverfront', 'Food', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300024, id FROM tags WHERE tag_name IN ('Market', 'Shopping', 'Street Food', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300025, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Museum', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300026, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300027, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300028, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300029, id FROM tags WHERE tag_name IN ('Museum', 'Architecture', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300030, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300031, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300032, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300033, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300034, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300035, id FROM tags WHERE tag_name IN ('Heritage', 'Food', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300036, id FROM tags WHERE tag_name IN ('Heritage', 'Local Culture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300037, id FROM tags WHERE tag_name IN ('Museum', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300038, id FROM tags WHERE tag_name IN ('Museum', 'Local Culture', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300039, id FROM tags WHERE tag_name IN ('Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300040, id FROM tags WHERE tag_name IN ('Food', 'Riverfront');

-- ============================================================================
-- BATCH 3 — LITTLE INDIA, KAMPONG GELAM & BUGIS — places 300041-300060
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300041', '3001', 'Sri Veeramakaliamman Temple', 'Sri Veeramakaliamman Temple', 'Historic Hindu temple dedicated to Kali in the heart of Little India.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.7, 4.6, 1.3067, 103.8495, '141 Serangoon Road, Singapore 218042', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Active temple; worship schedule includes daily morning and evening periods.', '2026-10-01'),
('300042', '3001', 'Indian Heritage Centre', 'Indian Heritage Centre', 'NHB museum documenting the histories and cultures of Indian and South Asian communities in Singapore and Southeast Asia.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Tourist admission applies; local concessions may apply', 4.7, 4.7, 1.3056, 103.8517, '5 Campbell Lane, Singapore 209924', 'https://www.indianheritage.gov.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NHB current hours: Tue-Thu 10 AM-7 PM; Fri-Sat 10 AM-8 PM; Sun/PH 10 AM-4 PM; closed Monday.', '2026-10-01'),
('300043', '3001', 'Tekka Centre', 'Tekka Centre', 'Little India wet market, hawker centre and retail complex known for Indian, Malay and Chinese food plus fresh produce.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals; market purchases extra', 4.8, 4.7, 1.306, 103.8501, '665 Buffalo Road, Singapore 210665', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Indian / Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'verified', 'Public market and hawker centre; individual stall hours vary.', '2026-10-01'),
('300044', '3001', 'Little India Arcade', 'Little India Arcade', 'Cluster of conserved shophouses selling Indian sweets, textiles, gifts, henna and traditional goods.', '45-90 minutes', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; purchases extra', 4.3, 4.3, 1.3061, 103.8518, '48 Serangoon Road, Singapore 217959', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Individual shop hours differ.', '2026-10-01'),
('300045', '3001', 'House of Tan Teng Niah', 'House of Tan Teng Niah', 'Colourfully painted surviving Chinese villa in Little India and a popular heritage photo stop.', '15-30 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free exterior viewing', 4.4, 4.3, 1.307, 103.852, '37 Kerbau Road, Singapore 219168', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Exterior heritage landmark viewable from public street.', '2026-10-01'),
('300046', '3001', 'Mustafa Centre', 'Mustafa Centre', 'Large department-store complex in Little India known for wide product variety and late-night shopping.', '1-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free entry; shopping extra', 4.3, 4.2, 1.3099, 103.8554, '145 Syed Alwi Road, Singapore 207704', 'https://www.mustafa.com.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Operating hours have changed historically; refresh current store hours.', '2026-10-01'),
('300047', '3001', 'Masjid Abdul Gafoor', 'Masjid Abdul Gafoor', 'Historic mosque in Little India with ornate architecture blending Islamic and South Asian decorative influences.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.4, 1.3067, 103.8551, '41 Dunlop Street, Singapore 209369', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active mosque; visitor access depends on prayer schedule.', '2026-10-01'),
('300048', '3001', 'Sri Srinivasa Perumal Temple', 'Sri Srinivasa Perumal Temple', 'Historic Vaishnavite Hindu temple with a tall gopuram on Serangoon Road.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.5, 4.5, 1.3126, 103.8544, '397 Serangoon Road, Singapore 218123', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Active national-monument temple; worship hours vary by day.', '2026-10-01'),
('300049', '3001', 'Sakya Muni Buddha Gaya Temple', 'Sakya Muni Buddha Gaya Temple', 'Buddhist temple known for a large seated Buddha and Thai-influenced architecture near Little India.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.3, 4.4, 1.314, 103.8575, '366 Race Course Road, Singapore 218638', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active temple; current visitor hours should be refreshed.', '2026-10-01'),
('300050', '3001', 'Leong San See Temple', 'Leong San See Temple', 'Chinese Buddhist temple opposite Sakya Muni Buddha Gaya, known for traditional southern Chinese architecture.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.2, 4.4, 1.3138, 103.8571, '371 Race Course Road, Singapore 218641', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active temple; current hours should be refreshed.', '2026-10-01'),
('300051', '3001', 'Sultan Mosque', 'Sultan Mosque', 'Landmark mosque with a large golden dome anchoring the Kampong Gelam historic district.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.9, 4.8, 1.3023, 103.859, '3 Muscat Street, Singapore 198833', 'https://sultanmosque.sg/', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active mosque; public visitor hours vary around prayer periods and Fridays.', '2026-10-01'),
('300052', '3001', 'Malay Heritage Centre', 'Malay Heritage Centre', 'Revamped national heritage institution in the former Istana Kampong Gelam exploring Malay identities, history and culture.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Admission policy varies by residency/exhibition', 4.8, 4.8, 1.3038, 103.8599, '85 Sultan Gate, Singapore 198501', 'https://www.malayheritage.gov.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NHB announced reopening on 25 Apr 2026 after revamp. Visitor materials list Tue-Sun 10 AM-6 PM, closed Monday.', '2026-10-01'),
('300053', '3001', 'Haji Lane', 'Haji Lane', 'Narrow Kampong Gelam street filled with murals, independent boutiques, cafés and bars.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public street; shopping extra', 4.7, 4.5, 1.3008, 103.8597, 'Haji Lane, Singapore 189214', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public street; individual businesses keep their own hours.', '2026-10-01'),
('300054', '3001', 'Arab Street', 'Arab Street', 'Historic Kampong Gelam street known for textile shops, rugs, perfumes and views toward Sultan Mosque.', '1 hour', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public street; shopping extra', 4.5, 4.5, 1.302, 103.8593, 'Arab Street, Singapore', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public street; shop hours vary.', '2026-10-01'),
('300055', '3001', 'Bugis Street Market', 'Bugis Street Market', 'Dense shopping market near Bugis MRT selling budget fashion, snacks, accessories and souvenirs.', '1-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; purchases extra', 4.5, 4.2, 1.3008, 103.8547, '3 New Bugis Street, Singapore 188867', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Retail hours vary by stall; market is busiest afternoon/evening.', '2026-10-01'),
('300056', '3001', 'Kwan Im Thong Hood Cho Temple', 'Kwan Im Thong Hood Cho Temple', 'Busy Buddhist temple on Waterloo Street dedicated to Guanyin and visited by worshippers seeking blessings.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.5, 4.5, 1.3, 103.8524, '178 Waterloo Street, Singapore 187964', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active temple; exact opening hours should be refreshed.', '2026-10-01'),
('300057', '3001', 'Sri Krishnan Temple', 'Sri Krishnan Temple', 'Colourful Hindu temple on Waterloo Street dedicated to Krishna, illustrating the district’s multi-religious character.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free / donations optional', 4.3, 4.4, 1.2998, 103.8525, '152 Waterloo Street, Singapore 187961', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Active temple; visitor hours vary around worship.', '2026-10-01'),
('300058', '3001', 'Singapore Zam Zam', 'Singapore Zam Zam', 'Historic Muslim restaurant opposite Sultan Mosque, famous for murtabak and biryani.', '45-75 minutes', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget to mid-range', 4.8, 4.6, 1.3019, 103.8587, '697-699 North Bridge Road, Singapore 198675', 'https://zamzamsingapore.com/', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Indian Muslim / Murtabak', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Long-running restaurant; current service hours should be refreshed.', '2026-10-01'),
('300059', '3001', 'Komala Vilas', 'Komala Vilas', 'Long-running South Indian vegetarian restaurant in Little India known for dosa, thali and banana-leaf meals.', '45-75 minutes', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget', 4.7, 4.6, 1.3057, 103.8516, '76-78 Serangoon Road, Singapore 217981', 'https://komalavilas.com.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'South Indian Vegetarian', 'budget', 'veg', 'own', '2026-10-01 17:45:00', 'partial', 'Historic vegetarian restaurant; outlet hours should be refreshed.', '2026-10-01'),
('300060', '3001', 'Muthu''s Curry', 'Muthu''s Curry', 'Popular Indian restaurant known for fish-head curry and South Indian dishes.', '1-1.5 hours', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Mid-range', 4.6, 4.5, 1.307, 103.8519, '138 Race Course Road, Singapore 218591', 'https://www.muthuscurry.com/', 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'South Indian / Fish Head Curry', 'mid', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Official restaurant brand; current branch hours should be refreshed.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300041', '300041', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', ''),
('300042', '300042', 'Closed', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 4:00 PM', ''),
('300043', '300043', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', ''),
('300044', '300044', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300045', '300045', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300046', '300046', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', '9:30 AM - 2:00 AM', ''),
('300047', '300047', 'Prayer / visitor dependent', 'Prayer / visitor dependent', 'Prayer / visitor dependent', 'Prayer / visitor dependent', 'Prayer / visitor dependent', 'Prayer / visitor dependent', 'Prayer / visitor dependent', ''),
('300048', '300048', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', ''),
('300049', '300049', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', '8:00 AM - 4:30 PM', ''),
('300050', '300050', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', '7:30 AM - 5:00 PM', ''),
('300051', '300051', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', 'Visitor hours / prayer-dependent', ''),
('300052', '300052', 'Closed', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', ''),
('300053', '300053', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300054', '300054', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300055', '300055', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', ''),
('300056', '300056', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', '6:00 AM - 6:00 PM', ''),
('300057', '300057', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', 'Morning / evening worship hours', ''),
('300058', '300058', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', '7:00 AM - 11:00 PM', ''),
('300059', '300059', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', '7:00 AM - 10:30 PM', ''),
('300060', '300060', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300041', '300041', 'Sri Veeramakaliamman Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300042', '300042', 'Indian Heritage Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300043', '300043', 'Tekka Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300044', '300044', 'Little India Arcade', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300045', '300045', 'House of Tan Teng Niah', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300046', '300046', 'Mustafa Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300047', '300047', 'Masjid Abdul Gafoor', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300048', '300048', 'Sri Srinivasa Perumal Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300049', '300049', 'Sakya Muni Buddha Gaya Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300050', '300050', 'Leong San See Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300051', '300051', 'Sultan Mosque', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300052', '300052', 'Malay Heritage Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300053', '300053', 'Haji Lane', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300054', '300054', 'Arab Street', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300055', '300055', 'Bugis Street Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300056', '300056', 'Kwan Im Thong Hood Cho Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300057', '300057', 'Sri Krishnan Temple', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300058', '300058', 'Singapore Zam Zam', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300059', '300059', 'Komala Vilas', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300060', '300060', 'Muthu''s Curry', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300041, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300042, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300043, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Market', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300044, id FROM tags WHERE tag_name IN ('Shopping', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300045, id FROM tags WHERE tag_name IN ('Heritage', 'Architecture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300046, id FROM tags WHERE tag_name IN ('Shopping', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300047, id FROM tags WHERE tag_name IN ('Mosque', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300048, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300049, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300050, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300051, id FROM tags WHERE tag_name IN ('Mosque', 'Religious', 'Heritage', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300052, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300053, id FROM tags WHERE tag_name IN ('Shopping', 'Street Art', 'Photography', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300054, id FROM tags WHERE tag_name IN ('Shopping', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300055, id FROM tags WHERE tag_name IN ('Market', 'Shopping', 'Street Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300056, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300057, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300058, id FROM tags WHERE tag_name IN ('Food', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300059, id FROM tags WHERE tag_name IN ('Food', 'Vegetarian', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300060, id FROM tags WHERE tag_name IN ('Food', 'Local Culture');

-- ============================================================================
-- BATCH 4 — BOTANIC GARDENS, ORCHARD, DEMPSEY & HOLLAND — places 300061-300080
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300061', '3001', 'Singapore Botanic Gardens', 'Singapore Botanic Gardens', 'UNESCO-listed tropical botanic garden with heritage landscapes, rainforest, lakes and themed plant collections.', '3-5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free general gardens', 5.0, 4.9, 1.3138, 103.8159, '1 Cluny Road, Singapore 259569', 'https://sbg.nparks.gov.sg/visit/general-info/', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official NParks hours: Gardens daily 5:00 AM-midnight.', '2026-10-01'),
('300062', '3001', 'National Orchid Garden', 'National Orchid Garden', 'Ticketed garden within Singapore Botanic Gardens showcasing extensive tropical orchid collections.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Standard adult S$15; students/seniors S$3; under 12 free', 4.9, 4.9, 1.3128, 103.8147, 'Singapore Botanic Gardens, 1 Cluny Road, Singapore 259569', 'https://sbg.nparks.gov.sg/visit/general-info/', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official NParks hours 8:30 AM-7:00 PM; last ticket sale/entry 6:00 PM.', '2026-10-01'),
('300063', '3001', 'Jacob Ballas Children''s Garden', 'Jacob Ballas Children''s Garden', 'Nature-learning garden for children within Singapore Botanic Gardens with play areas and interactive landscapes.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.6, 1.3214, 103.8141, '481 Bukit Timah Road, Singapore 259769', 'https://sbg.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Children-focused garden; operating days can include Monday closure except public holidays.', '2026-10-01'),
('300064', '3001', 'Learning Forest', 'Learning Forest', 'Boardwalks and elevated walks through wetland and secondary rainforest habitats at the Botanic Gardens.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.6, 1.3097, 103.8131, 'Singapore Botanic Gardens, Singapore', 'https://sbg.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Part of the Botanic Gardens; general gardens open 5 AM-midnight.', '2026-10-01'),
('300065', '3001', 'Gallop Extension & Forest Discovery Centre', 'Gallop Extension & Forest Discovery Centre', 'Botanic Gardens extension featuring heritage buildings, forest exhibits, galleries and landscaped trails.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Outdoor areas free; gallery access generally free', 4.4, 4.5, 1.3105, 103.8081, '5 Gallop Road, Singapore 258960', 'https://sbg.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Outdoor garden follows Botanic Gardens hours; indoor centre has shorter hours.', '2026-10-01'),
('300066', '3001', 'Orchard Road', 'Orchard Road', 'Singapore’s flagship shopping boulevard lined with malls, hotels, department stores and seasonal street decorations.', '3-5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public street; shopping extra', 4.8, 4.5, 1.3048, 103.8318, 'Orchard Road, Singapore', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public commercial district; mall hours vary.', '2026-10-01'),
('300067', '3001', 'ION Orchard', 'ION Orchard', 'Major luxury and lifestyle mall above Orchard MRT with retail, dining and indoor connections.', '2-3 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; shopping extra', 4.5, 4.4, 1.304, 103.8319, '2 Orchard Turn, Singapore 238801', 'https://www.ionorchard.com/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mall trading hours can change during holidays.', '2026-10-01'),
('300068', '3001', 'ION Sky', 'ION Sky', 'Observation space high above Orchard Road offering city views from ION Orchard.', '30-60 minutes', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Access policy varies', 4.3, 4.4, 1.3042, 103.8319, 'ION Orchard, 2 Orchard Turn, Singapore 238801', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Public-access policy and operating hours are dynamic.', '2026-10-01'),
('300069', '3001', 'Design Orchard', 'Design Orchard', 'Retail and design showcase on Orchard Road promoting Singapore fashion, lifestyle products and creative brands.', '1-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; shopping extra', 4.3, 4.4, 1.3018, 103.8363, '250 Orchard Road, Singapore 238905', 'https://designorchard.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Retail and rooftop hours differ; refresh current schedule.', '2026-10-01'),
('300070', '3001', 'Emerald Hill', 'Emerald Hill', 'Conserved residential street near Orchard with ornate Peranakan and Straits Chinese terrace houses.', '30-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public street', 4.5, 4.5, 1.3016, 103.8393, 'Emerald Hill Road, Singapore', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public street with conserved private residences.', '2026-10-01'),
('300071', '3001', 'Dempsey Hill', 'Dempsey Hill', 'Former military-barracks area converted into a leafy dining, retail and lifestyle enclave.', '2-4 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free district access; dining/shopping extra', 4.5, 4.5, 1.3046, 103.8106, 'Dempsey Road, Singapore 249679', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public lifestyle district; venue hours vary.', '2026-10-01'),
('300072', '3001', 'Museum of Ice Cream Singapore', 'Museum of Ice Cream Singapore', 'Interactive pink-themed attraction with playful installations centered on ice-cream culture.', '1.5-2 hours', 'Afternoon', '', 'Advance booking required', 'Singapore', 0, 0, '', '', 'Ticketed attraction; dynamic pricing', 4.2, 4.2, 1.3039, 103.8118, '100 Loewen Road, Singapore 248837', 'https://www.museumoficecream.com/singapore', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Timed-entry attraction; hours and prices vary by date.', '2026-10-01'),
('300073', '3001', 'Holland Village', 'Holland Village', 'Compact dining and nightlife neighbourhood with cafés, restaurants and low-rise shophouse streets.', '2-3 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free district access; dining extra', 4.3, 4.4, 1.3113, 103.7961, 'Holland Avenue / Lorong Mambong, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public neighbourhood; business hours vary.', '2026-10-01'),
('300074', '3001', 'One Holland Village', 'One Holland Village', 'Modern mixed-use retail complex adding restaurants, shops and public spaces to Holland Village.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry; shopping/dining extra', 4.0, 4.2, 1.311, 103.7954, '7 Holland Village Way, Singapore 275748', NULL, 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mall/retail hours can change.', '2026-10-01'),
('300075', '3001', 'Candlenut', 'Candlenut', 'Michelin-recognised Peranakan restaurant in Dempsey serving contemporary interpretations of Straits Chinese cuisine.', '1.5-2 hours', 'Dinner', '', 'Reservation recommended', 'Singapore', 0, 0, '', '', 'Premium dining', 4.8, 4.8, 1.3055, 103.8092, '17A Dempsey Road, Singapore 249676', 'https://www.comodempsey.sg/restaurant/candlenut', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Peranakan', 'premium', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Official restaurant; meal periods and menu pricing change.', '2026-10-01'),
('300076', '3001', 'Burnt Ends', 'Burnt Ends', 'Contemporary barbecue restaurant in Dempsey centered on wood-fired cooking and counter dining.', '2 hours', 'Dinner', '', 'Advance reservation strongly recommended', 'Singapore', 0, 0, '', '', 'Premium dining', 4.8, 4.8, 1.3058, 103.81, '7 Dempsey Road, Singapore 249671', 'https://burntends.com.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Modern Barbecue', 'premium', 'limited', 'own', '2026-10-01 17:45:00', 'partial', 'High-demand restaurant; service hours and reservation release rules change.', '2026-10-01'),
('300077', '3001', 'PS.Cafe Harding Road', 'PS.Cafe Harding Road', 'Leafy Dempsey café-restaurant known for brunch, cakes, salads, burgers and garden-like surroundings.', '1.5-2 hours', 'Brunch', '', '', 'Singapore', 0, 0, '', '', 'Mid to premium', 4.5, 4.5, 1.3052, 103.8096, '28B Harding Road, Singapore 249549', 'https://www.pscafe.com/', 0.91, '2026-10-01 17:45:00', NULL, 'restaurant', 'Cafe / International', 'premium', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Official chain; outlet service hours should be refreshed.', '2026-10-01'),
('300078', '3001', 'Chatterbox', 'Chatterbox', 'Singapore restaurant best known for its long-running Mandarin chicken rice and local classics.', '1-1.5 hours', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Premium casual dining', 4.5, 4.4, 1.3028, 103.8365, 'Hilton Singapore Orchard, 333 Orchard Road, Singapore 238867', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singaporean', 'premium', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Hotel restaurant; current hours/menu should be refreshed.', '2026-10-01'),
('300079', '3001', 'Violet Oon Singapore at ION Orchard', 'Violet Oon Singapore at ION Orchard', 'Restaurant showcasing Singaporean, Peranakan and heritage recipes in a refined Orchard setting.', '1.5-2 hours', 'Dinner', '', '', 'Singapore', 0, 0, '', '', 'Premium dining', 4.6, 4.6, 1.3041, 103.8319, 'ION Orchard, 2 Orchard Turn, Singapore 238801', 'https://violetoon.com/', 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singaporean / Peranakan', 'premium', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Official restaurant brand; current branch hours should be refreshed.', '2026-10-01'),
('300080', '3001', 'Holland Drive Market & Food Centre', 'Holland Drive Market & Food Centre', 'Neighbourhood hawker centre serving economical local breakfast and lunch near Holland Village.', '1-1.5 hours', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.2, 4.4, 1.3088, 103.7922, '44 Holland Drive, Singapore 270044', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Stall operating hours vary widely.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300061', '300061', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', ''),
('300062', '300062', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', '8:30 AM - 7:00 PM', ''),
('300063', '300063', 'Closed / PH exception', '8:00 AM - 7:00 PM', '8:00 AM - 7:00 PM', '8:00 AM - 7:00 PM', '8:00 AM - 7:00 PM', '8:00 AM - 7:00 PM', '8:00 AM - 7:00 PM', ''),
('300064', '300064', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', '5:00 AM - 12:00 AM', ''),
('300065', '300065', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', 'Outdoor: 5:00 AM - 12:00 AM; indoor venue shorter', ''),
('300066', '300066', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300067', '300067', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300068', '300068', 'Access-dependent', 'Access-dependent', 'Access-dependent', 'Access-dependent', 'Access-dependent', 'Access-dependent', 'Access-dependent', ''),
('300069', '300069', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', '10:30 AM - 9:30 PM', ''),
('300070', '300070', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300071', '300071', 'Venue-dependent', 'Venue-dependent', 'Venue-dependent', 'Venue-dependent', 'Venue-dependent', 'Venue-dependent', 'Venue-dependent', ''),
('300072', '300072', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', ''),
('300073', '300073', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300074', '300074', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300075', '300075', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', ''),
('300076', '300076', 'Lunch / dinner service', 'Lunch / dinner service', 'Lunch / dinner service', 'Lunch / dinner service', 'Lunch / dinner service', 'Lunch / dinner service', 'Lunch / dinner service', ''),
('300077', '300077', 'Brunch through dinner', 'Brunch through dinner', 'Brunch through dinner', 'Brunch through dinner', 'Brunch through dinner', 'Brunch through dinner', 'Brunch through dinner', ''),
('300078', '300078', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', ''),
('300079', '300079', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', 'Lunch and dinner service', ''),
('300080', '300080', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300061', '300061', 'Singapore Botanic Gardens', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300062', '300062', 'National Orchid Garden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300063', '300063', 'Jacob Ballas Children''s Garden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300064', '300064', 'Learning Forest', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300065', '300065', 'Gallop Extension & Forest Discovery Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300066', '300066', 'Orchard Road', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300067', '300067', 'ION Orchard', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300068', '300068', 'ION Sky', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300069', '300069', 'Design Orchard', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300070', '300070', 'Emerald Hill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300071', '300071', 'Dempsey Hill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300072', '300072', 'Museum of Ice Cream Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300073', '300073', 'Holland Village', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300074', '300074', 'One Holland Village', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300075', '300075', 'Candlenut', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300076', '300076', 'Burnt Ends', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300077', '300077', 'PS.Cafe Harding Road', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300078', '300078', 'Chatterbox', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300079', '300079', 'Violet Oon Singapore at ION Orchard', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300080', '300080', 'Holland Drive Market & Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300061, id FROM tags WHERE tag_name IN ('UNESCO', 'Garden', 'Nature', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300062, id FROM tags WHERE tag_name IN ('Garden', 'Photography', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300063, id FROM tags WHERE tag_name IN ('Garden', 'Family', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300064, id FROM tags WHERE tag_name IN ('Nature', 'Garden', 'Boardwalk');
INSERT INTO place_tags (place_id, tag_id) SELECT 300065, id FROM tags WHERE tag_name IN ('Museum', 'Nature', 'Garden', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300066, id FROM tags WHERE tag_name IN ('Shopping', 'Architecture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300067, id FROM tags WHERE tag_name IN ('Shopping', 'Food', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300068, id FROM tags WHERE tag_name IN ('Observation Deck', 'Viewpoint', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300069, id FROM tags WHERE tag_name IN ('Shopping', 'Design', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300070, id FROM tags WHERE tag_name IN ('Heritage', 'Architecture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300071, id FROM tags WHERE tag_name IN ('Food', 'Shopping', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300072, id FROM tags WHERE tag_name IN ('Museum', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300073, id FROM tags WHERE tag_name IN ('Food', 'Nightlife', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300074, id FROM tags WHERE tag_name IN ('Shopping', 'Food', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300075, id FROM tags WHERE tag_name IN ('Food', 'Peranakan');
INSERT INTO place_tags (place_id, tag_id) SELECT 300076, id FROM tags WHERE tag_name IN ('Food', 'Fine Dining');
INSERT INTO place_tags (place_id, tag_id) SELECT 300077, id FROM tags WHERE tag_name IN ('Food', 'Garden');
INSERT INTO place_tags (place_id, tag_id) SELECT 300078, id FROM tags WHERE tag_name IN ('Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300079, id FROM tags WHERE tag_name IN ('Food', 'Peranakan');
INSERT INTO place_tags (place_id, tag_id) SELECT 300080, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');

-- ============================================================================
-- BATCH 5 — SENTOSA & RESORTS WORLD — places 300081-300100
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300081', '3001', 'Universal Studios Singapore', 'Universal Studios Singapore', 'Major theme park at Resorts World Sentosa with movie-themed rides, shows and seven themed zones.', 'Full day', 'Morning', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Ticketed theme park; date-based pricing', 5.0, 4.8, 1.254, 103.8238, '30 Sentosa Gateway, Singapore 098140', 'https://www.rwsentosa.com/en/play/universal-studios-singapore', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official site publishes date-specific operating hours; commonly opens 10 AM and closes between early evening and 8 PM. Verify chosen date.', '2026-10-01'),
('300082', '3001', 'Singapore Oceanarium', 'Singapore Oceanarium', 'Large marine attraction at Resorts World Sentosa with more than 40 habitats, immersive zones and conservation-focused interpretation.', '3-4 hours', 'Morning', '', 'Timed entry may apply during peak periods', 'Singapore', 0, 0, '', '', 'Ticketed attraction; resident/tourist rates vary', 5.0, 4.9, 1.258, 103.8206, '24 Sentosa Gateway, Sentosa Island, Singapore 098137', 'https://www.singaporeoceanarium.com/en.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official Sep 2026 schedule shows standard 10 AM-8 PM, with specific early-closure dates including 1 Oct 2026 at 2 PM. Always use date calendar.', '2026-10-01'),
('300083', '3001', 'Adventure Cove Waterpark', 'Adventure Cove Waterpark', 'Water theme park at Resorts World Sentosa combining slides, lazy river and marine attractions.', 'Full day', 'Morning', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Ticketed waterpark', 4.7, 4.6, 1.2587, 103.819, '8 Sentosa Gateway, Singapore 098269', 'https://www.rwsentosa.com/en/play/adventure-cove-waterpark', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Operating schedule and ride availability are date-dependent.', '2026-10-01'),
('300084', '3001', 'Harry Potter: Visions of Magic Singapore', 'Harry Potter: Visions of Magic Singapore', 'Immersive multimedia experience at Resorts World Sentosa inspired by locations and magic from the Harry Potter universe.', '1.5-2 hours', 'Afternoon', '', 'Timed booking required', 'Singapore', 0, 0, '', '', 'Ticketed immersive experience', 4.6, 4.6, 1.2574, 103.8202, 'Resorts World Sentosa, Singapore 098269', 'https://www.rwsentosa.com/en/events/harry-potter-visions-of-magic', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Current Resorts World Sentosa attraction/event; timed-ticket schedule varies.', '2026-10-01'),
('300085', '3001', 'SkyHelix Sentosa', 'SkyHelix Sentosa', 'Open-air rotating gondola ride rising high above Sentosa with 360-degree island and harbour views.', '30-45 minutes', 'Sunset', '', '', 'Singapore', 0, 1, '', '', 'Adult S$20; child S$17 before online discounts', 4.5, 4.5, 1.2555, 103.817, '41 Imbiah Road, Sentosa, Singapore 099707', 'https://www.sentosa.com.sg/things-to-do/attractions/skyhelix-sentosa', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Sentosa official page: daily 10:00 AM-9:30 PM; last admission 9:00 PM.', '2026-10-01'),
('300086', '3001', 'Singapore Cable Car', 'Singapore Cable Car', 'Aerial cable-car network connecting Mount Faber, HarbourFront and Sentosa with harbour and island views.', '1-1.5 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed ride; pass types vary', 4.8, 4.7, 1.2669, 103.8191, 'Mount Faber / HarbourFront / Sentosa stations, Singapore', 'https://www.sentosa.com.sg/things-to-do/attractions/singapore-cable-car', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Sentosa official page: daily 8:45 AM-10:00 PM; last boarding 9:30 PM.', '2026-10-01'),
('300087', '3001', 'Madame Tussauds Singapore', 'Madame Tussauds Singapore', 'Sentosa wax museum with celebrity figures, Spirit of Singapore boat ride and multimedia experiences.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.3, 4.3, 1.2562, 103.8177, '40 Imbiah Road, Sentosa, Singapore 099700', 'https://www.sentosa.com.sg/en/things-to-do/attractions/madame-tussauds-singapore', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Sentosa official page: daily 10:00 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300088', '3001', 'Skyline Luge Singapore', 'Skyline Luge Singapore', 'Gravity-powered luge tracks and chairlift rides on Sentosa, suitable for families and repeat runs.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed ride bundles', 4.6, 4.6, 1.2526, 103.8172, '45 Siloso Beach Walk, Sentosa, Singapore 099003', 'https://www.skylineluge.com/en/sentosa/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Current operating schedule and weather closures should be checked.', '2026-10-01'),
('300089', '3001', 'Mega Adventure Park', 'Mega Adventure Park', 'Sentosa adventure attraction featuring ziplines and high-element activities.', '2-3 hours', 'Morning', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Paid activities; packages vary', 4.4, 4.5, 1.2529, 103.8154, '10A Siloso Beach Walk, Sentosa, Singapore 099008', 'https://www.megazip.com.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Activity schedule and restrictions vary; refresh before production.', '2026-10-01'),
('300090', '3001', 'iFly Singapore', 'iFly Singapore', 'Indoor skydiving wind tunnel at Siloso Beach offering instructor-led bodyflight sessions.', '1.5-2 hours', 'Afternoon', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Ticketed flight packages', 4.4, 4.5, 1.2516, 103.8174, '43 Siloso Beach Walk, Sentosa, Singapore 099010', 'https://www.iflysingapore.com/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Timed sessions and package prices vary.', '2026-10-01'),
('300091', '3001', 'Wings of Time', 'Wings of Time', 'Nighttime outdoor spectacle at Siloso Beach using water screens, lasers, fire, projection and music.', '30-45 minutes', 'Evening', '', 'Advance ticket recommended', 'Singapore', 0, 0, '', '', 'Ticketed show', 4.7, 4.6, 1.2507, 103.8175, '50 Beach View, Sentosa, Singapore 098604', 'https://www.sentosa.com.sg/things-to-do/attractions/wings-of-time', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Show times vary by date; refresh current schedule.', '2026-10-01'),
('300092', '3001', 'Sentosa Sensoryscape', 'Sentosa Sensoryscape', 'Landscaped pedestrian spine connecting Resorts World Sentosa to the beaches through sensory gardens and nighttime digital experiences.', '1-1.5 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public space', 4.5, 4.5, 1.2542, 103.8182, 'Sentosa, Singapore', 'https://www.sentosa.com.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Sentosa connector; individual nighttime experiences may have separate timings.', '2026-10-01'),
('300093', '3001', 'Palawan Beach', 'Palawan Beach', 'Family-oriented Sentosa beach with calm swimming areas and access to the southernmost-point suspension bridge area.', '2-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public beach', 4.6, 4.5, 1.2494, 103.8221, 'Palawan Beach, Sentosa, Singapore 099981', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Sentosa beach; specific facilities keep separate hours.', '2026-10-01'),
('300094', '3001', 'Siloso Beach', 'Siloso Beach', 'Sentosa’s liveliest beach, lined with activities, casual dining and beach clubs.', '2-4 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public beach; activities extra', 4.6, 4.4, 1.2502, 103.8149, 'Siloso Beach, Sentosa, Singapore', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Sentosa beach.', '2026-10-01'),
('300095', '3001', 'Tanjong Beach', 'Tanjong Beach', 'Quieter Sentosa beach on the island’s southern edge, popular for relaxed afternoons and sunset.', '2-4 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free public beach', 4.4, 4.5, 1.2449, 103.8288, 'Tanjong Beach, Sentosa, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Sentosa beach.', '2026-10-01'),
('300096', '3001', 'Fort Siloso', 'Fort Siloso', 'Singapore’s preserved coastal fort with military exhibits, tunnels and World War II history.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free general admission', 4.7, 4.7, 1.2585, 103.8089, 'Siloso Road, Sentosa, Singapore 099981', 'https://www.sentosa.com.sg/things-to-do/attractions/fort-siloso', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Sentosa heritage attraction; gallery and trail hours should be refreshed.', '2026-10-01'),
('300097', '3001', 'Fort Siloso Skywalk', 'Fort Siloso Skywalk', 'Elevated walkway leading toward Fort Siloso with treetop and harbour views.', '30-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.3, 4.4, 1.2588, 103.8101, 'Siloso Road, Sentosa, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Access hours may differ from Fort Siloso galleries.', '2026-10-01'),
('300098', '3001', 'Sentosa Nature Discovery', 'Sentosa Nature Discovery', 'Nature interpretation centre and trails exploring Sentosa’s secondary forest, birds and biodiversity.', '1-1.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.4, 1.2567, 103.8163, 'Imbiah Lookout, Sentosa, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Sentosa nature attraction; centre hours and trail access differ.', '2026-10-01'),
('300099', '3001', 'Imbiah Trail', 'Imbiah Trail', 'Forested walking trail network on Sentosa linking Imbiah Lookout, heritage points and nature areas.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.2575, 103.816, 'Imbiah, Sentosa, Singapore', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Outdoor public trail network.', '2026-10-01'),
('300100', '3001', 'Scentopia', 'Scentopia', 'Interactive Sentosa fragrance attraction where visitors learn about scents and can create personalised perfumes.', '1-1.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free entry to some areas; workshops/products extra', 4.0, 4.2, 1.2509, 103.818, '36 Siloso Beach Walk, Sentosa, Singapore 099007', 'https://www.scentopia-singapore.com/', 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Private attraction; workshop hours and prices vary.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300081', '300081', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', ''),
('300082', '300082', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', 'Calendar-dependent; standard 10:00 AM - 8:00 PM', ''),
('300083', '300083', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', 'Calendar-dependent', ''),
('300084', '300084', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', ''),
('300085', '300085', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', '10:00 AM - 9:30 PM', ''),
('300086', '300086', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', '8:45 AM - 10:00 PM', ''),
('300087', '300087', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', ''),
('300088', '300088', 'Day/evening sessions', 'Day/evening sessions', 'Day/evening sessions', 'Day/evening sessions', 'Day/evening sessions', 'Day/evening sessions', 'Day/evening sessions', ''),
('300089', '300089', 'Daytime activity schedule', 'Daytime activity schedule', 'Daytime activity schedule', 'Daytime activity schedule', 'Daytime activity schedule', 'Daytime activity schedule', 'Daytime activity schedule', ''),
('300090', '300090', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', ''),
('300091', '300091', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', 'Evening show schedule', ''),
('300092', '300092', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300093', '300093', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300094', '300094', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300095', '300095', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300096', '300096', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', ''),
('300097', '300097', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', '9:00 AM - 10:00 PM', ''),
('300098', '300098', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', ''),
('300099', '300099', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300100', '300100', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '11:00 AM - 7:00 PM', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300081', '300081', 'Universal Studios Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300082', '300082', 'Singapore Oceanarium', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300083', '300083', 'Adventure Cove Waterpark', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300084', '300084', 'Harry Potter: Visions of Magic Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300085', '300085', 'SkyHelix Sentosa', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300086', '300086', 'Singapore Cable Car', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300087', '300087', 'Madame Tussauds Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300088', '300088', 'Skyline Luge Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300089', '300089', 'Mega Adventure Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300090', '300090', 'iFly Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300091', '300091', 'Wings of Time', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300092', '300092', 'Sentosa Sensoryscape', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300093', '300093', 'Palawan Beach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300094', '300094', 'Siloso Beach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300095', '300095', 'Tanjong Beach', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300096', '300096', 'Fort Siloso', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300097', '300097', 'Fort Siloso Skywalk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300098', '300098', 'Sentosa Nature Discovery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300099', '300099', 'Imbiah Trail', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300100', '300100', 'Scentopia', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300081, id FROM tags WHERE tag_name IN ('Theme Park', 'Family', 'Adventure');
INSERT INTO place_tags (place_id, tag_id) SELECT 300082, id FROM tags WHERE tag_name IN ('Aquarium', 'Marine Life', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300083, id FROM tags WHERE tag_name IN ('Water Park', 'Family', 'Adventure');
INSERT INTO place_tags (place_id, tag_id) SELECT 300084, id FROM tags WHERE tag_name IN ('Immersive Experience', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300085, id FROM tags WHERE tag_name IN ('Viewpoint', 'Ride', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300086, id FROM tags WHERE tag_name IN ('Cable Car', 'Viewpoint', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300087, id FROM tags WHERE tag_name IN ('Museum', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300088, id FROM tags WHERE tag_name IN ('Adventure', 'Family', 'Ride');
INSERT INTO place_tags (place_id, tag_id) SELECT 300089, id FROM tags WHERE tag_name IN ('Adventure', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300090, id FROM tags WHERE tag_name IN ('Adventure', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300091, id FROM tags WHERE tag_name IN ('Show', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300092, id FROM tags WHERE tag_name IN ('Garden', 'Photography', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300093, id FROM tags WHERE tag_name IN ('Beach', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300094, id FROM tags WHERE tag_name IN ('Beach', 'Adventure', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300095, id FROM tags WHERE tag_name IN ('Beach', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300096, id FROM tags WHERE tag_name IN ('Fort', 'Museum', 'Heritage', 'War History');
INSERT INTO place_tags (place_id, tag_id) SELECT 300097, id FROM tags WHERE tag_name IN ('Viewpoint', 'Heritage', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300098, id FROM tags WHERE tag_name IN ('Nature', 'Family', 'Bird Watching');
INSERT INTO place_tags (place_id, tag_id) SELECT 300099, id FROM tags WHERE tag_name IN ('Nature', 'Trek', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300100, id FROM tags WHERE tag_name IN ('Workshop', 'Shopping', 'Family');

-- ============================================================================
-- BATCH 6 — MANDAI, KRANJI & THE NORTH — places 300101-300120
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300101', '3001', 'Singapore Zoo', 'Singapore Zoo', 'Open-concept zoological park at Mandai with large naturalistic habitats and animal presentations.', 'Full day', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed wildlife park', 5.0, 4.9, 1.4043, 103.793, '80 Mandai Lake Road, Singapore 729826', 'https://www.mandai.com/en/singapore-zoo.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Mandai official maps list daily 8:30 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300102', '3001', 'Night Safari', 'Night Safari', 'Night wildlife park using tram and walking trails to view nocturnal animals after sunset.', '3-4 hours', 'Evening', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Ticketed wildlife park', 5.0, 4.9, 1.4021, 103.7885, '80 Mandai Lake Road, Singapore 729826', 'https://www.mandai.com/en/night-safari.html', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Mandai official map lists daily 6:00 PM-midnight; last entry 11:15 PM.', '2026-10-01'),
('300103', '3001', 'River Wonders', 'River Wonders', 'Freshwater and river-themed wildlife park at Mandai, including giant pandas and aquatic habitats.', '3-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed wildlife park', 4.8, 4.7, 1.4038, 103.7906, '80 Mandai Lake Road, Singapore 729826', 'https://www.mandai.com/en/river-wonders.html', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Mandai official map lists daily 9:00 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300104', '3001', 'Bird Paradise', 'Bird Paradise', 'Large Mandai bird park with more than 3,500 birds across immersive walk-through aviaries.', '4-6 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed wildlife park', 4.9, 4.9, 1.4122, 103.7898, '20 Mandai Lake Road, Singapore 729825', 'https://www.mandai.com/en/bird-paradise.html', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Official Mandai page lists daily 9:00 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300105', '3001', 'Rainforest Wild Adventure EAST', 'Rainforest Wild Adventure EAST', 'Immersive Mandai rainforest attraction combining wildlife environments with active adventure experiences.', '3-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.7, 4.7, 1.4075, 103.792, '80 Mandai Lake Road, Singapore 729826', 'https://www.mandai.com/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Mandai official map lists daily 9:00 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300106', '3001', 'Rainforest Wild Adventure WEST', 'Rainforest Wild Adventure WEST', 'Mandai Wildlife WEST rainforest experience with immersive nature and wildlife zones.', '3-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.6, 4.7, 1.413, 103.7875, '20 Mandai Lake Road, Singapore 729825', 'https://www.mandai.com/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Mandai official map lists daily 9:00 AM-6:00 PM; last entry 5:00 PM.', '2026-10-01'),
('300107', '3001', 'Mandai Boardwalk', 'Mandai Boardwalk', 'Reservoir-edge walking boardwalk within the Mandai precinct offering water and nature views.', '45-90 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.4, 1.408, 103.79, 'Mandai Wildlife Reserve, Singapore', 'https://www.mandai.com/en/plan-your-visit/maps.html', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mandai public-access feature; current access hours should be checked.', '2026-10-01'),
('300108', '3001', 'Mandai Gallery', 'Mandai Gallery', 'Interpretive gallery within Mandai Wildlife Reserve about wildlife, conservation and the precinct’s development.', '45-60 minutes', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Access conditions vary', 4.0, 4.2, 1.409, 103.789, 'Mandai Wildlife Reserve, Singapore', 'https://www.mandai.com/en/plan-your-visit/maps.html', 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Gallery is listed by Mandai; current admission/access details should be refreshed.', '2026-10-01'),
('300109', '3001', 'Curiosity Cove', 'Curiosity Cove', 'Child-focused play and discovery attraction within the Mandai precinct.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed / session-based', 4.1, 4.3, 1.41, 103.79, 'Mandai Wildlife Reserve, Singapore', 'https://www.mandai.com/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mandai attraction; current session times and ticketing should be refreshed.', '2026-10-01'),
('300110', '3001', 'Exploria', 'Exploria', 'Indoor interactive experience at Mandai with play and discovery activities for children and families.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed / session-based', 4.0, 4.2, 1.4105, 103.7905, 'Mandai Wildlife Reserve, Singapore', 'https://www.mandai.com/', 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mandai-listed attraction; current schedule should be refreshed.', '2026-10-01'),
('300111', '3001', 'Sungei Buloh Wetland Reserve', 'Sungei Buloh Wetland Reserve', 'Singapore’s first ASEAN Heritage Park, protecting mangroves, mudflats and migratory-bird habitat.', '2-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.4464, 103.73, '60 Kranji Way, Singapore 739453', 'https://www.nparks.gov.sg/visit/parks/park-detail/sungei-buloh-wetland-reserve', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks official hours 7:00 AM-7:00 PM; last entry 6:30 PM.', '2026-10-01'),
('300112', '3001', 'Kranji Marshes', 'Kranji Marshes', 'Freshwater marsh and grassland nature area known for birdwatching and a tower viewpoint.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public area; guided areas may require registration', 4.5, 4.6, 1.4205, 103.7213, '11 Neo Tiew Lane 2, Singapore 718814', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Nature-park access and guided-core arrangements should be refreshed.', '2026-10-01'),
('300113', '3001', 'Kranji Reservoir Park', 'Kranji Reservoir Park', 'Reservoir-side public park near the Johor Strait with fishing areas, memorials and open lawns.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.4386, 103.7366, '30 Kranji Way, Singapore 739440', 'https://www.nparks.gov.sg/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks reservoir park.', '2026-10-01'),
('300114', '3001', 'Bollywood Farms', 'Bollywood Farms', 'Working farm and bistro in the Kranji countryside growing tropical produce and offering farm visits and meals.', '1.5-2.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Farm visit/dining pricing varies', 4.3, 4.5, 1.4182, 103.7175, '100 Neo Tiew Road, Singapore 719026', 'https://bollywoodfarms.com/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Private farm; operating days and booking arrangements vary.', '2026-10-01'),
('300115', '3001', 'Hay Dairies Goat Farm', 'Hay Dairies Goat Farm', 'Singapore goat dairy farm offering visitor viewing of goats and farm products.', '45-90 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'General viewing low-cost/free; purchases extra', 4.1, 4.3, 1.4238, 103.7219, '3 Lim Chu Kang Lane 4, Singapore 718859', 'https://haydairies.sg/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Private farm; visitor hours and closures should be refreshed.', '2026-10-01'),
('300116', '3001', 'Woodlands Waterfront Park', 'Woodlands Waterfront Park', 'Northern coastal park with a long jetty and views toward Johor Bahru across the strait.', '1-2 hours', 'Sunset', '', '', 'Singapore', 0, 1, '', '', 'Free', 4.3, 4.5, 1.4516, 103.7803, '6A Admiralty Road West, Singapore 759956', 'https://www.nparks.gov.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300117', '3001', 'Admiralty Park', 'Admiralty Park', 'Large northern park with hilly nature areas and one of Singapore’s biggest collections of playground slides.', '1.5-2.5 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.6, 1.4404, 103.7803, '31 Riverside Road, Singapore 739087', 'https://www.nparks.gov.sg/visit/parks', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks lists general park open 24 hours; nature area 7 AM-7 PM.', '2026-10-01'),
('300118', '3001', 'Sembawang Hot Spring Park', 'Sembawang Hot Spring Park', 'Public park built around Singapore’s natural hot spring, with foot-soaking pools and an egg-cooking station.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.5, 1.4346, 103.8226, 'Gambas Avenue, Singapore 756952', 'https://www.nparks.gov.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks hot-spring park.', '2026-10-01'),
('300119', '3001', 'Sembawang Park', 'Sembawang Park', 'Seaside park around Beaulieu House and Sembawang Jetty with maritime and naval-history connections.', '1-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.4611, 103.8368, 'Sembawang Road, Singapore 758459', 'https://www.nparks.gov.sg/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300120', '3001', 'Yishun Dam', 'Yishun Dam', 'Dam and roadside waterfront area popular with cyclists and sunset watchers near Lower Seletar.', '30-60 minutes', 'Sunset', '', '', 'Singapore', 0, 1, '', '', 'Free', 3.9, 4.1, 1.422, 103.8545, 'Yishun Avenue 1, Singapore', NULL, 0.86, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Public roadside viewpoint area; not a formal attraction.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300101', '300101', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', '8:30 AM - 6:00 PM', ''),
('300102', '300102', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', '6:00 PM - 12:00 AM', ''),
('300103', '300103', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', ''),
('300104', '300104', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', ''),
('300105', '300105', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', ''),
('300106', '300106', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', ''),
('300107', '300107', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300108', '300108', 'Park-dependent', 'Park-dependent', 'Park-dependent', 'Park-dependent', 'Park-dependent', 'Park-dependent', 'Park-dependent', ''),
('300109', '300109', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', ''),
('300110', '300110', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', 'Session-dependent', ''),
('300111', '300111', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300112', '300112', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300113', '300113', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300114', '300114', 'Selected days; check before visit', 'Selected days; check before visit', 'Selected days; check before visit', 'Selected days; check before visit', 'Selected days; check before visit', 'Selected days; check before visit', 'Selected days; check before visit', ''),
('300115', '300115', 'Morning visitor hours', 'Morning visitor hours', 'Morning visitor hours', 'Morning visitor hours', 'Morning visitor hours', 'Morning visitor hours', 'Morning visitor hours', ''),
('300116', '300116', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300117', '300117', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', '24 hours; nature area 7:00 AM - 7:00 PM', ''),
('300118', '300118', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300119', '300119', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300120', '300120', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300101', '300101', 'Singapore Zoo', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300102', '300102', 'Night Safari', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300103', '300103', 'River Wonders', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300104', '300104', 'Bird Paradise', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300105', '300105', 'Rainforest Wild Adventure EAST', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300106', '300106', 'Rainforest Wild Adventure WEST', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300107', '300107', 'Mandai Boardwalk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300108', '300108', 'Mandai Gallery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300109', '300109', 'Curiosity Cove', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300110', '300110', 'Exploria', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300111', '300111', 'Sungei Buloh Wetland Reserve', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300112', '300112', 'Kranji Marshes', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300113', '300113', 'Kranji Reservoir Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300114', '300114', 'Bollywood Farms', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300115', '300115', 'Hay Dairies Goat Farm', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300116', '300116', 'Woodlands Waterfront Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300117', '300117', 'Admiralty Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300118', '300118', 'Sembawang Hot Spring Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300119', '300119', 'Sembawang Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300120', '300120', 'Yishun Dam', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300101, id FROM tags WHERE tag_name IN ('Zoo', 'Wildlife', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300102, id FROM tags WHERE tag_name IN ('Wildlife', 'Nightlife', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300103, id FROM tags WHERE tag_name IN ('Wildlife', 'Aquarium', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300104, id FROM tags WHERE tag_name IN ('Bird Watching', 'Wildlife', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300105, id FROM tags WHERE tag_name IN ('Adventure', 'Wildlife', 'Nature', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300106, id FROM tags WHERE tag_name IN ('Adventure', 'Wildlife', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300107, id FROM tags WHERE tag_name IN ('Boardwalk', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300108, id FROM tags WHERE tag_name IN ('Museum', 'Wildlife', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300109, id FROM tags WHERE tag_name IN ('Family', 'Playground');
INSERT INTO place_tags (place_id, tag_id) SELECT 300110, id FROM tags WHERE tag_name IN ('Family', 'Indoor Attraction');
INSERT INTO place_tags (place_id, tag_id) SELECT 300111, id FROM tags WHERE tag_name IN ('Wetland', 'Mangrove', 'Bird Watching', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300112, id FROM tags WHERE tag_name IN ('Wetland', 'Bird Watching', 'Nature', 'Viewpoint');
INSERT INTO place_tags (place_id, tag_id) SELECT 300113, id FROM tags WHERE tag_name IN ('Park', 'Waterfront', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300114, id FROM tags WHERE tag_name IN ('Farm', 'Food', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300115, id FROM tags WHERE tag_name IN ('Farm', 'Family', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300116, id FROM tags WHERE tag_name IN ('Park', 'Waterfront', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300117, id FROM tags WHERE tag_name IN ('Park', 'Family', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300118, id FROM tags WHERE tag_name IN ('Hot Spring', 'Park', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300119, id FROM tags WHERE tag_name IN ('Park', 'Waterfront', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300120, id FROM tags WHERE tag_name IN ('Waterfront', 'Viewpoint', 'Photography');

-- ============================================================================
-- BATCH 7 — EAST COAST, KATONG, JOO CHIAT & CHANGI — places 300121-300140
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300121', '3001', 'East Coast Park', 'East Coast Park', 'Long coastal park with beaches, cycling routes, lawns, food areas and family recreation.', '3-5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.7, 1.3008, 103.9123, 'East Coast Park Service Road, Singapore', 'https://www.nparks.gov.sg/visit/parks', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks lists East Coast Park open 24 hours.', '2026-10-01'),
('300122', '3001', 'Coastal PlayGrove', 'Coastal PlayGrove', 'Family recreation zone at East Coast Park on the former Big Splash site, with play areas and open lawns.', '1.5-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.4, 1.3001, 103.9065, '902 East Coast Park, Singapore 449874', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Public park feature; individual play zones may have maintenance closures.', '2026-10-01'),
('300123', '3001', 'Bedok Jetty', 'Bedok Jetty', 'Long public jetty at East Coast Park popular with anglers, walkers and sunrise views.', '30-60 minutes', 'Sunrise', '', '', 'Singapore', 1, 0, '', '', 'Free', 4.3, 4.4, 1.305, 103.9361, 'East Coast Park Area F, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public jetty within East Coast Park.', '2026-10-01'),
('300124', '3001', 'East Coast Lagoon Food Village', 'East Coast Lagoon Food Village', 'Large seaside hawker centre inside East Coast Park, known for satay, seafood, barbecue and local dishes.', '1.5-2 hours', 'Dinner', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.7, 4.6, 1.3073, 103.9344, '1220 East Coast Parkway, Singapore 468960', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Seafood', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Hawker-centre hours and stall schedules vary.', '2026-10-01'),
('300125', '3001', 'Katong–Joo Chiat Heritage District', 'Katong–Joo Chiat Heritage District', 'Historic east-side neighbourhood known for Peranakan shophouses, temples, traditional businesses and food.', '3-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public district; dining/shopping extra', 4.8, 4.8, 1.3116, 103.9018, 'Joo Chiat Road / East Coast Road, Singapore', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public heritage district.', '2026-10-01'),
('300126', '3001', 'Koon Seng Road Shophouses', 'Koon Seng Road Shophouses', 'Iconic row of colourful Peranakan terrace houses in Joo Chiat.', '20-40 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.5, 1.3122, 103.9036, 'Koon Seng Road, Singapore', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public street view of conserved private houses.', '2026-10-01'),
('300127', '3001', 'The Intan', 'The Intan', 'Private Peranakan home-museum offering guided visits, antiques and cultural experiences by appointment.', '1.5-2 hours', 'Afternoon', '', 'Advance booking required', 'Singapore', 0, 0, '', '', 'Paid guided experience', 4.6, 4.8, 1.318, 103.905, '69 Joo Chiat Terrace, Singapore 427231', 'https://the-intan.com/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Private museum; appointment and package details vary.', '2026-10-01'),
('300128', '3001', 'Eurasian Heritage Gallery', 'Eurasian Heritage Gallery', 'Community museum at the Eurasian Association tracing Eurasian history, culture and contributions in Singapore.', '1-1.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free / low-cost depending on programme', 4.2, 4.4, 1.3077, 103.8981, '139 Ceylon Road, Singapore 429744', 'https://www.eurasians.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Community heritage gallery; current visitor hours should be refreshed.', '2026-10-01'),
('300129', '3001', 'Geylang Serai Market', 'Geylang Serai Market', 'Market and hawker centre serving Malay and Muslim food alongside fresh produce and household goods.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals / market purchases', 4.7, 4.7, 1.3167, 103.898, '1 Geylang Serai, Singapore 402001', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Malay / Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'verified', 'Public market and hawker centre; stall hours vary.', '2026-10-01'),
('300130', '3001', 'Wisma Geylang Serai', 'Wisma Geylang Serai', 'Community and cultural hub beside Geylang Serai Market with events, programmes and Malay-community facilities.', '45-90 minutes', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Public areas free', 4.0, 4.2, 1.3175, 103.8974, '1 Engku Aman Turn, Singapore 408528', 'https://www.wgs.com.sg/', 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Community facility; programme and venue hours vary.', '2026-10-01'),
('300131', '3001', '328 Katong Laksa', '328 Katong Laksa', 'Well-known Katong eatery serving coconut-rich laksa with cut noodles and seafood.', '30-60 minutes', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget', 4.6, 4.5, 1.305, 103.9052, '51 East Coast Road, Singapore 428770', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Katong Laksa', 'budget', 'limited', 'own', '2026-10-01 17:45:00', 'partial', 'Popular restaurant; current outlet hours should be refreshed.', '2026-10-01'),
('300132', '3001', 'Chin Mee Chin Confectionery', 'Chin Mee Chin Confectionery', 'Old-school Katong coffee shop known for kaya toast, kopi, pastries and nostalgic tile-and-marble interiors.', '45-60 minutes', 'Breakfast', '', '', 'Singapore', 0, 0, '', '', 'Budget', 4.6, 4.6, 1.3054, 103.9044, '204 East Coast Road, Singapore 428903', 'https://www.chinmeechin.sg/', 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Cafe / Kaya Toast', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Historic cafe; current days off and hours should be refreshed.', '2026-10-01'),
('300133', '3001', 'Changi Chapel and Museum', 'Changi Chapel and Museum', 'NHB museum documenting the experiences of prisoners and civilians in Singapore during the Japanese Occupation.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Tourist admission applies; concessions available', 4.7, 4.7, 1.3627, 103.9724, '1000 Upper Changi Road North, Singapore 507707', 'https://www.nhb.gov.sg/changichapelmuseum', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NHB lists Tue-Sun 9:30 AM-5:30 PM, closed Monday except public holidays; last admission 5 PM.', '2026-10-01'),
('300134', '3001', 'Changi Village Hawker Centre', 'Changi Village Hawker Centre', 'East-side hawker centre near the ferry terminal, known for nasi lemak, seafood, noodles and local breakfast dishes.', '1-1.5 hours', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.7, 4.6, 1.3894, 103.988, '2 Changi Village Road, Singapore 500002', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Malay / Seafood', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Individual hawker hours vary substantially.', '2026-10-01'),
('300135', '3001', 'Changi Boardwalk', 'Changi Boardwalk', 'Coastal boardwalk around Changi Point with sections through mangrove-edge and seaside scenery.', '1-1.5 hours', 'Sunset', '', '', 'Singapore', 0, 1, '', '', 'Free', 4.4, 4.5, 1.3899, 103.991, 'Changi Point, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Public coastal boardwalk; maintenance can affect segments.', '2026-10-01'),
('300136', '3001', 'Changi Beach Park', 'Changi Beach Park', 'Long east-coast public park facing Pulau Ubin and Johor waters, popular for cycling, picnics and planespotting.', '2-3 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.3908, 103.992, 'Nicoll Drive, Singapore 498991', 'https://www.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300137', '3001', 'HSBC Rain Vortex', 'HSBC Rain Vortex', 'Jewel Changi Airport’s central indoor waterfall dropping through the glass-roofed complex.', '30-60 minutes', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free', 5.0, 4.8, 1.3602, 103.9897, 'Jewel Changi Airport, 78 Airport Boulevard, Singapore 819666', 'https://www.jewelchangiairport.com/', 0.95, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Core Jewel public attraction; light-show schedule can change.', '2026-10-01'),
('300138', '3001', 'Shiseido Forest Valley', 'Shiseido Forest Valley', 'Multi-level indoor garden wrapping around Jewel’s Rain Vortex, with walking paths and lush planting.', '45-90 minutes', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.3601, 103.9896, 'Jewel Changi Airport, Singapore 819666', 'https://www.jewelchangiairport.com/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Free public garden within Jewel; access follows Jewel public-area operations.', '2026-10-01'),
('300139', '3001', 'Canopy Park', 'Canopy Park', 'Jewel’s top-floor attraction zone with gardens, Discovery Slides, Foggy Bowls and access to additional ticketed mazes/nets.', '1.5-2.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed; bundles vary', 4.7, 4.7, 1.36, 103.9894, 'Level 5, Jewel Changi Airport, Singapore 819666', 'https://www.jewelchangiairport.com/en/attractions/canopy-park.html', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Jewel ticketing currently lists Mon-Thu 10 AM-9 PM; Fri-Sun 10 AM-10 PM.', '2026-10-01'),
('300140', '3001', 'Changi Experience Studio', 'Changi Experience Studio', 'Interactive digital attraction in Jewel explaining the airport, aviation operations and Changi experiences through games and simulations.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.5, 4.5, 1.3604, 103.9893, 'Level 4, Jewel Changi Airport, Singapore 819666', 'https://www.jewelchangiairport.com/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Jewel current attraction information states 11:00 AM-8:00 PM; last admission 7:00 PM.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300121', '300121', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300122', '300122', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', ''),
('300123', '300123', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300124', '300124', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', 'Late morning - late evening; stall-dependent', ''),
('300125', '300125', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300126', '300126', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300127', '300127', 'By appointment', 'By appointment', 'By appointment', 'By appointment', 'By appointment', 'By appointment', 'By appointment', ''),
('300128', '300128', 'Selected daytime hours', 'Selected daytime hours', 'Selected daytime hours', 'Selected daytime hours', 'Selected daytime hours', 'Selected daytime hours', 'Selected daytime hours', ''),
('300129', '300129', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', 'Early morning - evening; stall-dependent', ''),
('300130', '300130', 'Day/evening programme-dependent', 'Day/evening programme-dependent', 'Day/evening programme-dependent', 'Day/evening programme-dependent', 'Day/evening programme-dependent', 'Day/evening programme-dependent', 'Day/evening programme-dependent', ''),
('300131', '300131', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300132', '300132', 'Morning - afternoon', 'Morning - afternoon', 'Morning - afternoon', 'Morning - afternoon', 'Morning - afternoon', 'Morning - afternoon', 'Morning - afternoon', ''),
('300133', '300133', 'Closed', '9:30 AM - 5:30 PM', '9:30 AM - 5:30 PM', '9:30 AM - 5:30 PM', '9:30 AM - 5:30 PM', '9:30 AM - 5:30 PM', '9:30 AM - 5:30 PM', ''),
('300134', '300134', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', 'Morning - late evening; stall-dependent', ''),
('300135', '300135', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', 'Daylight / evening', ''),
('300136', '300136', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300137', '300137', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', 'Jewel public-area hours / show-dependent', ''),
('300138', '300138', 'Long daily hours', 'Long daily hours', 'Long daily hours', 'Long daily hours', 'Long daily hours', 'Long daily hours', 'Long daily hours', ''),
('300139', '300139', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 9:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300140', '300140', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '11:00 AM - 8:00 PM', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300121', '300121', 'East Coast Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300122', '300122', 'Coastal PlayGrove', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300123', '300123', 'Bedok Jetty', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300124', '300124', 'East Coast Lagoon Food Village', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300125', '300125', 'Katong–Joo Chiat Heritage District', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300126', '300126', 'Koon Seng Road Shophouses', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300127', '300127', 'The Intan', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300128', '300128', 'Eurasian Heritage Gallery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300129', '300129', 'Geylang Serai Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300130', '300130', 'Wisma Geylang Serai', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300131', '300131', '328 Katong Laksa', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300132', '300132', 'Chin Mee Chin Confectionery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300133', '300133', 'Changi Chapel and Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300134', '300134', 'Changi Village Hawker Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300135', '300135', 'Changi Boardwalk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300136', '300136', 'Changi Beach Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300137', '300137', 'HSBC Rain Vortex', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300138', '300138', 'Shiseido Forest Valley', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300139', '300139', 'Canopy Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300140', '300140', 'Changi Experience Studio', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300121, id FROM tags WHERE tag_name IN ('Park', 'Beach', 'Cycling', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300122, id FROM tags WHERE tag_name IN ('Playground', 'Family', 'Park');
INSERT INTO place_tags (place_id, tag_id) SELECT 300123, id FROM tags WHERE tag_name IN ('Waterfront', 'Photography', 'Fishing');
INSERT INTO place_tags (place_id, tag_id) SELECT 300124, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Beach');
INSERT INTO place_tags (place_id, tag_id) SELECT 300125, id FROM tags WHERE tag_name IN ('Heritage', 'Peranakan', 'Food', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300126, id FROM tags WHERE tag_name IN ('Peranakan', 'Architecture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300127, id FROM tags WHERE tag_name IN ('Museum', 'Peranakan', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300128, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300129, id FROM tags WHERE tag_name IN ('Market', 'Hawker Centre', 'Food', 'Malay Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300130, id FROM tags WHERE tag_name IN ('Local Culture', 'Community');
INSERT INTO place_tags (place_id, tag_id) SELECT 300131, id FROM tags WHERE tag_name IN ('Food', 'Peranakan');
INSERT INTO place_tags (place_id, tag_id) SELECT 300132, id FROM tags WHERE tag_name IN ('Food', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300133, id FROM tags WHERE tag_name IN ('Museum', 'War History', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300134, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300135, id FROM tags WHERE tag_name IN ('Boardwalk', 'Waterfront', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300136, id FROM tags WHERE tag_name IN ('Park', 'Beach', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300137, id FROM tags WHERE tag_name IN ('Waterfall', 'Architecture', 'Photography', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300138, id FROM tags WHERE tag_name IN ('Garden', 'Architecture', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300139, id FROM tags WHERE tag_name IN ('Family', 'Garden', 'Playground');
INSERT INTO place_tags (place_id, tag_id) SELECT 300140, id FROM tags WHERE tag_name IN ('Museum', 'Interactive', 'Family');

-- ============================================================================
-- BATCH 8 — SOUTHERN RIDGES, HARBOURFRONT & PASIR PANJANG — places 300141-300160
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300141', '3001', 'Mount Faber Park', 'Mount Faber Park', 'Hilltop park above HarbourFront with harbour views, walking trails and access to the Singapore Cable Car.', '1.5-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.7, 4.7, 1.2712, 103.8196, 'Mount Faber Road, Singapore 099200', 'https://www.nparks.gov.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks hill park.', '2026-10-01'),
('300142', '3001', 'Faber Point', 'Faber Point', 'Mount Faber summit viewpoint and landmark area overlooking the harbour, Sentosa and southern islands.', '30-60 minutes', 'Sunset', '', '', 'Singapore', 0, 1, '', '', 'Free', 4.6, 4.6, 1.2713, 103.8179, 'Mount Faber Park, Singapore', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public viewpoint inside Mount Faber Park.', '2026-10-01'),
('300143', '3001', 'Henderson Waves', 'Henderson Waves', 'Singapore’s highest pedestrian bridge, a wave-shaped timber structure connecting Mount Faber and Telok Blangah Hill.', '30-60 minutes', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.9, 4.8, 1.2763, 103.816, 'Henderson Road, Singapore', 'https://www.nparks.gov.sg/visit/parks/telok-blangah-hill-park/special-features/henderson-waves', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks confirms 274 m bridge and LED lighting 7 PM-2 AM daily.', '2026-10-01'),
('300144', '3001', 'Telok Blangah Hill Park', 'Telok Blangah Hill Park', 'Hilly park forming part of the Southern Ridges with forest, terraces and links to Henderson Waves.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.2766, 103.8175, '10 Telok Blangah Green, Singapore 109178', 'https://www.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300145', '3001', 'Forest Walk – Southern Ridges', 'Forest Walk – Southern Ridges', 'Elevated walkway through secondary forest between Telok Blangah Hill and Alexandra Arch.', '45-90 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.2773, 103.8085, 'Southern Ridges, Singapore', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Southern Ridges trail.', '2026-10-01'),
('300146', '3001', 'HortPark', 'HortPark', 'Gardening-themed park with display gardens, horticulture areas and links to the Southern Ridges.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.2789, 103.8017, '33 Hyderabad Road, Singapore 119578', 'https://www.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks horticultural park.', '2026-10-01'),
('300147', '3001', 'Labrador Nature Reserve', 'Labrador Nature Reserve', 'Coastal nature reserve preserving rocky shore, forest and wartime military structures along the southern coast.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.6, 1.2665, 103.8026, 'Labrador Villa Road, Singapore 119187', 'https://www.nparks.gov.sg/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks nature reserve; access generally 7 AM-7 PM for nature-reserve areas.', '2026-10-01'),
('300148', '3001', 'Berlayer Creek Boardwalk', 'Berlayer Creek Boardwalk', 'Mangrove-edge boardwalk linking Labrador MRT to the coast through one of southern Singapore’s natural estuaries.', '30-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.3, 4.5, 1.271, 103.8035, 'Labrador Park, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks boardwalk.', '2026-10-01'),
('300149', '3001', 'Labrador Battery', 'Labrador Battery', 'Remains of British coastal-defence gun positions and military structures inside Labrador Nature Reserve.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.3, 1.2671, 103.8013, 'Labrador Nature Reserve, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Outdoor heritage structures in public park.', '2026-10-01'),
('300150', '3001', 'Marina at Keppel Bay', 'Marina at Keppel Bay', 'Modern marina and waterfront promenade framed by luxury residences and yachts.', '1-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public waterfront; dining extra', 4.2, 4.4, 1.2642, 103.8129, '2 Keppel Bay Vista, Singapore 098382', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public marina promenade; individual venues vary.', '2026-10-01'),
('300151', '3001', 'VivoCity Sky Park', 'VivoCity Sky Park', 'Large rooftop public space at VivoCity with harbour views and family recreation near Sentosa gateway.', '45-90 minutes', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.2645, 103.822, '1 HarbourFront Walk, Singapore 098585', 'https://www.vivocity.com.sg/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Mall rooftop/public-space access follows mall rules.', '2026-10-01'),
('300152', '3001', 'Reflections at Bukit Chandu', 'Reflections at Bukit Chandu', 'NHB museum at a restored colonial bungalow interpreting the Battle of Pasir Panjang and Malay Regiment.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Tourist admission may apply; concessions available', 4.7, 4.7, 1.2765, 103.792, '31-K Pepys Road, Singapore 118458', 'https://www.nhb.gov.sg/bukitchandu', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NHB lists Tue-Sun 9:30 AM-5:00 PM, closed Monday except public holidays; last admission 4:30 PM.', '2026-10-01'),
('300153', '3001', 'Kent Ridge Park', 'Kent Ridge Park', 'Hilly park with forest trails, viewpoints and World War II associations overlooking Pasir Panjang.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.2813, 103.7901, 'Vigilante Drive, Singapore 118176', 'https://www.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300154', '3001', 'Canopy Walk – Kent Ridge', 'Canopy Walk – Kent Ridge', 'Elevated forest walkway connecting Kent Ridge Park toward HortPark through secondary forest.', '30-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.3, 4.5, 1.2811, 103.794, 'Kent Ridge Park, Singapore', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public park boardwalk.', '2026-10-01'),
('300155', '3001', 'Haw Par Villa', 'Haw Par Villa', 'Open-air cultural park filled with Chinese mythological sculptures, dioramas and moral tales.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Outdoor park generally free; museum ticket separate', 4.7, 4.6, 1.2838, 103.7818, '262 Pasir Panjang Road, Singapore 118628', 'https://www.hawparvilla.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Outdoor park and museum have different hours and ticketing.', '2026-10-01'),
('300156', '3001', 'Hell''s Museum', 'Hell''s Museum', 'Ticketed museum inside Haw Par Villa examining death, afterlife beliefs and the famous Ten Courts of Hell.', '1-1.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Ticketed museum', 4.4, 4.5, 1.2838, 103.7819, 'Haw Par Villa, 262 Pasir Panjang Road, Singapore 118628', 'https://www.hawparvilla.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Current admission and operating hours should be refreshed.', '2026-10-01'),
('300157', '3001', 'Pasir Panjang Food Centre', 'Pasir Panjang Food Centre', 'Hawker centre near the port known for seafood, satay and late-evening local dining.', '1-1.5 hours', 'Dinner', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.2, 4.4, 1.2768, 103.7912, '121 Pasir Panjang Road, Singapore 118543', NULL, 0.89, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Seafood', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Individual stalls operate different days and hours.', '2026-10-01'),
('300158', '3001', 'Singapore Art Museum at Tanjong Pagar Distripark', 'Singapore Art Museum at Tanjong Pagar Distripark', 'Contemporary-art galleries and programmes in the Tanjong Pagar Distripark while SAM’s Bras Basah buildings undergo redevelopment.', '1.5-2 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Admission varies; some exhibitions free', 4.5, 4.5, 1.272, 103.7994, '39 Keppel Road, #01-02 Tanjong Pagar Distripark, Singapore 089065', 'https://www.singaporeartmuseum.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Programme venue; exhibition schedules and hours vary.', '2026-10-01'),
('300159', '3001', 'Gillman Barracks', 'Gillman Barracks', 'Former military barracks transformed into a contemporary-art and lifestyle enclave with galleries and restaurants.', '2-3 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'District access free; galleries generally free', 4.4, 4.5, 1.279, 103.7885, '9 Lock Road, Singapore 108937', 'https://www.gillmanbarracks.com/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Individual galleries keep separate schedules.', '2026-10-01'),
('300160', '3001', 'Alexandra Arch', 'Alexandra Arch', 'Curved pedestrian bridge connecting HortPark and the Forest Walk section of the Southern Ridges.', '20-40 minutes', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.2794, 103.8011, 'Alexandra Road, Singapore', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public pedestrian bridge.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300141', '300141', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300142', '300142', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300143', '300143', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300144', '300144', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300145', '300145', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300146', '300146', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', '6:00 AM - 11:00 PM', ''),
('300147', '300147', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300148', '300148', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300149', '300149', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300150', '300150', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300151', '300151', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', ''),
('300152', '300152', 'Closed', '9:30 AM - 5:00 PM', '9:30 AM - 5:00 PM', '9:30 AM - 5:00 PM', '9:30 AM - 5:00 PM', '9:30 AM - 5:00 PM', '9:30 AM - 5:00 PM', ''),
('300153', '300153', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300154', '300154', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300155', '300155', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', '9:00 AM - 8:00 PM', ''),
('300156', '300156', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', ''),
('300157', '300157', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', 'Afternoon - late evening; stall-dependent', ''),
('300158', '300158', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', '10:00 AM - 7:00 PM', ''),
('300159', '300159', 'Gallery-dependent', 'Gallery-dependent', 'Gallery-dependent', 'Gallery-dependent', 'Gallery-dependent', 'Gallery-dependent', 'Gallery-dependent', ''),
('300160', '300160', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300141', '300141', 'Mount Faber Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300142', '300142', 'Faber Point', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300143', '300143', 'Henderson Waves', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300144', '300144', 'Telok Blangah Hill Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300145', '300145', 'Forest Walk – Southern Ridges', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300146', '300146', 'HortPark', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300147', '300147', 'Labrador Nature Reserve', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300148', '300148', 'Berlayer Creek Boardwalk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300149', '300149', 'Labrador Battery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300150', '300150', 'Marina at Keppel Bay', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300151', '300151', 'VivoCity Sky Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300152', '300152', 'Reflections at Bukit Chandu', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300153', '300153', 'Kent Ridge Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300154', '300154', 'Canopy Walk – Kent Ridge', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300155', '300155', 'Haw Par Villa', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300156', '300156', 'Hell''s Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300157', '300157', 'Pasir Panjang Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300158', '300158', 'Singapore Art Museum at Tanjong Pagar Distripark', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300159', '300159', 'Gillman Barracks', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300160', '300160', 'Alexandra Arch', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300141, id FROM tags WHERE tag_name IN ('Park', 'Viewpoint', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300142, id FROM tags WHERE tag_name IN ('Viewpoint', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300143, id FROM tags WHERE tag_name IN ('Bridge', 'Architecture', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300144, id FROM tags WHERE tag_name IN ('Park', 'Nature', 'Trek');
INSERT INTO place_tags (place_id, tag_id) SELECT 300145, id FROM tags WHERE tag_name IN ('Boardwalk', 'Nature', 'Trek');
INSERT INTO place_tags (place_id, tag_id) SELECT 300146, id FROM tags WHERE tag_name IN ('Garden', 'Park', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300147, id FROM tags WHERE tag_name IN ('Nature Reserve', 'Coast', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300148, id FROM tags WHERE tag_name IN ('Boardwalk', 'Mangrove', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300149, id FROM tags WHERE tag_name IN ('War History', 'Heritage', 'Fort');
INSERT INTO place_tags (place_id, tag_id) SELECT 300150, id FROM tags WHERE tag_name IN ('Waterfront', 'Photography', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300151, id FROM tags WHERE tag_name IN ('Shopping', 'Viewpoint', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300152, id FROM tags WHERE tag_name IN ('Museum', 'War History', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300153, id FROM tags WHERE tag_name IN ('Park', 'War History', 'Nature', 'Viewpoint');
INSERT INTO place_tags (place_id, tag_id) SELECT 300154, id FROM tags WHERE tag_name IN ('Boardwalk', 'Nature', 'Bird Watching');
INSERT INTO place_tags (place_id, tag_id) SELECT 300155, id FROM tags WHERE tag_name IN ('Heritage', 'Local Culture', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300156, id FROM tags WHERE tag_name IN ('Museum', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300157, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300158, id FROM tags WHERE tag_name IN ('Museum', 'Art', 'Contemporary');
INSERT INTO place_tags (place_id, tag_id) SELECT 300159, id FROM tags WHERE tag_name IN ('Art', 'Heritage', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300160, id FROM tags WHERE tag_name IN ('Bridge', 'Architecture', 'Photography');

-- ============================================================================
-- BATCH 9 — CENTRAL NATURE, BUKIT TIMAH & HEARTLANDS — places 300161-300180
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300161', '3001', 'Bukit Timah Nature Reserve', 'Bukit Timah Nature Reserve', 'Primary rainforest reserve protecting Singapore’s highest natural point and rich biodiversity.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.3542, 103.7764, '177 Hindhede Drive, Singapore 589333', 'https://www.nparks.gov.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks nature reserve; public access generally 7:00 AM-7:00 PM.', '2026-10-01'),
('300162', '3001', 'Bukit Timah Summit', 'Bukit Timah Summit', 'Singapore’s highest natural point, reached by a steep paved/trail climb within Bukit Timah Nature Reserve.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.3547, 103.7764, 'Bukit Timah Nature Reserve, Singapore', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Within Bukit Timah Nature Reserve; reserve hours apply.', '2026-10-01'),
('300163', '3001', 'Hindhede Nature Park', 'Hindhede Nature Park', 'Family-friendly nature park beside Bukit Timah with a quarry viewpoint and easier trails.', '1-1.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.3489, 103.7769, 'Hindhede Drive, Singapore 589318', 'https://www.nparks.gov.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks nature park.', '2026-10-01'),
('300164', '3001', 'Dairy Farm Nature Park', 'Dairy Farm Nature Park', 'Nature park with forest trails, Wallace Trail and links toward Singapore Quarry.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.6, 1.3609, 103.7762, '100 Dairy Farm Road, Singapore 679057', 'https://www.nparks.gov.sg/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks nature park.', '2026-10-01'),
('300165', '3001', 'Wallace Education Centre', 'Wallace Education Centre', 'Restored heritage building in Dairy Farm Nature Park with exhibits on natural history and Alfred Russel Wallace.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.3, 1.3622, 103.7733, 'Dairy Farm Nature Park, Singapore', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Indoor education centre has shorter hours than surrounding park.', '2026-10-01'),
('300166', '3001', 'Rail Corridor', 'Rail Corridor', 'Continuous green corridor along the former railway line, popular for walking, running and cycling through multiple neighbourhoods.', '2-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.7, 1.33, 103.78, 'Former railway corridor across central/west Singapore', 'https://www.nparks.gov.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public green corridor; individual trail sections may close for works.', '2026-10-01'),
('300167', '3001', 'Bukit Timah Railway Station', 'Bukit Timah Railway Station', 'Restored former railway station and heritage node along the Rail Corridor.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.3341, 103.7792, '1 Bukit Timah Railway Station, Singapore 599938', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Restored public heritage node on Rail Corridor.', '2026-10-01'),
('300168', '3001', 'Bukit Timah Railway Truss Bridge', 'Bukit Timah Railway Truss Bridge', 'Historic black steel railway bridge preserved along the Rail Corridor.', '20-40 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.333, 103.7809, 'Rail Corridor near Upper Bukit Timah Road, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public heritage structure on Rail Corridor.', '2026-10-01'),
('300169', '3001', 'Central Catchment Nature Reserve', 'Central Catchment Nature Reserve', 'Singapore’s largest nature reserve around MacRitchie, Upper Seletar, Upper Peirce and Lower Peirce reservoirs.', 'Half day', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.357, 103.815, 'Central Singapore', 'https://www.nparks.gov.sg/visit/parks', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks lists Central Catchment Nature Reserve 7:00 AM-7:00 PM; TreeTop Walk has different hours.', '2026-10-01'),
('300170', '3001', 'MacRitchie Reservoir Park', 'MacRitchie Reservoir Park', 'Popular reservoir park and trailhead for forest walks into Central Catchment Nature Reserve.', '2-4 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.3416, 103.833, 'MacRitchie Reservoir, Singapore 298717', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks reservoir park; nature-reserve rules apply on trails.', '2026-10-01'),
('300171', '3001', 'TreeTop Walk', 'TreeTop Walk', 'Suspension bridge high in Central Catchment forest linking MacRitchie trail sections.', '3-4 hours including approach', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.8, 4.8, 1.3607, 103.8117, 'Central Catchment Nature Reserve, Singapore', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'TreeTop Walk has shorter operating hours and can close for weather/maintenance; verify before visit.', '2026-10-01'),
('300172', '3001', 'Windsor Nature Park', 'Windsor Nature Park', 'Buffer nature park with boardwalks and forest trails connecting toward Central Catchment.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.3573, 103.8271, '30 Venus Drive, Singapore 573858', 'https://www.nparks.gov.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks nature park.', '2026-10-01'),
('300173', '3001', 'Thomson Nature Park', 'Thomson Nature Park', 'Former Hainan village landscape reclaimed by forest, with heritage ruins and nature trails.', '1.5-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.387, 103.8152, 'Upper Thomson Road, Singapore 574423', 'https://www.nparks.gov.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks nature park.', '2026-10-01'),
('300174', '3001', 'Bishan–Ang Mo Kio Park', 'Bishan–Ang Mo Kio Park', 'Large river park with lawns, naturalised Kallang River, playgrounds and dining.', '1.5-3 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.3623, 103.8465, '1384 Ang Mo Kio Avenue 1, Singapore 569932', 'https://www.nparks.gov.sg/', 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300175', '3001', 'Lower Peirce Reservoir Park', 'Lower Peirce Reservoir Park', 'Quiet reservoir park with boardwalk through mature secondary forest and waterside views.', '1-1.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.3, 4.5, 1.3693, 103.8294, 'Old Upper Thomson Road, Singapore 574339', 'https://www.nparks.gov.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks reservoir park.', '2026-10-01'),
('300176', '3001', 'Upper Peirce Reservoir Park', 'Upper Peirce Reservoir Park', 'Scenic reservoir viewpoint and park in Central Catchment reached by a winding access road.', '1-1.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.6, 1.3778, 103.8032, 'Upper Peirce Reservoir Park, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public reservoir park with controlled road access.', '2026-10-01'),
('300177', '3001', 'Tiong Bahru Market', 'Tiong Bahru Market', 'Neighbourhood market and hawker centre in one of Singapore’s oldest housing estates.', '1.5-2 hours', 'Breakfast', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.8, 4.7, 1.2852, 103.8326, '30 Seng Poh Road, Singapore 168898', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Market/hawker operating hours vary by stall and cleaning day.', '2026-10-01'),
('300178', '3001', 'Tiong Bahru Heritage District', 'Tiong Bahru Heritage District', 'Art Deco public-housing neighbourhood with cafés, murals, independent shops and historic streets.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free public neighbourhood; dining extra', 4.7, 4.7, 1.2845, 103.833, 'Tiong Bahru, Singapore', NULL, 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public neighbourhood and heritage streets.', '2026-10-01'),
('300179', '3001', 'HDB LIVINGSPACE Gallery', 'HDB LIVINGSPACE Gallery', 'Public-housing gallery at HDB Hub explaining the evolution of Singapore’s housing planning and neighbourhood design.', '1-1.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.4, 1.3321, 103.848, 'HDB Hub, 480 Lorong 6 Toa Payoh, Singapore 310480', 'https://www.roots.gov.sg/places/places-landing/Places/building-and-sites/hdb-livingspace', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Government gallery; current visitor hours should be refreshed.', '2026-10-01'),
('300180', '3001', 'Toa Payoh Dragon Playground', 'Toa Payoh Dragon Playground', 'Iconic 1970s mosaic dragon playground preserved as a beloved piece of Singapore public-housing design history.', '20-40 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.4, 1.3366, 103.8565, '28 Lorong 6 Toa Payoh, Singapore 310028', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public neighbourhood playground.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300161', '300161', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300162', '300162', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300163', '300163', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300164', '300164', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300165', '300165', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', ''),
('300166', '300166', '24 hours / section-dependent', '24 hours / section-dependent', '24 hours / section-dependent', '24 hours / section-dependent', '24 hours / section-dependent', '24 hours / section-dependent', '24 hours / section-dependent', ''),
('300167', '300167', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300168', '300168', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300169', '300169', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300170', '300170', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300171', '300171', 'Closed', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '9:00 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', ''),
('300172', '300172', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300173', '300173', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300174', '300174', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300175', '300175', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300176', '300176', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', '6:00 AM - 7:30 PM', ''),
('300177', '300177', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', 'Morning - afternoon; stall-dependent', ''),
('300178', '300178', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300179', '300179', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 5:00 PM', '8:30 AM - 1:00 PM', 'Closed', ''),
('300180', '300180', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300161', '300161', 'Bukit Timah Nature Reserve', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300162', '300162', 'Bukit Timah Summit', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300163', '300163', 'Hindhede Nature Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300164', '300164', 'Dairy Farm Nature Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300165', '300165', 'Wallace Education Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300166', '300166', 'Rail Corridor', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300167', '300167', 'Bukit Timah Railway Station', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300168', '300168', 'Bukit Timah Railway Truss Bridge', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300169', '300169', 'Central Catchment Nature Reserve', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300170', '300170', 'MacRitchie Reservoir Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300171', '300171', 'TreeTop Walk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300172', '300172', 'Windsor Nature Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300173', '300173', 'Thomson Nature Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300174', '300174', 'Bishan–Ang Mo Kio Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300175', '300175', 'Lower Peirce Reservoir Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300176', '300176', 'Upper Peirce Reservoir Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300177', '300177', 'Tiong Bahru Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300178', '300178', 'Tiong Bahru Heritage District', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300179', '300179', 'HDB LIVINGSPACE Gallery', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300180', '300180', 'Toa Payoh Dragon Playground', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300161, id FROM tags WHERE tag_name IN ('Nature Reserve', 'Trek', 'Wildlife');
INSERT INTO place_tags (place_id, tag_id) SELECT 300162, id FROM tags WHERE tag_name IN ('Trek', 'Nature', 'Viewpoint');
INSERT INTO place_tags (place_id, tag_id) SELECT 300163, id FROM tags WHERE tag_name IN ('Nature', 'Family', 'Quarry', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300164, id FROM tags WHERE tag_name IN ('Nature', 'Trek', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300165, id FROM tags WHERE tag_name IN ('Museum', 'Nature', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300166, id FROM tags WHERE tag_name IN ('Trek', 'Heritage', 'Cycling', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300167, id FROM tags WHERE tag_name IN ('Railway', 'Heritage', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300168, id FROM tags WHERE tag_name IN ('Railway', 'Heritage', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300169, id FROM tags WHERE tag_name IN ('Nature Reserve', 'Trek', 'Wildlife');
INSERT INTO place_tags (place_id, tag_id) SELECT 300170, id FROM tags WHERE tag_name IN ('Lake', 'Nature', 'Trek', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300171, id FROM tags WHERE tag_name IN ('Bridge', 'Trek', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300172, id FROM tags WHERE tag_name IN ('Nature', 'Boardwalk', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300173, id FROM tags WHERE tag_name IN ('Nature', 'Heritage', 'Trek');
INSERT INTO place_tags (place_id, tag_id) SELECT 300174, id FROM tags WHERE tag_name IN ('Park', 'River', 'Family', 'Wildlife');
INSERT INTO place_tags (place_id, tag_id) SELECT 300175, id FROM tags WHERE tag_name IN ('Lake', 'Nature', 'Boardwalk');
INSERT INTO place_tags (place_id, tag_id) SELECT 300176, id FROM tags WHERE tag_name IN ('Lake', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300177, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Market', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 300178, id FROM tags WHERE tag_name IN ('Heritage', 'Architecture', 'Food', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300179, id FROM tags WHERE tag_name IN ('Museum', 'Architecture', 'Urban Planning');
INSERT INTO place_tags (place_id, tag_id) SELECT 300180, id FROM tags WHERE tag_name IN ('Heritage', 'Playground', 'Photography');

-- ============================================================================
-- BATCH 10 — PULAU UBIN, NORTHEAST & WESTERN DISCOVERY — places 300181-300200
-- ============================================================================

INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('300181', '3001', 'Pulau Ubin', 'Pulau Ubin', 'Rustic island off northeastern Singapore preserving kampong landscapes, quarries, cycling routes and biodiversity.', 'Full day', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Bumboat typically S$4 per person each way; bicycle supplement S$2', 4.9, 4.9, 1.4144, 103.9603, 'Pulau Ubin, Singapore', 'https://pulau-ubin.nparks.gov.sg/visitubin/', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks 2026 visitor info: bumboats generally operate on demand 6 AM-7 PM, departing with 12 passengers; fares can vary outside normal conditions.', '2026-10-01'),
('300182', '3001', 'Chek Jawa Wetlands', 'Chek Jawa Wetlands', 'Pulau Ubin wetland complex combining mangroves, seagrass, rocky shore and coastal forest with boardwalks and tower.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.9, 4.9, 1.4124, 103.992, 'Chek Jawa, Pulau Ubin, Singapore', 'https://pulau-ubin.nparks.gov.sg/', 0.94, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'NParks lists Chek Jawa 7 AM-7 PM. As of Sep 2026, part of Coastal Loop boardwalk is closed for maintenance until expected Apr 30, 2027; mangrove and open coastal sections remain accessible.', '2026-10-01'),
('300183', '3001', 'Puaka Hill', 'Puaka Hill', 'Short but steep Pulau Ubin hike to viewpoints over Ubin Quarry and the island landscape.', '1-1.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.7, 1.408, 103.9497, 'Pulau Ubin, Singapore', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Outdoor Pulau Ubin trail; weather-dependent.', '2026-10-01'),
('300184', '3001', 'Pekan Quarry', 'Pekan Quarry', 'Scenic former granite quarry near Ubin village, now a water-filled habitat viewed from public paths.', '30-45 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.4058, 103.9565, 'Pulau Ubin, Singapore', NULL, 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public Pulau Ubin viewpoint.', '2026-10-01'),
('300185', '3001', 'Ubin Sensory Trail', 'Ubin Sensory Trail', 'Short nature and village-garden trail near Ubin Town showcasing traditional plants and local ecology.', '45-60 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.1, 4.4, 1.4047, 103.96, 'Pulau Ubin, Singapore', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks trail near Ubin village.', '2026-10-01'),
('300186', '3001', 'Coney Island Park', 'Coney Island Park', 'Rustic northeastern island park linked to Punggol by bridges, with forest, beaches and cycling routes.', '2-3 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.6, 1.4081, 103.9235, 'Punggol Promenade Nature Walk, Singapore', 'https://www.nparks.gov.sg/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks island park; gate hours are daytime.', '2026-10-01'),
('300187', '3001', 'Punggol Waterway Park', 'Punggol Waterway Park', 'Linear river-and-canal park with cycling routes, bridges, playgrounds and waterfront lawns.', '1.5-3 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.4, 4.5, 1.4063, 103.9025, 'Sentul Crescent Road, Singapore 821313', 'https://www.nparks.gov.sg/', 0.9, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300188', '3001', 'Lorong Halus Wetland', 'Lorong Halus Wetland', 'Constructed wetland beside Serangoon Reservoir that treats water naturally and connects to Punggol cycling routes.', '45-90 minutes', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.0, 4.3, 1.3955, 103.9213, 'Lorong Halus, Singapore', NULL, 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public wetland and park connector area.', '2026-10-01'),
('300189', '3001', 'The Punggol Settlement', 'The Punggol Settlement', 'Waterfront dining cluster at Punggol Point with restaurants and access to the promenade.', '1.5-2 hours', 'Evening', '', '', 'Singapore', 0, 0, '', '', 'Free public area; dining extra', 4.1, 4.3, 1.4205, 103.9127, '3 Punggol Point Road, Singapore 828694', NULL, 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Dining complex; individual restaurant hours vary.', '2026-10-01'),
('300190', '3001', 'Sengkang Riverside Park', 'Sengkang Riverside Park', 'River-edge park with wetlands, fruit-tree areas, cycling routes and family spaces.', '1.5-2 hours', 'Late Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.0, 4.3, 1.3907, 103.8875, 'Anchorvale Street, Singapore 544834', 'https://www.nparks.gov.sg/', 0.87, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public NParks park.', '2026-10-01'),
('300191', '3001', 'Jurong Lake Gardens', 'Jurong Lake Gardens', 'Large national garden in western Singapore combining Lakeside Garden, Chinese Garden and Japanese Garden landscapes.', '3-5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.7, 4.8, 1.3368, 103.729, 'Yuan Ching Road, Singapore 618661', 'https://www.nparks.gov.sg/juronglakegardens', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Public national garden; outdoor areas have long daily access.', '2026-10-01'),
('300192', '3001', 'Chinese Garden', 'Chinese Garden', 'Revitalised landscape at Jurong Lake Gardens featuring Chinese-style pavilions, gardens and waterfront paths.', '1.5-2.5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.6, 4.7, 1.338, 103.73, 'Jurong Lake Gardens, Singapore', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Part of Jurong Lake Gardens; reopened after major redevelopment.', '2026-10-01'),
('300193', '3001', 'Japanese Garden', 'Japanese Garden', 'Japanese-inspired garden landscape at Jurong Lake Gardens with bridges, planting and waterside walks.', '1-2 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.5, 4.6, 1.336, 103.728, 'Jurong Lake Gardens, Singapore', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'verified', 'Part of Jurong Lake Gardens.', '2026-10-01'),
('300194', '3001', 'Science Centre Singapore', 'Science Centre Singapore', 'Hands-on science museum in Jurong with interactive exhibits, demonstrations and family learning spaces.', '3-5 hours', 'Morning', '', '', 'Singapore', 0, 0, '', '', 'Ticketed attraction', 4.6, 4.6, 1.3332, 103.7355, '15 Science Centre Road, Singapore 609081', 'https://www.science.edu.sg/', 0.92, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Operating days, galleries and ticket bundles should be refreshed.', '2026-10-01'),
('300195', '3001', 'Snow City Singapore', 'Snow City Singapore', 'Indoor snow-and-ice attraction beside Science Centre offering sub-zero play and snow activities.', '1.5-2 hours', 'Afternoon', '', 'Advance booking recommended', 'Singapore', 0, 0, '', '', 'Ticketed timed sessions', 4.1, 4.2, 1.333, 103.735, '21 Jurong Town Hall Road, Singapore 609433', 'https://www.snowcity.com.sg/', 0.88, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Timed attraction; operating hours and sessions vary.', '2026-10-01'),
('300196', '3001', 'Lee Kong Chian Natural History Museum', 'Lee Kong Chian Natural History Museum', 'NUS natural-history museum housing Singapore’s national zoological collections and dinosaur skeletons.', '2-3 hours', 'Afternoon', '', 'Advance ticket recommended', 'Singapore', 0, 0, '', '', 'Ticketed museum', 4.7, 4.8, 1.3018, 103.7736, '2 Conservatory Drive, Singapore 117377', 'https://lkcnhm.nus.edu.sg/', 0.93, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'Museum generally closes Monday; current timed-entry schedule should be refreshed.', '2026-10-01'),
('300197', '3001', 'NUS Museum', 'NUS Museum', 'University museum covering Asian art, archaeology, Singapore collections and changing exhibitions.', '1-1.5 hours', 'Afternoon', '', '', 'Singapore', 0, 0, '', '', 'Free', 4.2, 4.4, 1.2966, 103.773, '50 Kent Ridge Crescent, National University of Singapore, Singapore 119279', 'https://museum.nus.edu.sg/', 0.89, '2026-10-01 17:45:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 17:45:00', 'partial', 'University museum; current public hours should be refreshed.', '2026-10-01'),
('300198', '3001', 'Old Airport Road Food Centre', 'Old Airport Road Food Centre', 'Large, highly regarded hawker centre with a deep mix of classic Singapore stalls.', '1.5-2 hours', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.9, 4.8, 1.3083, 103.8859, '51 Old Airport Road, Singapore 390051', NULL, 0.94, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Individual stall hours vary widely.', '2026-10-01'),
('300199', '3001', 'Newton Food Centre', 'Newton Food Centre', 'Central open-air hawker centre near Orchard known for seafood, satay and late-evening dining.', '1.5-2 hours', 'Dinner', '', '', 'Singapore', 0, 0, '', '', 'Budget to mid-range hawker meals', 4.6, 4.3, 1.3122, 103.838, '500 Clemenceau Avenue North, Singapore 229495', NULL, 0.92, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Seafood', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Individual stall hours and pricing vary.', '2026-10-01'),
('300200', '3001', 'Adam Road Food Centre', 'Adam Road Food Centre', 'Compact hawker centre near Botanic Gardens known for nasi lemak and Malay-Muslim stalls.', '45-75 minutes', 'Lunch', '', '', 'Singapore', 0, 0, '', '', 'Budget hawker meals', 4.5, 4.5, 1.3248, 103.8142, '2 Adam Road, Singapore 289876', NULL, 0.91, '2026-10-01 17:45:00', NULL, 'restaurant', 'Singapore Hawker / Malay', 'budget', 'veg-options', 'own', '2026-10-01 17:45:00', 'partial', 'Stall hours vary; several close on different weekdays.', '2026-10-01');

INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('300181', '300181', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', 'Island open; normal bumboats 6:00 AM - 7:00 PM', ''),
('300182', '300182', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300183', '300183', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300184', '300184', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300185', '300185', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', 'Daylight', ''),
('300186', '300186', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', '7:00 AM - 7:00 PM', ''),
('300187', '300187', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300188', '300188', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300189', '300189', 'Restaurant-dependent', 'Restaurant-dependent', 'Restaurant-dependent', 'Restaurant-dependent', 'Restaurant-dependent', 'Restaurant-dependent', 'Restaurant-dependent', ''),
('300190', '300190', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', ''),
('300191', '300191', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', ''),
('300192', '300192', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', ''),
('300193', '300193', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', '5:30 AM - 11:00 PM', ''),
('300194', '300194', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', ''),
('300195', '300195', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', 'Timed sessions', ''),
('300196', '300196', 'Closed', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', ''),
('300197', '300197', 'Closed', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', 'Closed', ''),
('300198', '300198', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', ''),
('300199', '300199', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', 'Late morning - late night; stall-dependent', ''),
('300200', '300200', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', 'Morning - evening; stall-dependent', '');

INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('300181', '300181', 'Pulau Ubin', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300182', '300182', 'Chek Jawa Wetlands', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300183', '300183', 'Puaka Hill', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300184', '300184', 'Pekan Quarry', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300185', '300185', 'Ubin Sensory Trail', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300186', '300186', 'Coney Island Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300187', '300187', 'Punggol Waterway Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300188', '300188', 'Lorong Halus Wetland', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300189', '300189', 'The Punggol Settlement', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300190', '300190', 'Sengkang Riverside Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300191', '300191', 'Jurong Lake Gardens', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300192', '300192', 'Chinese Garden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300193', '300193', 'Japanese Garden', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300194', '300194', 'Science Centre Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300195', '300195', 'Snow City Singapore', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300196', '300196', 'Lee Kong Chian Natural History Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300197', '300197', 'NUS Museum', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300198', '300198', 'Old Airport Road Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300199', '300199', 'Newton Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('300200', '300200', 'Adam Road Food Centre', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS ----
INSERT INTO place_tags (place_id, tag_id) SELECT 300181, id FROM tags WHERE tag_name IN ('Island', 'Nature', 'Heritage', 'Cycling');
INSERT INTO place_tags (place_id, tag_id) SELECT 300182, id FROM tags WHERE tag_name IN ('Wetland', 'Mangrove', 'Boardwalk', 'Wildlife');
INSERT INTO place_tags (place_id, tag_id) SELECT 300183, id FROM tags WHERE tag_name IN ('Trek', 'Viewpoint', 'Quarry', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300184, id FROM tags WHERE tag_name IN ('Quarry', 'Nature', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300185, id FROM tags WHERE tag_name IN ('Nature', 'Heritage', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300186, id FROM tags WHERE tag_name IN ('Island', 'Nature', 'Cycling', 'Beach');
INSERT INTO place_tags (place_id, tag_id) SELECT 300187, id FROM tags WHERE tag_name IN ('Park', 'Waterfront', 'Cycling', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300188, id FROM tags WHERE tag_name IN ('Wetland', 'Cycling', 'Nature');
INSERT INTO place_tags (place_id, tag_id) SELECT 300189, id FROM tags WHERE tag_name IN ('Food', 'Waterfront', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300190, id FROM tags WHERE tag_name IN ('Park', 'River', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300191, id FROM tags WHERE tag_name IN ('Garden', 'Lake', 'Family', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300192, id FROM tags WHERE tag_name IN ('Garden', 'Heritage', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 300193, id FROM tags WHERE tag_name IN ('Garden', 'Photography', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300194, id FROM tags WHERE tag_name IN ('Museum', 'Science', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300195, id FROM tags WHERE tag_name IN ('Family', 'Indoor Attraction');
INSERT INTO place_tags (place_id, tag_id) SELECT 300196, id FROM tags WHERE tag_name IN ('Museum', 'Natural History', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 300197, id FROM tags WHERE tag_name IN ('Museum', 'Art', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 300198, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Local Culture');
INSERT INTO place_tags (place_id, tag_id) SELECT 300199, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Nightlife');
INSERT INTO place_tags (place_id, tag_id) SELECT 300200, id FROM tags WHERE tag_name IN ('Hawker Centre', 'Food', 'Malay Culture');

-- ============================================================================
-- FESTIVALS / MAJOR EVENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS festivals (
  id             INTEGER PRIMARY KEY,
  state_id       INTEGER,
  city_id        INTEGER,
  place_id       INTEGER,
  festival_name  TEXT NOT NULL,
  timing_label   TEXT,
  lunar_note     TEXT,
  duration_label TEXT,
  description    TEXT,
  source         TEXT DEFAULT 'own',
  updated_at     TEXT
);

INSERT INTO festivals (id, state_id, city_id, place_id, festival_name, timing_label, lunar_note, duration_label, description, source, updated_at) VALUES
(400001, 9101, 3001, 300013, 'Light to Night Singapore 2026', '9-31 January 2026', 'Dated 2026 arts festival', '23 days', 'Civic District arts festival centred on National Gallery Singapore and partner venues, with facade projections, installations and programmes.', 'own', '2026-10-01 17:45:00'),
(400002, 9101, 3001, 300024, 'Chinese New Year in Chinatown', 'January-February annually', 'Lunar calendar', 'Multiple weeks', 'Chinatown light-up, markets and Lunar New Year programming; exact annual dates and road closures should be refreshed.', 'own', '2026-10-01 17:45:00'),
(400003, 9101, 3001, 300052, 'Hari Raya in Kampong Gelam', 'Ramadan / Hari Raya period', 'Islamic lunar calendar; dates shift yearly', 'Multiple weeks', 'Festive bazaar, light-up and cultural programming around Kampong Gelam and Sultan Mosque; exact annual dates should be refreshed.', 'own', '2026-10-01 17:45:00'),
(400004, 9101, 3001, 300042, 'Deepavali in Little India', 'October-November annually', 'Hindu lunar calendar; date shifts yearly', 'Multiple weeks', 'Little India festive light-up, shopping and cultural programmes around Deepavali; exact dates and street arrangements should be refreshed.', 'own', '2026-10-01 17:45:00'),
(400005, 9101, 3001, 300002, 'Singapore Garden Festival 2026', '4-12 July 2026', 'Dated 2026 festival', '9 days', 'Gardens by the Bay hosts Singapore Garden Festival at The Meadow and Supertree Grove; official hours 10 AM-10 PM, last entry 9:30 PM.', 'own', '2026-10-01 17:45:00'),
(400006, 9101, 3001, 300001, 'Formula 1 Singapore Airlines Singapore Grand Prix 2026', '9-11 October 2026', 'Dated 2026 race weekend', '3 days', 'Night-race weekend at the Marina Bay Street Circuit; 2026 includes Singapore''s first F1 Sprint and extensive entertainment programming.', 'own', '2026-10-01 17:45:00'),
(400007, 9101, 3001, 300024, 'Mid-Autumn Festival 2026', '11 September-4 October 2026', '15th day of eighth lunar month season', 'Multiple weeks', 'Visit Singapore lists lantern activities in Chinatown from 11 Sep-4 Oct and related festive markets around Singapore in September 2026.', 'own', '2026-10-01 17:45:00'),
(400008, 9101, 3001, 300002, 'Christmas Wonderland 2026', 'Late November-December 2026', 'Year-end festive season', 'Multiple weeks', 'Annual Christmas Wonderland returns to Gardens by the Bay with light displays, carnival attractions and festive programming; exact 2026 dates should be refreshed.', 'own', '2026-10-01 17:45:00'),
(400009, 9101, 3001, NULL, 'Singapore National Day', '9 August annually', 'Fixed national day', '1 day plus surrounding events', 'National Day celebrations include parade-related programming, fireworks and community events; access controls vary by year.', 'own', '2026-10-01 17:45:00'),
(400010, 9101, 3001, 300016, 'Singapore HeritageFest 2026', 'May 2026', 'Annual heritage festival', 'Multiple weeks', 'National Heritage Board festival programming across museums and heritage precincts; Peranakan Museum ran Singapore HeritageFest programmes 1-24 May 2026.', 'own', '2026-10-01 17:45:00'),
(400011, 9101, 3001, 300001, 'Singapore New Year Countdown', '31 December-1 January', 'Gregorian New Year', '1 night', 'Year-end countdown activities and fireworks affect Marina Bay and other public areas; exact zones and transport controls should be refreshed annually.', 'own', '2026-10-01 17:45:00'),
(400012, 9101, 3001, 300181, 'Pulau Ubin Community Nature Events', 'Dates vary yearly', 'Community-event calendar', 'Varies', 'Nature and heritage activities are periodically organised on Pulau Ubin; exact annual programme should be refreshed from NParks and Ubin notices.', 'own', '2026-10-01 17:45:00');

-- ============================================================================
-- FINAL SINGAPORE CORE SUMMARY
-- ============================================================================
-- 1 city-state
-- 10 visitor-area batches
-- 200 places
-- 200 opening_hours rows
-- 200 photo placeholder rows
-- 12 festival/event rows
-- google_place_id remains NULL by owner decision.
-- Photo rows remain no_match placeholders pending licensed-image pass.
-- ============================================================================
