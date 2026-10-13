-- TripRaft Countries Master | 190 source IDs/names preserved exactly
-- Prepared: 2026-10-09 | SQLite 3.x | UTF-8 | Re-runnable upsert
-- Source of numeric IDs & names: supplied canonical sql_database/Old export (190 rows).
-- Source framework: ISO 3166-1 / UN M49, ISO 4217/CLDR, ITU E.164, and
-- government/central-bank verification of 2026 updates. Source URLs follow below.
-- WARNING: Review a backup before importing into an existing live DB.
--
-- IMPORTANT FIELD SEMANTICS:
-- iso_numeric: 3-digit TEXT, including leading zeros. It is NOT the TripRaft id.
-- iso2/iso3: only officially assigned ISO 3166-1 codes; Kosovo has NULL for
--   all ISO fields because XK/XKX are practical user-assigned codes, not ISO.
-- currency_code: one primary ISO 4217 code per record; several destinations
--   also use other currencies (see notes below).
-- calling_code: ITU E.164 country dialling code with +, NOT an area code.
--   NANP countries share +1 and must additionally dial their local area code.
-- capital: administrative/government seat for multi-seat cases, or NULL if
--   there is no formally designated separate capital (Hong Kong, Macao, Nauru).
-- region: broad continental/UN-style category (Africa, Americas, Asia,
--   Europe, Oceania); transcontinental states placed in one category.
-- updated_at: populated with actual import date; created_at & retired_at for
--   existing rows are preserved. New rows default created_at; retired_at NULL.
--
-- VERIFIED SPECIAL CASES (as at 2026-10-09):
-- * Bulgaria: EUR since 2026-01-01 (no longer BGN).
-- * Equatorial Guinea: Ciudad de la Paz replaced Malabo as capital in Jan 2026.
-- * Burundi: Gitega is political capital; Bujumbura is economic capital.
-- * Eswatini: Mbabane administrative; Lobamba royal/legislative.
-- * South Africa: Pretoria administrative; Cape Town legislative;
--   Bloemfontein judicial.
-- * Bolivia: Sucre constitutional capital; La Paz seat of government.
-- * Netherlands: Amsterdam constitutional capital; The Hague government seat.
-- * Sri Lanka: Sri Jayawardenepura Kotte legislative capital; Colombo major
--   executive/commercial centre.
-- * Palestine: Ramallah administrative seat; East Jerusalem is claimed as
--   capital. Uses ILS widely alongside JOD and other currencies. ITU has
--   assigned +970; its implementation has involved a gradual transition.
-- * Panama: PAB national monetary unit; USD also legal tender.
-- * Bhutan: BTN national currency; INR is also legal tender.
-- * Namibia: NAD national currency; ZAR also legal tender.
-- * Lesotho: LSL national currency; ZAR also legal tender.
-- * Zimbabwe: ZWG (Zimbabwe Gold/ZiG) as primary local code; USD also used.
-- * Vatican City: +39 is operational for Vatican phone numbers; assigned
--   +379 is generally unused.
-- * Nauru: no official capital; government offices located in Yaren District.
-- * Hong Kong and Macao: PRC special administrative regions; no separate
--   legally designated national capitals.
-- * Indonesia: Jakarta remains recorded pending full transfer to Nusantara.
--
-- REFERENCE LINKS:
-- https://www.iso.org/iso-3166-country-codes.html
-- https://op.europa.eu/en/web/eu-vocabularies/countries-and-territories
-- https://www.itu.int/oth/t0202/en
-- https://www.ecb.europa.eu/press/pr/date/2026/html/ecb.pr260101~c830245e42.en.html
-- https://www.guineaecuatorialpress.com/index.php/noticias/el_presidente_de_la_republica_proclama_la_ciudad_de_la_paz_como_capital_de_la_republica_de_guinea_ecuatorial_con_la_firma_de_un_decreto_ley
-- https://presidence.gov.bi/le-pays/
-- https://www.gov.za/about-sa/south-africas-provinces
-- https://www.un.int/eswatini/swaziland/country-facts
-- https://www.consilium.europa.eu/prado/en/prado-documents/XKX/index.html
-- https://www.ituob.org/issues/1252-en/
-- https://mfa.gov.ua/en/correctua
-- https://www.reuters.com/world/africa/zimbabwe-central-bank-maintains-policy-rate-anchor-inflation-2026-02-27/
--
PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE TRANSACTION;

