-- ==========================================================================
-- TripRaft Places Seed : THAILAND — PHASE 1 (BANGKOK VERIFIED STARTER)
-- Generated: 2026-10-01
-- Reference structure: andhra-pradesh-seed-verified.sql
-- --------------------------------------------------------------------------
-- WHAT THIS FILE DOES
--   1. Registers 10 priority Thailand destinations in cities.
--   2. Fully seeds the first destination, Bangkok, with 20 reviewed records.
--   3. Adds matching opening_hours, photo placeholders, place_tags, and
--      Bangkok festival rows.
--   4. Keeps google_place_id NULL, matching the owner decision in the
--      Andhra Pradesh seed.
--
-- IMPORTANT — PROVINCE / state_id MAPPING
-- The supplied TripRaft reference only exposes cities.state_id and does not
-- include the countries/states table schema. This file therefore RESERVES:
--   9001 Bangkok
--   9002 Phuket
--   9003 Chiang Mai
--   9004 Chon Buri            (Pattaya)
--   9005 Krabi
--   9006 Surat Thani          (Ko Samui)
--   9007 Chiang Rai
--   9008 Phra Nakhon Si Ayutthaya
--   9009 Prachuap Khiri Khan  (Hua Hin)
--   9010 Kanchanaburi
-- Before production import, replace these IDs if your states/provinces table
-- already uses different primary keys. This file intentionally does NOT
-- insert province rows because that table's schema was not present in the
-- provided reference.
--
-- VERIFICATION (2026-10-01)
-- Bangkok hours/fees were checked against official/government sources where
-- available. Rows are marked verified or partial. Any inferred/provisional
-- hours are explicitly flagged in verification_notes and hours notes.
--
-- PHOTOS
-- Phase 1 does not yet perform the licensed-image pass. All photo rows are
-- placeholders with photo_status='no_match'; do not interpret that as proof
-- that no licensed image exists.
-- ==========================================================================

-- ---- Cities: Thailand priority rollout ----
INSERT INTO cities (id, state_id, city_name, latitude, longitude, created_at, tier) VALUES
(2001, 9001, 'Bangkok', 13.7563, 100.5018, '2026-10-01 16:22:00', 1),
(2002, 9002, 'Phuket', 7.8804, 98.3923, '2026-10-01 16:22:00', 1),
(2003, 9003, 'Chiang Mai', 18.7883, 98.9853, '2026-10-01 16:22:00', 1),
(2004, 9004, 'Pattaya', 12.9236, 100.8825, '2026-10-01 16:22:00', 1),
(2005, 9005, 'Krabi', 8.0863, 98.9063, '2026-10-01 16:22:00', 1),
(2006, 9006, 'Ko Samui', 9.512, 100.0136, '2026-10-01 16:22:00', 1),
(2007, 9007, 'Chiang Rai', 19.9105, 99.8406, '2026-10-01 16:22:00', 2),
(2008, 9008, 'Ayutthaya', 14.3532, 100.5689, '2026-10-01 16:22:00', 2),
(2009, 9009, 'Hua Hin', 12.5684, 99.9577, '2026-10-01 16:22:00', 2),
(2010, 9010, 'Kanchanaburi', 14.0228, 99.5328, '2026-10-01 16:22:00', 2);

-- ---- Shared tag vocabulary (idempotent) ----
INSERT OR IGNORE INTO tags (tag_name) VALUES
('Temple'),('Museum'),('Heritage'),('Religious'),('Family'),('Photography'),
('River'),('Food'),('Shopping'),('Park'),('Nature'),('Viewpoint'),
('Palace'),('Market'),('Night Market'),('Street Food'),('Art'),('Observation Deck');

-- ============================================================================
-- CITY 1 : BANGKOK (id 2001) — places 200001-200020
-- ============================================================================