CREATE TABLE IF NOT EXISTS countries (
    id           INTEGER PRIMARY KEY,
    country_name TEXT NOT NULL,
    created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d','now')),
    iso2         TEXT UNIQUE CHECK (iso2 IS NULL OR (length(iso2)=2 AND iso2=upper(iso2))),
    iso3         TEXT UNIQUE CHECK (iso3 IS NULL OR (length(iso3)=3 AND iso3=upper(iso3))),
    iso_numeric  TEXT UNIQUE,
    currency_code TEXT,
    calling_code TEXT,
    capital TEXT,
    region TEXT,
    updated_at TEXT,
    retired_at TEXT,
    UNIQUE (country_name)
);

-- Stage first to prevent silently overwriting pre-existing country identities.
DROP TABLE IF EXISTS temp._tripraft_countries_stage;
CREATE TEMP TABLE _tripraft_countries_stage (
    id INTEGER NOT NULL PRIMARY KEY,
    country_name TEXT NOT NULL UNIQUE,
    iso2 TEXT UNIQUE,
    iso3 TEXT UNIQUE,
    iso_numeric TEXT UNIQUE,
    currency_code TEXT,
    calling_code TEXT,
    capital TEXT,
    region TEXT
);

INSERT INTO _tripraft_countries_stage
    (id,country_name,iso2,iso3,iso_numeric,currency_code,calling_code,capital,region)
VALUES
    (515987, 'Afghanistan', 'AF', 'AFG', '004', 'AFN', '+93', 'Kabul', 'Asia'),
    (982229, 'Albania', 'AL', 'ALB', '008', 'ALL', '+355', 'Tirana', 'Europe'),
    (905258, 'Algeria', 'DZ', 'DZA', '012', 'DZD', '+213', 'Algiers', 'Africa'),
    (284865, 'Andorra', 'AD', 'AND', '020', 'EUR', '+376', 'Andorra la Vella', 'Europe'),
    (645553, 'Angola', 'AO', 'AGO', '024', 'AOA', '+244', 'Luanda', 'Africa'),
    (952210, 'Antigua and Barbuda', 'AG', 'ATG', '028', 'XCD', '+1', 'Saint John''s', 'Americas'),
    (978019, 'Argentina', 'AR', 'ARG', '032', 'ARS', '+54', 'Buenos Aires', 'Americas'),
    (141872, 'Armenia', 'AM', 'ARM', '051', 'AMD', '+374', 'Yerevan', 'Asia'),
    (814786, 'Australia', 'AU', 'AUS', '036', 'AUD', '+61', 'Canberra', 'Oceania'),
    (221478, 'Austria', 'AT', 'AUT', '040', 'EUR', '+43', 'Vienna', 'Europe'),
    (608898, 'Azerbaijan', 'AZ', 'AZE', '031', 'AZN', '+994', 'Baku', 'Asia'),
    (329213, 'Bahamas', 'BS', 'BHS', '044', 'BSD', '+1', 'Nassau', 'Americas'),
    (493695, 'Bahrain', 'BH', 'BHR', '048', 'BHD', '+973', 'Manama', 'Asia'),
    (424620, 'Barbados', 'BB', 'BRB', '052', 'BBD', '+1', 'Bridgetown', 'Americas'),
    (551522, 'Belarus', 'BY', 'BLR', '112', 'BYN', '+375', 'Minsk', 'Europe'),
    (284021, 'Belgium', 'BE', 'BEL', '056', 'EUR', '+32', 'Brussels', 'Europe'),
    (953161, 'Belize', 'BZ', 'BLZ', '084', 'BZD', '+501', 'Belmopan', 'Americas'),
    (195153, 'Benin', 'BJ', 'BEN', '204', 'XOF', '+229', 'Porto-Novo', 'Africa'),
    (128663, 'Bhutan', 'BT', 'BTN', '064', 'BTN', '+975', 'Thimphu', 'Asia'),
    (218823, 'Bolivia', 'BO', 'BOL', '068', 'BOB', '+591', 'Sucre', 'Americas'),
    (212647, 'Botswana', 'BW', 'BWA', '072', 'BWP', '+267', 'Gaborone', 'Africa'),
    (253913, 'Brazil', 'BR', 'BRA', '076', 'BRL', '+55', 'Brasília', 'Americas'),
    (448337, 'Brunei', 'BN', 'BRN', '096', 'BND', '+673', 'Bandar Seri Begawan', 'Asia'),
    (275342, 'Bulgaria', 'BG', 'BGR', '100', 'EUR', '+359', 'Sofia', 'Europe'),
    (675490, 'Burkina Faso', 'BF', 'BFA', '854', 'XOF', '+226', 'Ouagadougou', 'Africa'),
    (999561, 'Burundi', 'BI', 'BDI', '108', 'BIF', '+257', 'Gitega', 'Africa'),
    (348707, 'Cabo Verde', 'CV', 'CPV', '132', 'CVE', '+238', 'Praia', 'Africa'),
    (179855, 'Cambodia', 'KH', 'KHM', '116', 'KHR', '+855', 'Phnom Penh', 'Asia'),
    (322177, 'Cameroon', 'CM', 'CMR', '120', 'XAF', '+237', 'Yaoundé', 'Africa'),
    (656868, 'Canada', 'CA', 'CAN', '124', 'CAD', '+1', 'Ottawa', 'Americas'),
    (584753, 'Central African Republic', 'CF', 'CAF', '140', 'XAF', '+236', 'Bangui', 'Africa'),
    (743498, 'Chad', 'TD', 'TCD', '148', 'XAF', '+235', 'N''Djamena', 'Africa'),
    (354659, 'Chile', 'CL', 'CHL', '152', 'CLP', '+56', 'Santiago', 'Americas'),
    (635449, 'China', 'CN', 'CHN', '156', 'CNY', '+86', 'Beijing', 'Asia'),
    (178922, 'Colombia', 'CO', 'COL', '170', 'COP', '+57', 'Bogotá', 'Americas'),
    (972441, 'Comoros', 'KM', 'COM', '174', 'KMF', '+269', 'Moroni', 'Africa'),
    (909436, 'Costa Rica', 'CR', 'CRI', '188', 'CRC', '+506', 'San José', 'Americas'),
    (600025, 'Croatia', 'HR', 'HRV', '191', 'EUR', '+385', 'Zagreb', 'Europe'),
    (985059, 'Cuba', 'CU', 'CUB', '192', 'CUP', '+53', 'Havana', 'Americas'),
    (383156, 'Cyprus', 'CY', 'CYP', '196', 'EUR', '+357', 'Nicosia', 'Europe'),
    (303772, 'Czechia', 'CZ', 'CZE', '203', 'CZK', '+420', 'Prague', 'Europe'),
    (649644, 'Côte d’Ivoire', 'CI', 'CIV', '384', 'XOF', '+225', 'Yamoussoukro', 'Africa'),
    (374383, 'Democratic Republic of the Congo', 'CD', 'COD', '180', 'CDF', '+243', 'Kinshasa', 'Africa'),
    (959717, 'Denmark', 'DK', 'DNK', '208', 'DKK', '+45', 'Copenhagen', 'Europe'),
    (602400, 'Djibouti', 'DJ', 'DJI', '262', 'DJF', '+253', 'Djibouti', 'Africa'),
    (513631, 'Dominica', 'DM', 'DMA', '212', 'XCD', '+1', 'Roseau', 'Americas'),
    (992137, 'Dominican Republic', 'DO', 'DOM', '214', 'DOP', '+1', 'Santo Domingo', 'Americas'),
    (627779, 'Ecuador', 'EC', 'ECU', '218', 'USD', '+593', 'Quito', 'Americas'),
    (589692, 'Egypt', 'EG', 'EGY', '818', 'EGP', '+20', 'Cairo', 'Africa'),
    (121964, 'El Salvador', 'SV', 'SLV', '222', 'USD', '+503', 'San Salvador', 'Americas'),
    (882718, 'Equatorial Guinea', 'GQ', 'GNQ', '226', 'XAF', '+240', 'Ciudad de la Paz', 'Africa'),
    (353335, 'Eritrea', 'ER', 'ERI', '232', 'ERN', '+291', 'Asmara', 'Africa'),
    (491776, 'Estonia', 'EE', 'EST', '233', 'EUR', '+372', 'Tallinn', 'Europe'),
    (564290, 'Eswatini', 'SZ', 'SWZ', '748', 'SZL', '+268', 'Mbabane', 'Africa'),
    (626142, 'Ethiopia', 'ET', 'ETH', '231', 'ETB', '+251', 'Addis Ababa', 'Africa'),
    (146391, 'Fiji', 'FJ', 'FJI', '242', 'FJD', '+679', 'Suva', 'Oceania'),
    (605111, 'Finland', 'FI', 'FIN', '246', 'EUR', '+358', 'Helsinki', 'Europe'),
    (187629, 'France', 'FR', 'FRA', '250', 'EUR', '+33', 'Paris', 'Europe'),
    (352240, 'Gabon', 'GA', 'GAB', '266', 'XAF', '+241', 'Libreville', 'Africa'),
    (256550, 'Gambia', 'GM', 'GMB', '270', 'GMD', '+220', 'Banjul', 'Africa'),
    (506828, 'Georgia', 'GE', 'GEO', '268', 'GEL', '+995', 'Tbilisi', 'Asia'),
    (628904, 'Germany', 'DE', 'DEU', '276', 'EUR', '+49', 'Berlin', 'Europe'),
    (144257, 'Ghana', 'GH', 'GHA', '288', 'GHS', '+233', 'Accra', 'Africa'),
    (294235, 'Greece', 'GR', 'GRC', '300', 'EUR', '+30', 'Athens', 'Europe'),
    (197376, 'Grenada', 'GD', 'GRD', '308', 'XCD', '+1', 'St. George''s', 'Americas'),
    (790487, 'Guatemala', 'GT', 'GTM', '320', 'GTQ', '+502', 'Guatemala City', 'Americas'),
    (634827, 'Guinea', 'GN', 'GIN', '324', 'GNF', '+224', 'Conakry', 'Africa'),
    (957198, 'Guinea-Bissau', 'GW', 'GNB', '624', 'XOF', '+245', 'Bissau', 'Africa'),
    (536276, 'Guyana', 'GY', 'GUY', '328', 'GYD', '+592', 'Georgetown', 'Americas'),
    (402102, 'Hong Kong', 'HK', 'HKG', '344', 'HKD', '+852', NULL, 'Asia'),
    (998580, 'Hungary', 'HU', 'HUN', '348', 'HUF', '+36', 'Budapest', 'Europe'),
    (736149, 'Iceland', 'IS', 'ISL', '352', 'ISK', '+354', 'Reykjavik', 'Europe'),
    (989320, 'India', 'IN', 'IND', '356', 'INR', '+91', 'New Delhi', 'Asia'),
    (501519, 'Indonesia', 'ID', 'IDN', '360', 'IDR', '+62', 'Jakarta', 'Asia'),
    (482179, 'Iran', 'IR', 'IRN', '364', 'IRR', '+98', 'Tehran', 'Asia'),
    (566685, 'Iraq', 'IQ', 'IRQ', '368', 'IQD', '+964', 'Baghdad', 'Asia'),
    (715287, 'Ireland', 'IE', 'IRL', '372', 'EUR', '+353', 'Dublin', 'Europe'),
    (293886, 'Israel', 'IL', 'ISR', '376', 'ILS', '+972', 'Jerusalem', 'Asia'),
    (552384, 'Italy', 'IT', 'ITA', '380', 'EUR', '+39', 'Rome', 'Europe'),
    (807103, 'Japan', 'JP', 'JPN', '392', 'JPY', '+81', 'Tokyo', 'Asia'),
    (605953, 'Jordan', 'JO', 'JOR', '400', 'JOD', '+962', 'Amman', 'Asia'),
    (803420, 'Kazakhstan', 'KZ', 'KAZ', '398', 'KZT', '+7', 'Astana', 'Asia'),
    (537115, 'Kenya', 'KE', 'KEN', '404', 'KES', '+254', 'Nairobi', 'Africa'),
    (147808, 'Kiribati', 'KI', 'KIR', '296', 'AUD', '+686', 'South Tarawa', 'Oceania'),
    (638989, 'Kosovo', NULL, NULL, NULL, 'EUR', '+383', 'Pristina', 'Europe'),
    (167290, 'Kuwait', 'KW', 'KWT', '414', 'KWD', '+965', 'Kuwait City', 'Asia'),
    (972188, 'Kyrgyzstan', 'KG', 'KGZ', '417', 'KGS', '+996', 'Bishkek', 'Asia'),
    (271671, 'Laos', 'LA', 'LAO', '418', 'LAK', '+856', 'Vientiane', 'Asia'),
    (646972, 'Latvia', 'LV', 'LVA', '428', 'EUR', '+371', 'Riga', 'Europe'),
    (864727, 'Lebanon', 'LB', 'LBN', '422', 'LBP', '+961', 'Beirut', 'Asia'),
    (215374, 'Lesotho', 'LS', 'LSO', '426', 'LSL', '+266', 'Maseru', 'Africa'),
    (130596, 'Liberia', 'LR', 'LBR', '430', 'LRD', '+231', 'Monrovia', 'Africa'),
    (362764, 'Libya', 'LY', 'LBY', '434', 'LYD', '+218', 'Tripoli', 'Africa'),
    (731401, 'Liechtenstein', 'LI', 'LIE', '438', 'CHF', '+423', 'Vaduz', 'Europe'),
    (861242, 'Lithuania', 'LT', 'LTU', '440', 'EUR', '+370', 'Vilnius', 'Europe'),
    (165061, 'Luxembourg', 'LU', 'LUX', '442', 'EUR', '+352', 'Luxembourg', 'Europe'),
    (533050, 'Macao', 'MO', 'MAC', '446', 'MOP', '+853', NULL, 'Asia'),
    (120307, 'Madagascar', 'MG', 'MDG', '450', 'MGA', '+261', 'Antananarivo', 'Africa'),
    (214937, 'Malawi', 'MW', 'MWI', '454', 'MWK', '+265', 'Lilongwe', 'Africa'),
    (411451, 'Malaysia', 'MY', 'MYS', '458', 'MYR', '+60', 'Kuala Lumpur', 'Asia'),
    (301393, 'Maldives', 'MV', 'MDV', '462', 'MVR', '+960', 'Malé', 'Asia'),
    (421978, 'Mali', 'ML', 'MLI', '466', 'XOF', '+223', 'Bamako', 'Africa'),
    (426579, 'Malta', 'MT', 'MLT', '470', 'EUR', '+356', 'Valletta', 'Europe'),
    (462204, 'Marshall Islands', 'MH', 'MHL', '584', 'USD', '+692', 'Majuro', 'Oceania'),
    (129429, 'Mauritania', 'MR', 'MRT', '478', 'MRU', '+222', 'Nouakchott', 'Africa'),
    (442122, 'Mauritius', 'MU', 'MUS', '480', 'MUR', '+230', 'Port Louis', 'Africa'),
    (823384, 'Micronesia', 'FM', 'FSM', '583', 'USD', '+691', 'Palikir', 'Oceania'),
    (936809, 'Moldova', 'MD', 'MDA', '498', 'MDL', '+373', 'Chișinău', 'Europe'),
    (757759, 'Monaco', 'MC', 'MCO', '492', 'EUR', '+377', 'Monaco', 'Europe'),
    (197505, 'Mongolia', 'MN', 'MNG', '496', 'MNT', '+976', 'Ulaanbaatar', 'Asia'),
    (649270, 'Montenegro', 'ME', 'MNE', '499', 'EUR', '+382', 'Podgorica', 'Europe'),
    (430450, 'Morocco', 'MA', 'MAR', '504', 'MAD', '+212', 'Rabat', 'Africa'),
    (892486, 'Mozambique', 'MZ', 'MOZ', '508', 'MZN', '+258', 'Maputo', 'Africa'),
    (406288, 'Myanmar', 'MM', 'MMR', '104', 'MMK', '+95', 'Naypyidaw', 'Asia'),
    (101429, 'Namibia', 'NA', 'NAM', '516', 'NAD', '+264', 'Windhoek', 'Africa'),
    (837260, 'Nauru', 'NR', 'NRU', '520', 'AUD', '+674', NULL, 'Oceania'),
    (102337, 'Nepal', 'NP', 'NPL', '524', 'NPR', '+977', 'Kathmandu', 'Asia'),
    (694437, 'Netherlands', 'NL', 'NLD', '528', 'EUR', '+31', 'Amsterdam', 'Europe'),
    (452292, 'New Zealand', 'NZ', 'NZL', '554', 'NZD', '+64', 'Wellington', 'Oceania'),
    (788978, 'Niger', 'NE', 'NER', '562', 'XOF', '+227', 'Niamey', 'Africa'),
    (729515, 'Nigeria', 'NG', 'NGA', '566', 'NGN', '+234', 'Abuja', 'Africa'),
    (747811, 'North Korea', 'KP', 'PRK', '408', 'KPW', '+850', 'Pyongyang', 'Asia'),
    (859168, 'North Macedonia', 'MK', 'MKD', '807', 'MKD', '+389', 'Skopje', 'Europe'),
    (280456, 'Norway', 'NO', 'NOR', '578', 'NOK', '+47', 'Oslo', 'Europe'),
    (619511, 'Oman', 'OM', 'OMN', '512', 'OMR', '+968', 'Muscat', 'Asia'),
    (811784, 'Palau', 'PW', 'PLW', '585', 'USD', '+680', 'Ngerulmud', 'Oceania'),
    (327110, 'Palestine', 'PS', 'PSE', '275', 'ILS', '+970', 'Ramallah', 'Asia'),
    (191822, 'Panama', 'PA', 'PAN', '591', 'PAB', '+507', 'Panama City', 'Americas'),
    (682928, 'Papua New Guinea', 'PG', 'PNG', '598', 'PGK', '+675', 'Port Moresby', 'Oceania'),
    (356244, 'Paraguay', 'PY', 'PRY', '600', 'PYG', '+595', 'Asunción', 'Americas'),
    (424979, 'Peru', 'PE', 'PER', '604', 'PEN', '+51', 'Lima', 'Americas'),
    (908551, 'Philippines', 'PH', 'PHL', '608', 'PHP', '+63', 'Manila', 'Asia'),
    (978765, 'Poland', 'PL', 'POL', '616', 'PLN', '+48', 'Warsaw', 'Europe'),
    (901493, 'Portugal', 'PT', 'PRT', '620', 'EUR', '+351', 'Lisbon', 'Europe'),
    (450218, 'Qatar', 'QA', 'QAT', '634', 'QAR', '+974', 'Doha', 'Asia'),
    (637433, 'Republic of the Congo', 'CG', 'COG', '178', 'XAF', '+242', 'Brazzaville', 'Africa'),
    (251675, 'Romania', 'RO', 'ROU', '642', 'RON', '+40', 'Bucharest', 'Europe'),
    (879770, 'Russia', 'RU', 'RUS', '643', 'RUB', '+7', 'Moscow', 'Europe'),
    (164573, 'Rwanda', 'RW', 'RWA', '646', 'RWF', '+250', 'Kigali', 'Africa'),
    (598047, 'Saint Kitts and Nevis', 'KN', 'KNA', '659', 'XCD', '+1', 'Basseterre', 'Americas'),
    (800492, 'Saint Lucia', 'LC', 'LCA', '662', 'XCD', '+1', 'Castries', 'Americas'),
    (408606, 'Saint Vincent and the Grenadines', 'VC', 'VCT', '670', 'XCD', '+1', 'Kingstown', 'Americas'),
    (970359, 'Samoa', 'WS', 'WSM', '882', 'WST', '+685', 'Apia', 'Oceania'),
    (182564, 'San Marino', 'SM', 'SMR', '674', 'EUR', '+378', 'City of San Marino', 'Europe'),
    (113028, 'Saudi Arabia', 'SA', 'SAU', '682', 'SAR', '+966', 'Riyadh', 'Asia'),
    (260072, 'Senegal', 'SN', 'SEN', '686', 'XOF', '+221', 'Dakar', 'Africa'),
    (780707, 'Serbia', 'RS', 'SRB', '688', 'RSD', '+381', 'Belgrade', 'Europe'),
    (422070, 'Seychelles', 'SC', 'SYC', '690', 'SCR', '+248', 'Victoria', 'Africa'),
    (524319, 'Sierra Leone', 'SL', 'SLE', '694', 'SLE', '+232', 'Freetown', 'Africa'),
    (568312, 'Singapore', 'SG', 'SGP', '702', 'SGD', '+65', 'Singapore', 'Asia'),
    (933479, 'Slovakia', 'SK', 'SVK', '703', 'EUR', '+421', 'Bratislava', 'Europe'),
    (202251, 'Slovenia', 'SI', 'SVN', '705', 'EUR', '+386', 'Ljubljana', 'Europe'),
    (537427, 'Solomon Islands', 'SB', 'SLB', '090', 'SBD', '+677', 'Honiara', 'Oceania'),
    (307714, 'Somalia', 'SO', 'SOM', '706', 'SOS', '+252', 'Mogadishu', 'Africa'),
    (435562, 'South Africa', 'ZA', 'ZAF', '710', 'ZAR', '+27', 'Pretoria', 'Africa'),
    (851756, 'South Korea', 'KR', 'KOR', '410', 'KRW', '+82', 'Seoul', 'Asia'),
    (205557, 'South Sudan', 'SS', 'SSD', '728', 'SSP', '+211', 'Juba', 'Africa'),
    (248375, 'Spain', 'ES', 'ESP', '724', 'EUR', '+34', 'Madrid', 'Europe'),
    (389590, 'Sri Lanka', 'LK', 'LKA', '144', 'LKR', '+94', 'Sri Jayawardenepura Kotte', 'Asia'),
    (959254, 'Sudan', 'SD', 'SDN', '729', 'SDG', '+249', 'Khartoum', 'Africa'),
    (967750, 'Suriname', 'SR', 'SUR', '740', 'SRD', '+597', 'Paramaribo', 'Americas'),
    (335983, 'Sweden', 'SE', 'SWE', '752', 'SEK', '+46', 'Stockholm', 'Europe'),
    (532831, 'Switzerland', 'CH', 'CHE', '756', 'CHF', '+41', 'Bern', 'Europe'),
    (655604, 'Syria', 'SY', 'SYR', '760', 'SYP', '+963', 'Damascus', 'Asia'),
    (656909, 'São Tomé and Príncipe', 'ST', 'STP', '678', 'STN', '+239', 'São Tomé', 'Africa'),
    (187520, 'Taiwan', 'TW', 'TWN', '158', 'TWD', '+886', 'Taipei', 'Asia'),
    (446357, 'Tajikistan', 'TJ', 'TJK', '762', 'TJS', '+992', 'Dushanbe', 'Asia'),
    (845238, 'Tanzania', 'TZ', 'TZA', '834', 'TZS', '+255', 'Dodoma', 'Africa'),
    (117597, 'Thailand', 'TH', 'THA', '764', 'THB', '+66', 'Bangkok', 'Asia'),
    (429997, 'Timor-Leste', 'TL', 'TLS', '626', 'USD', '+670', 'Dili', 'Asia'),
    (374777, 'Togo', 'TG', 'TGO', '768', 'XOF', '+228', 'Lomé', 'Africa'),
    (764326, 'Tonga', 'TO', 'TON', '776', 'TOP', '+676', 'Nuku''alofa', 'Oceania'),
    (166296, 'Trinidad and Tobago', 'TT', 'TTO', '780', 'TTD', '+1', 'Port of Spain', 'Americas'),
    (427089, 'Tunisia', 'TN', 'TUN', '788', 'TND', '+216', 'Tunis', 'Africa'),
    (447646, 'Turkey', 'TR', 'TUR', '792', 'TRY', '+90', 'Ankara', 'Asia'),
    (982093, 'Turkmenistan', 'TM', 'TKM', '795', 'TMT', '+993', 'Ashgabat', 'Asia'),
    (659082, 'Tuvalu', 'TV', 'TUV', '798', 'AUD', '+688', 'Funafuti', 'Oceania'),
    (244269, 'Uganda', 'UG', 'UGA', '800', 'UGX', '+256', 'Kampala', 'Africa'),
    (637859, 'Ukraine', 'UA', 'UKR', '804', 'UAH', '+380', 'Kyiv', 'Europe'),
    (147789, 'United Arab Emirates', 'AE', 'ARE', '784', 'AED', '+971', 'Abu Dhabi', 'Asia'),
    (234391, 'United Kingdom', 'GB', 'GBR', '826', 'GBP', '+44', 'London', 'Europe'),
    (620205, 'Uruguay', 'UY', 'URY', '858', 'UYU', '+598', 'Montevideo', 'Americas'),
    (191709, 'Uzbekistan', 'UZ', 'UZB', '860', 'UZS', '+998', 'Tashkent', 'Asia'),
    (340700, 'Vanuatu', 'VU', 'VUT', '548', 'VUV', '+678', 'Port Vila', 'Oceania'),
    (721082, 'Vatican City', 'VA', 'VAT', '336', 'EUR', '+39', 'Vatican City', 'Europe'),
    (618816, 'Venezuela', 'VE', 'VEN', '862', 'VES', '+58', 'Caracas', 'Americas'),
    (607039, 'Vietnam', 'VN', 'VNM', '704', 'VND', '+84', 'Hanoi', 'Asia'),
    (270647, 'Yemen', 'YE', 'YEM', '887', 'YER', '+967', 'Sana''a', 'Asia'),
    (586309, 'Zambia', 'ZM', 'ZMB', '894', 'ZMW', '+260', 'Lusaka', 'Africa'),
    (660007, 'Zimbabwe', 'ZW', 'ZWE', '716', 'ZWG', '+263', 'Harare', 'Africa');