-- ---- PLACES: Bangkok ----
INSERT INTO places (id, city_id, place_name, name_english, ai_summary, suggested_duration, best_time_to_visit, place_tip, advanced_booking, state_name, sunrise_view, sunset_view, sunrise_time, sunset_time, cost, rating_tourist_priority, rating_traveler_experience, latitude, longitude, address, official_website, rank_score, created_at, google_place_id, category, cuisine, price_band, veg_flag, source, updated_at, verification_status, verification_notes, verified_at) VALUES
('200001', '2001', 'The Grand Palace', 'Grand Palace', 'Bangkok’s historic royal palace complex and home of the Temple of the Emerald Buddha, one of the city’s essential heritage sights.', '2-3 hours', 'Morning', 'Arrive near opening time and follow the strict dress code; ticket sales stop before the complex closes.', 'Advance online ticket optional', 'Bangkok', 0, 0, '', '', 'Foreigner ticket THB 500; children under 120 cm free; audio guide THB 200', 5.0, 4.8, 13.75, 100.4914, 'Na Phra Lan Road, Phra Nakhon, Bangkok 10200', 'https://www.royalgrandpalace.th/en', 0.99, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'premium', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official Grand Palace site checked 2026-10-01: open daily; visitor pages show complex opening 8:30 AM-4:30 PM, with ticket sales 8:30 AM-3:30 PM. Admission THB 500. The FAQ also states 8:30 AM-3:30 PM, so use the site footer/ticket-sale distinction in hours notes.', '2026-10-01'),
('200002', '2001', 'Wat Phra Chetuphon Wimon Mangkhalaram (Wat Pho)', 'Wat Pho', 'Historic temple beside the Grand Palace, famous for the Reclining Buddha and its traditional Thai massage school.', '1-2 hours', 'Morning', 'Combine with the Grand Palace; dress respectfully and allow extra time if booking a massage.', '', 'Bangkok', 0, 0, '', '', 'Foreign visitor admission THB 300; Thai nationals free with ID; children under 120 cm free', 4.9, 4.8, 13.7465, 100.493, '2 Sanam Chai Road, Phra Nakhon, Bangkok 10200', 'https://www.watpho.com/', 0.97, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'partial', 'Official Wat Pho pages checked 2026-10-01 confirm THB 300 foreign admission and closing 7:30 PM. One official visit-plan page says 8:00 AM opening while the homepage says 8:30 AM; stored hours use 8:00 AM-7:30 PM and flag the 30-minute conflict.', '2026-10-01'),
('200003', '2001', 'Wat Arun Ratchawararam', 'Wat Arun', 'Riverside Buddhist temple known as the Temple of Dawn, with a porcelain-decorated central prang overlooking the Chao Phraya.', '1-2 hours', 'Morning', 'Take the cross-river ferry from Tha Tien and visit before the midday heat.', '', 'Bangkok', 0, 1, '', '6:00 PM', 'Adult entry THB 200; small children free', 4.9, 4.8, 13.7437, 100.4889, '158 Wang Doem Road, Wat Arun, Bangkok Yai, Bangkok 10600', 'https://www.wat-arun.com/', 0.96, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official Wat Arun visitor site checked 2026-10-01: open daily 8:00 AM-6:00 PM; adult entry THB 200; small children free.', '2026-10-01'),
('200004', '2001', 'Museum Siam', 'Museum Siam', 'Interactive museum in a restored historic building exploring Thai identity, culture, and the changing idea of “Thainess.”', '1-2 hours', 'Afternoon', 'Pair with Wat Pho and Pak Khlong Talat; it is a good air-conditioned midday stop.', '', 'Bangkok', 0, 0, '', '', 'Adults THB 100; students age 15+ THB 50; group discounts; several categories enter free', 4.4, 4.4, 13.7441, 100.4943, '4 Sanam Chai Road, Phra Nakhon, Bangkok 10200', 'https://www.museumsiam.org/museumsiam-visit.php', 0.82, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official Museum Siam visitor page checked 2026-10-01: Tue-Sun 10:00 AM-6:00 PM, closed Monday. Adult Thai/foreign THB 100; student age 15+ THB 50; under-15s and listed concession groups free.', '2026-10-01'),
('200005', '2001', 'Bangkok Art and Culture Centre', 'BACC', 'Central contemporary arts venue with rotating exhibitions, galleries, design shops, an art library, and cultural events.', '1-2 hours', 'Afternoon', 'Easy to combine with the Siam shopping district; most exhibitions are free.', '', 'Bangkok', 0, 0, '', '', 'General exhibition entry free; special events may charge', 4.4, 4.4, 13.7467, 100.5302, '939 Rama I Road, Wang Mai, Pathum Wan, Bangkok 10330', 'https://www.bacc.or.th/en', 0.81, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official BACC site checked 2026-10-01: open Tuesday-Sunday 10:00 AM-8:00 PM, closed Mondays, New Year and Songkran holidays. General admission is free except some special events.', '2026-10-01'),
('200006', '2001', 'Jim Thompson House Museum', 'Jim Thompson House', 'Traditional Thai houses displaying the Asian art collection and Bangkok home of silk entrepreneur Jim Thompson.', '1-2 hours', 'Morning', 'The main house can only be visited with a guided tour; arrive before the last tour.', 'Online ticket optional', 'Bangkok', 0, 0, '', '', 'Adults THB 250; ages 10-21 THB 150; children 0-9 free', 4.6, 4.5, 13.7492, 100.5283, '6 Soi Kasemsan 2, Rama I Road, Bangkok 10330', 'https://jimthompsonhouse.org/', 0.86, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'mid', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official Jim Thompson House visitor page checked 2026-10-01: open daily 10:00 AM-5:00 PM; last guided tour 5:00 PM. Adults THB 250; ages 10-21 THB 150; children 0-9 free.', '2026-10-01'),
('200007', '2001', 'Chatuchak Weekend Market', 'Chatuchak Market', 'Huge weekend market with thousands of stalls selling fashion, antiques, crafts, plants, food, and home goods.', '3-5 hours', 'Morning', 'Go early on Saturday or Sunday for the full market and lower heat; sections have different weekday schedules.', '', 'Bangkok', 0, 0, '', '', 'Free entry; purchases priced by vendor', 4.7, 4.5, 13.7999, 100.5501, 'Kamphaeng Phet 2 Road, Chatuchak, Bangkok 10900', 'https://www.chatuchakmarket.org/', 0.9, '2026-10-01 16:22:00', NULL, 'attraction', 'Street Food', 'budget', 'veg-options', 'own', '2026-10-01 16:22:00', 'partial', 'Dedicated Chatuchak Market site checked 2026-10-01: Wed-Thu plant section 7 AM-6 PM; Fri wholesale 6 PM-midnight; Sat-Sun full market 9 AM-6 PM. This is not a Bangkok government site, so verification is marked partial.', '2026-10-01'),
('200008', '2001', 'Lumphini Park', 'Lumphini Park', 'Bangkok’s major central green space with lakes, walking and running paths, lawns, recreation facilities, and resident monitor lizards.', '1-2 hours', 'Early Morning', 'Visit early morning or after 5 PM for cooler weather and local exercise culture.', '', 'Bangkok', 1, 1, '6:00 AM', '6:00 PM', 'Free entry', 4.5, 4.5, 13.7303, 100.5417, 'Rama IV Road, Pathum Wan, Bangkok', 'https://invest.bangkok.go.th/park/', 0.83, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Bangkok Metropolitan Administration Invest Bangkok park page checked 2026-10-01: Lumphini Park opens daily 4:30 AM-9:00 PM. Public park; no entry fee listed.', '2026-10-01'),
('200009', '2001', 'Bangkok National Museum', 'National Museum Bangkok', 'Thailand’s principal national museum, with royal, archaeological, religious, and decorative arts collections near Sanam Luang.', '2-3 hours', 'Morning', 'Give the Thai history galleries at least two hours; check special-holiday openings before going.', '', 'Bangkok', 0, 0, '', '', 'Thai THB 30; foreign visitor THB 200', 4.6, 4.5, 13.7576, 100.4925, '4 Na Phra That Road, Phra Borom Maha Ratchawang, Bangkok 10200', 'https://www.finearts.go.th/museumbangkok', 0.86, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Fine Arts Department pages checked 2026-10-01: regular schedule Wed-Sun 8:30 AM-4:00 PM, closed Monday-Tuesday, with selected public-holiday openings. Fine Arts fee schedule lists Bangkok National Museum at THB 30 Thai / THB 200 foreign.', '2026-10-01'),
('200010', '2001', 'Wat Traimit Withayaram Worawihan', 'Wat Traimit / Golden Buddha', 'Temple at the edge of Chinatown housing the celebrated solid-gold Buddha image and a museum on Yaowarat’s history.', '1-2 hours', 'Morning', 'Visit before exploring Yaowarat; the Golden Buddha and Yaowarat history centre have separate admission.', '', 'Bangkok', 0, 0, '', '', 'Golden Buddha: foreign visitor THB 40; Yaowarat Chinatown Heritage Center: foreign visitor THB 100; Thai visitors free per TAT', 4.6, 4.5, 13.7377, 100.5139, '661 Charoen Krung Road, Talat Noi, Samphanthawong, Bangkok 10100', 'https://thai.tourismthailand.org/Attraction/%E0%B8%A7%E0%B8%B1%E0%B8%94%E0%B9%84%E0%B8%95%E0%B8%A3%E0%B8%A1%E0%B8%B4%E0%B8%95%E0%B8%A3%E0%B8%A7%E0%B8%B4%E0%B8%97%E0%B8%A2%E0%B8%B2%E0%B8%A3%E0%B8%B2%E0%B8%A1', 0.84, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Tourism Authority of Thailand page checked 2026-10-01: Golden Buddha area open daily 8:00 AM-5:00 PM; foreign admission THB 40. Yaowarat history centre Tue-Sun 8:00 AM-5:00 PM, closed Monday; foreign admission THB 100.', '2026-10-01'),
('200011', '2001', 'Wat Saket (The Golden Mount)', 'Golden Mount', 'Historic temple crowned by the Golden Mount, a man-made hill with a chedi and broad views over old Bangkok.', '1-2 hours', 'Morning', 'Climb early or late in the day; the exposed upper terraces get hot at midday.', '', 'Bangkok', 0, 1, '', '6:00 PM', 'Foreign visitor admission THB 100; Thai visitors free per TAT', 4.6, 4.5, 13.7539, 100.5065, '344 Chakkraphatdi Phong Road, Ban Bat, Pom Prap Sattru Phai, Bangkok 10100', 'https://thai.tourismthailand.org/Attraction/%E0%B8%A7%E0%B8%B1%E0%B8%94%E0%B8%AA%E0%B8%A3%E0%B8%B0%E0%B9%80%E0%B8%81%E0%B8%A8-%E0%B8%A3%E0%B8%B2%E0%B8%8A%E0%B8%A7%E0%B8%A3%E0%B8%A1%E0%B8%AB%E0%B8%B2%E0%B8%A7%E0%B8%B4%E0%B8%AB%E0%B8%B2%E0%B8%A3-%E0%B8%A7%E0%B8%B1%E0%B8%94%E0%B8%A0%E0%B8%B9%E0%B9%80%E0%B8%82%E0%B8%B2%E0%B8%97%E0%B8%AD%E0%B8%87', 0.85, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'partial', 'Tourism Authority of Thailand page checked 2026-10-01 confirms foreign admission THB 100. The fetched official tourism page did not expose a reliable current daily schedule; seed uses 8:00 AM-5:00 PM as a provisional travel-planning window and flags hours unverified.', '2026-10-01'),
('200012', '2001', 'Pak Khlong Talat', 'Pak Khlong Talat Flower Market', 'Bangkok’s famous wholesale flower market, busiest before dawn with orchids, garlands, roses, fruit, and vegetables.', '1 hour', 'Early Morning', 'For the strongest market atmosphere, go around 5-8 AM when deliveries and garland-making are active.', '', 'Bangkok', 1, 0, '6:00 AM', '', 'Free entry', 4.5, 4.5, 13.7431, 100.4961, 'Chak Phet Road, Wang Burapha Phirom, Phra Nakhon, Bangkok', 'https://www.tourismthailand.org/Attraction/pak-khlong-talat-night-market', 0.82, '2026-10-01 16:22:00', NULL, 'attraction', 'Street Food', 'budget', 'veg-options', 'own', '2026-10-01 16:22:00', 'verified', 'Thailand AM2026 government visitor page checked 2026-10-01 lists Pak Khlong Talat open daily 24 hours, free entry, and busiest around 4-8 AM. Tourism Authority of Thailand also lists the market as a Bangkok attraction.', '2026-10-01'),
('200013', '2001', 'Erawan Shrine', 'Thao Maha Phrom Shrine', 'Open-air Brahma shrine at Ratchaprasong, known for continuous worship, flower offerings, and traditional dance offerings.', '30-45 minutes', 'Evening', 'Be respectful of active worshippers and buy offerings only from established stalls at the shrine.', '', 'Bangkok', 0, 0, '', '', 'Free admission; offerings extra', 4.4, 4.3, 13.7443, 100.5397, 'Ratchaprasong Intersection, Ratchadamri Road, Lumphini, Pathum Wan, Bangkok 10330', '', 0.78, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'budget', 'na', 'own', '2026-10-01 16:22:00', 'partial', 'Current Erawan Shrine visitor guide checked 2026-10-01 lists daily 6:00 AM-10:00 PM and free admission. Because the fetched site describes itself as an educational/devotional guide rather than clearly as the managing foundation website, status is partial.', '2026-10-01'),
('200014', '2001', 'Mahanakhon SkyWalk', 'King Power Mahanakhon SkyWalk', 'Indoor and rooftop observation decks in King Power Mahanakhon with a glass tray and 360-degree Bangkok skyline views.', '1-2 hours', 'Sunset', 'Book a sunset slot in advance and check weather because the outdoor deck can close temporarily.', 'Advance booking recommended', 'Bangkok', 0, 1, '', '6:00 PM', 'Adult THB 1,000 daytime / THB 1,200 sunset; child/senior THB 500-600 on current official ticket information', 4.7, 4.5, 13.7237, 100.5285, '114 Narathiwas Ratchanakarin Road, Silom, Bang Rak, Bangkok', 'https://www.kingpowermahanakhon.co.th/', 0.89, '2026-10-01 16:22:00', NULL, 'attraction', NULL, 'premium', 'na', 'own', '2026-10-01 16:22:00', 'verified', 'Official King Power Mahanakhon pages checked 2026-10-01: SkyWalk open daily 10:00 AM-midnight, last access 11:00 PM. Current official ticket information lists adult THB 1,000 daytime / THB 1,200 sunset, with child/senior reductions; prices can vary by time/package.', '2026-10-01'),
('200015', '2001', 'ICONSIAM', 'ICONSIAM', 'Large Chao Phraya riverside shopping, dining, culture, craft, and entertainment complex with SOOKSIAM and River Park.', '2-4 hours', 'Evening', 'Arrive before sunset, explore SOOKSIAM for regional food, then walk the riverfront after dark.', '', 'Bangkok', 0, 1, '', '6:00 PM', 'Free entry; shopping, dining and attractions extra', 4.5, 4.4, 13.7265, 100.5102, '299 Charoen Nakhon Soi 5, Khlong Ton Sai, Khlong San, Bangkok 10600', 'https://www.iconsiam.com/en', 0.84, '2026-10-01 16:22:00', NULL, 'attraction', 'Thai / International', 'mid', 'veg-options', 'own', '2026-10-01 16:22:00', 'partial', 'Official ICONSIAM site confirms the address and attraction/dining complex. Tourism Authority of Thailand material and current ICONSIAM tenant directory consistently show 10:00 AM-10:00 PM daily; overall mall hours were not plainly exposed on the fetched homepage, so status is partial.', '2026-10-01'),
('200016', '2001', 'Asiatique The Riverfront', 'Asiatique', 'Chao Phraya riverfront retail and dining destination combining restored warehouse architecture, restaurants, entertainment, and a long riverside promenade.', '2-3 hours', 'Evening', 'Use the free shuttle boat from Sathorn Pier in the late afternoon and stay through the evening.', '', 'Bangkok', 0, 1, '', '6:00 PM', 'Free entry; rides, dining and events extra', 4.4, 4.3, 13.7046, 100.5038, '2194 Charoen Krung Road, Wat Phraya Krai, Bang Kho Laem, Bangkok 10120', 'https://www.asiatiquethailand.com/', 0.81, '2026-10-01 16:22:00', NULL, 'attraction', 'Thai / International', 'mid', 'veg-options', 'own', '2026-10-01 16:22:00', 'verified', 'Official Asiatique site checked 2026-10-01: destination open daily 11:00 AM-midnight. Free shuttle boat from Sathorn operates 4:00 PM-11:30 PM every 25-30 minutes. General entry fee is not listed.', '2026-10-01'),
('200017', '2001', 'Somboon Seafood - Surawong', 'Somboon Seafood Surawong', 'Flagship Bangkok seafood restaurant best known for its fried curry crab and large Thai-Chinese seafood menu.', '1-2 hours', 'Evening', 'Reserve for dinner and make sure you go to the official Surawong branch rather than lookalike restaurants.', 'Dinner reservation recommended', 'Bangkok', 0, 0, '', '', 'Paid; seafood priced by dish/weight', 4.6, 4.4, 13.7288, 100.531, '169, 169/7-12 Surawong Road, Suriyawong, Bang Rak, Bangkok 10500', 'https://www.somboonseafood.com/en/location', 0.83, '2026-10-01 16:22:00', NULL, 'restaurant', 'Thai-Chinese Seafood', 'mid', 'veg-options', 'own', '2026-10-01 16:22:00', 'verified', 'Official Somboon Seafood location page checked 2026-10-01: Surawong opens 11:00 AM, last order 9:30 PM, closes 10:00 PM daily. Official site states the chain operates eight Bangkok branches.', '2026-10-01'),
('200018', '2001', 'Baan Somtum Sathorn', 'Baan Somtum Sathorn', 'Popular Isaan restaurant specializing in som tam, spicy salads, grilled meats, sticky rice, and northeastern Thai dishes.', '1-2 hours', 'Evening', 'Order several dishes to share and specify your preferred spice level clearly.', 'Dinner reservation recommended', 'Bangkok', 0, 0, '', '', 'Paid; mid-range', 4.5, 4.4, 13.7178, 100.5216, '9/1 Pramuan Road, Silom, Bang Rak, Bangkok 10500', 'https://baansomtum.com/en/branches/', 0.8, '2026-10-01 16:22:00', NULL, 'restaurant', 'Isaan / Northeastern Thai', 'mid', 'veg-options', 'own', '2026-10-01 16:22:00', 'verified', 'Official Baan Somtum branch page checked 2026-10-01: Sathorn branch open daily 11:00 AM-10:00 PM, last order 9:30 PM.', '2026-10-01'),
('200019', '2001', 'Thipsamai Padthai Pratoopee', 'Thipsamai', 'Long-running Bangkok pad thai specialist on Maha Chai Road, famous for egg-wrapped prawn pad thai and orange juice.', '45-60 minutes', 'Evening', 'Expect queues at peak times; arrive before the dinner rush if your itinerary is tight.', '', 'Bangkok', 0, 0, '', '', 'Paid; budget-to-mid range', 4.5, 4.3, 13.7533, 100.5048, '313-315 Maha Chai Road, Samran Rat, Phra Nakhon, Bangkok 10200', '', 0.79, '2026-10-01 16:22:00', NULL, 'restaurant', 'Thai / Pad Thai', 'budget', 'veg-options', 'own', '2026-10-01 16:22:00', 'partial', 'Current local business listing checked 2026-10-01: flagship listed 9:00 AM-midnight on operating days and closed Tuesday. No clearly authoritative official branch-hours page was captured in this pass, so status is partial and hours should be rechecked before publication.', '2026-10-01'),
('200020', '2001', 'Raan Jay Fai', 'Jay Fai', 'Famous Bangkok street-food restaurant centered on premium seafood wok dishes, especially its crab omelette.', '1-2 hours', 'Lunch', 'Bring cash, arrive early, and expect variable waits; operating days are limited.', 'Reservation/wait-list planning recommended', 'Bangkok', 0, 0, '', '', 'Paid; premium street-food pricing', 4.7, 4.3, 13.7525, 100.5045, '327 Maha Chai Road, Samran Rat, Phra Nakhon, Bangkok 10200', '', 0.82, '2026-10-01 16:22:00', NULL, 'restaurant', 'Thai Seafood / Street Food', 'premium', 'veg-options', 'own', '2026-10-01 16:22:00', 'partial', 'Current local business listing checked 2026-10-01 shows Wed-Sat 9:00 AM-7:30 PM and closed Sun-Tue. Because no official restaurant website with current hours was captured, mark partial and reconfirm before publishing.', '2026-10-01');

-- ---- HOURS: Bangkok ----
INSERT INTO opening_hours (id, place_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, notes) VALUES
('200001', '200001', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', '8:30 AM - 4:30 PM', 'Ticket sales end 3:30 PM; royal ceremonies can affect access. [verified: royalgrandpalace.th] '),
('200002', '200002', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', '8:00 AM - 7:30 PM', 'Official Wat Pho pages conflict on opening: 8:00 vs 8:30 AM; closing 7:30 PM consistent. [partial: watpho.com]'),
('200003', '200003', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', '8:00 AM - 6:00 PM', 'Daily. [verified: wat-arun.com]'),
('200004', '200004', 'Closed', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', '10:00 AM - 6:00 PM', 'Closed Mondays. [verified: museumsiam.org]'),
('200005', '200005', 'Closed', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', '10:00 AM - 8:00 PM', 'Closed Mondays plus New Year and Songkran holidays. [verified: bacc.or.th]'),
('200006', '200006', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', '10:00 AM - 5:00 PM', 'Last guided tour 5:00 PM; main house requires a guide. [verified: jimthompsonhouse.org]'),
('200007', '200007', 'Closed', 'Closed', '7:00 AM - 6:00 PM (plant section)', '7:00 AM - 6:00 PM (plant section)', '6:00 PM - 12:00 AM (wholesale)', '9:00 AM - 6:00 PM', '9:00 AM - 6:00 PM', 'Different sections operate on different days; full market Sat-Sun. [partial: chatuchakmarket.org]'),
('200008', '200008', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', '4:30 AM - 9:00 PM', 'Daily. [verified: Bangkok Metropolitan Administration / invest.bangkok.go.th]'),
('200009', '200009', 'Closed', 'Closed', '8:30 AM - 4:00 PM', '8:30 AM - 4:00 PM', '8:30 AM - 4:00 PM', '8:30 AM - 4:00 PM', '8:30 AM - 4:00 PM', 'Regular schedule; selected public holidays may open specially. [verified: Fine Arts Department]'),
('200010', '200010', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', 'Golden Buddha area daily; Yaowarat history centre is closed Monday. [verified: Tourism Authority of Thailand]'),
('200011', '200011', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', '8:00 AM - 5:00 PM', 'Provisional planning window; fee verified but current daily hours were not exposed in fetched TAT page. [hours unverified - confirm before use]'),
('200012', '200012', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', '24 hours', 'Market operates 24 hours; strongest wholesale flower activity roughly 4-8 AM. [verified: Thailand AM2026 visitor page]'),
('200013', '200013', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', '6:00 AM - 10:00 PM', 'Daily per current shrine visitor guide; managing-foundation ownership of the site not confirmed in this pass. [partial]'),
('200014', '200014', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', '10:00 AM - 12:00 AM', 'Last access 11:00 PM; outdoor deck subject to weather closure. [verified: kingpowermahanakhon.co.th]'),
('200015', '200015', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', '10:00 AM - 10:00 PM', 'Hours corroborated by TAT material and current ICONSIAM directory; overall hours not prominent on fetched homepage. [partial]'),
('200016', '200016', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', '11:00 AM - 12:00 AM', 'Free shuttle boat from Sathorn 4:00 PM-11:30 PM. [verified: asiatiquethailand.com]'),
('200017', '200017', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', 'Last order 9:30 PM. [verified: somboonseafood.com]'),
('200018', '200018', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', '11:00 AM - 10:00 PM', 'Last order 9:30 PM. [verified: baansomtum.com]'),
('200019', '200019', '9:00 AM - 12:00 AM', 'Closed', '9:00 AM - 12:00 AM', '9:00 AM - 12:00 AM', '9:00 AM - 12:00 AM', '9:00 AM - 12:00 AM', '9:00 AM - 12:00 AM', 'Current listing; official branch page not captured. [hours partial - confirm before use]'),
('200020', '200020', 'Closed', 'Closed', '9:00 AM - 7:30 PM', '9:00 AM - 7:30 PM', '9:00 AM - 7:30 PM', '9:00 AM - 7:30 PM', 'Closed', 'Current listing only; official restaurant page not captured. [hours partial - confirm before use]');

-- ---- PHOTOS: Bangkok (placeholder pass; licensed-image pass pending) ----
INSERT INTO photos (id, place_id, photo_title, usage_terms, thumbnail_url, photo_url, photo_author, photo_license, photo_source_url, photo_status) VALUES
('200001', '200001', 'Grand Palace', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200002', '200002', 'Wat Pho', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200003', '200003', 'Wat Arun', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200004', '200004', 'Museum Siam', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200005', '200005', 'BACC', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200006', '200006', 'Jim Thompson House', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200007', '200007', 'Chatuchak Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200008', '200008', 'Lumphini Park', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200009', '200009', 'National Museum Bangkok', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200010', '200010', 'Wat Traimit / Golden Buddha', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200011', '200011', 'Golden Mount', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200012', '200012', 'Pak Khlong Talat Flower Market', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200013', '200013', 'Thao Maha Phrom Shrine', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200014', '200014', 'King Power Mahanakhon SkyWalk', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200015', '200015', 'ICONSIAM', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200016', '200016', 'Asiatique', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200017', '200017', 'Somboon Seafood Surawong', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200018', '200018', 'Baan Somtum Sathorn', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200019', '200019', 'Thipsamai', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match'),
('200020', '200020', 'Jay Fai', 'no-photo-available', NULL, NULL, NULL, NULL, NULL, 'no_match');

-- ---- PLACE TAGS: Bangkok ----
INSERT INTO place_tags (place_id, tag_id) SELECT 200001, id FROM tags WHERE tag_name IN ('Heritage', 'Palace', 'Religious', 'Temple');
INSERT INTO place_tags (place_id, tag_id) SELECT 200002, id FROM tags WHERE tag_name IN ('Heritage', 'Religious', 'Temple');
INSERT INTO place_tags (place_id, tag_id) SELECT 200003, id FROM tags WHERE tag_name IN ('Heritage', 'Religious', 'Temple', 'River', 'Photography');
INSERT INTO place_tags (place_id, tag_id) SELECT 200004, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 200005, id FROM tags WHERE tag_name IN ('Art', 'Museum', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 200006, id FROM tags WHERE tag_name IN ('Museum', 'Heritage', 'Art');
INSERT INTO place_tags (place_id, tag_id) SELECT 200007, id FROM tags WHERE tag_name IN ('Market', 'Shopping', 'Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 200008, id FROM tags WHERE tag_name IN ('Park', 'Nature', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 200009, id FROM tags WHERE tag_name IN ('Museum', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 200010, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 200011, id FROM tags WHERE tag_name IN ('Temple', 'Religious', 'Viewpoint', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 200012, id FROM tags WHERE tag_name IN ('Market', 'Photography', 'Shopping');
INSERT INTO place_tags (place_id, tag_id) SELECT 200013, id FROM tags WHERE tag_name IN ('Religious', 'Heritage');
INSERT INTO place_tags (place_id, tag_id) SELECT 200014, id FROM tags WHERE tag_name IN ('Viewpoint', 'Photography', 'Family');
INSERT INTO place_tags (place_id, tag_id) SELECT 200015, id FROM tags WHERE tag_name IN ('Shopping', 'Food', 'Family', 'River');
INSERT INTO place_tags (place_id, tag_id) SELECT 200016, id FROM tags WHERE tag_name IN ('Shopping', 'Food', 'Family', 'River');
INSERT INTO place_tags (place_id, tag_id) SELECT 200017, id FROM tags WHERE tag_name IN ('Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 200018, id FROM tags WHERE tag_name IN ('Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 200019, id FROM tags WHERE tag_name IN ('Food', 'Street Food');
INSERT INTO place_tags (place_id, tag_id) SELECT 200020, id FROM tags WHERE tag_name IN ('Food', 'Street Food');

-- ============================================================================
-- FESTIVALS: Bangkok starter rows
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
(300001, 9001, 2001, NULL, 'Songkran in Bangkok', '13-15 April', 'Solar-calendar national holiday period; local programming varies yearly', '3 days', 'Bangkok-wide Thai New Year water festival and cultural celebrations; exact road closures and event zones should be refreshed annually.', 'own', '2026-10-01 16:22:00'),
(300002, 9001, 2001, NULL, 'Loy Krathong in Bangkok', 'November', 'Full moon of the 12th Thai lunar month; date shifts yearly', '1 evening', 'Krathong-floating celebrations take place at riverfronts, canals, parks and event venues across Bangkok.', 'own', '2026-10-01 16:22:00'),
(300003, 9001, 2001, 200010, 'Chinese New Year in Yaowarat', 'January-February', 'Lunar calendar; date shifts yearly', '1-3 days', 'Yaowarat/Chinatown hosts decorations, performances and celebrations around Lunar New Year.', 'own', '2026-10-01 16:22:00');

-- ============================================================================
-- NEXT PASS
-- Expand city 2002 Phuket, then Chiang Mai, Pattaya, Krabi and Ko Samui.
-- Perform a separate licensed-photo verification pass.
-- Reconcile reserved province IDs 9001-9010 with the production states table.
--
-- PHASE 1 COUNTS
-- 10 city scaffold rows
-- 20 Bangkok places
-- 20 Bangkok opening_hours rows
-- 20 photo placeholder rows
-- 20 place_tag mapping statements
-- 3 Bangkok festival rows
-- ============================================================================
-- END OF THAILAND PHASE 1 SEED
-- ============================================================================