CREATE TEMP TABLE _tripraft_countries_guard (ok INTEGER NOT NULL CHECK(ok=1));
-- Identity collision with existing data aborts import rather than reassigning ID/name.
INSERT INTO _tripraft_countries_guard (ok)
SELECT CASE WHEN EXISTS (
   SELECT 1 FROM countries c JOIN _tripraft_countries_stage s
     ON c.id=s.id WHERE c.country_name<>s.country_name
) OR EXISTS (
   SELECT 1 FROM countries c JOIN _tripraft_countries_stage s
     ON c.country_name=s.country_name WHERE c.id<>s.id
) THEN 0 ELSE 1 END;

-- Existing rows: refresh metadata only, never rewrite the primary key.
-- New rows: use the schema default created_at and NULL retired_at.
INSERT INTO countries (
  id, country_name, iso2, iso3, iso_numeric,
  currency_code, calling_code, capital, region, updated_at
)
SELECT
  id, country_name, iso2, iso3, iso_numeric, currency_code, calling_code, capital, region, strftime('%Y-%m-%d','now')
FROM _tripraft_countries_stage WHERE 1=1
ON CONFLICT(id) DO UPDATE SET
  country_name=excluded.country_name,
  iso2=excluded.iso2,
  iso3=excluded.iso3,
  iso_numeric=excluded.iso_numeric,
  currency_code=excluded.currency_code,
  calling_code=excluded.calling_code,
  capital=excluded.capital,
  region=excluded.region,
  updated_at=excluded.updated_at;

-- Assert that every staged country has landed with its exact original ID/name.
INSERT INTO _tripraft_countries_guard(ok)
SELECT CASE WHEN
  (SELECT COUNT(*) FROM _tripraft_countries_stage)=190
  AND (SELECT COUNT(*) FROM countries c JOIN _tripraft_countries_stage s
       ON c.id=s.id AND c.country_name=s.country_name)=190
  THEN 1 ELSE 0 END;

DROP TABLE _tripraft_countries_guard;
DROP TABLE _tripraft_countries_stage;
COMMIT;

-- Optional verification in your SQLite console:
-- SELECT COUNT(*) FROM countries; -- 190 if the table was initially empty
-- SELECT id,country_name,iso2,iso3,iso_numeric,currency_code,calling_code,capital,region
-- FROM countries ORDER BY country_name;
-- PRAGMA integrity_check;
-- PRAGMA foreign_key_check;
