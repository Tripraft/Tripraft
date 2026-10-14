const photos = {
  'photo-1478436127897-769e1b3f0f36': 'kyoto-torii',
  'photo-1503899036084-c55cdd92da26': 'kyoto-market',
  'photo-1493976040374-85c8e12f0c0e': 'kyoto-temple',
  'photo-1540959733332-eab4deabeeaf': 'kyoto-lanterns',
  'photo-1528164344705-475426879c0d': 'kyoto-river',
  'photo-1545569341-9eb8b30979d9': 'kyoto-river',
  'photo-1509023464722-18d996393ca8': 'kyoto-pavilion',
  'photo-1555881400-74d7acaacd8b': 'lisbon',
  'photo-1502784444187-359ac186c5bb': 'alps',
  'photo-1507003211169-0a1dd7228f2d': 'alex',
  'photo-1534528741775-53994a69daeb': 'sarah',
  'photo-1500648767791-00dcc994a43e': 'marcus',
  'photo-1517841905240-472988babdf9': 'elena',
};
const photo = id => '/images/planner-demo/' + photos[id] + '.jpg';
export const demoPeople = [
  {
    id: 'demo-alex',
    user_id: 'demo-alex',
    display_name: 'Alex Rivera',
    email: 'alex@example.test',
    role: 'creator',
    photo_url: photo('photo-1507003211169-0a1dd7228f2d', 120),
  },
  {
    id: 'demo-sarah',
    user_id: 'demo-sarah',
    display_name: 'Sarah Chen',
    email: 'sarah@example.test',
    role: 'admin',
    photo_url: photo('photo-1534528741775-53994a69daeb', 120),
  },
  {
    id: 'demo-marcus',
    user_id: 'demo-marcus',
    display_name: 'Marcus Williams',
    email: 'marcus@example.test',
    role: 'member',
    photo_url: photo('photo-1500648767791-00dcc994a43e', 120),
  },
  {
    id: 'demo-elena',
    user_id: 'demo-elena',
    display_name: 'Elena Rossi',
    email: 'elena@example.test',
    role: 'viewer',
    photo_url: photo('photo-1517841905240-472988babdf9', 120),
  },
];
export function createDemoState() {
  const now = new Date().toISOString();
  const catalog = [
    [
      'inari',
      'Fushimi Inari Taisha',
      'Culture',
      34.9671,
      135.7727,
      'photo-1478436127897-769e1b3f0f36',
      'Walk through vermilion torii gates before the crowds arrive.',
    ],
    [
      'nishiki',
      'Nishiki Market',
      'Dining',
      35.005,
      135.765,
      'photo-1503899036084-c55cdd92da26',
      'Taste matcha sweets, fresh skewers and Kyoto specialties.',
    ],
    [
      'kiyomizu',
      'Kiyomizu-dera Temple',
      'Culture',
      34.9949,
      135.785,
      'photo-1493976040374-85c8e12f0c0e',
      'A wooden stage overlooking the autumn maple canopy.',
    ],
    [
      'pontocho',
      'Pontocho Alley',
      'Nightlife',
      35.006,
      135.771,
      'photo-1540959733332-eab4deabeeaf',
      'Lantern-lit riverside lanes and small izakayas.',
    ],
    [
      'bamboo',
      'Arashiyama Bamboo Grove',
      'Culture',
      35.017,
      135.671,
      'photo-1528164344705-475426879c0d',
      'A quiet morning among towering green bamboo.',
    ],
    [
      'arabica',
      'Arabica Riverfront',
      'Dining',
      35.012,
      135.677,
      'photo-1545569341-9eb8b30979d9',
      'Coffee beside Togetsukyo Bridge and the Katsura River.',
    ],
    [
      'gold',
      'Kinkaku-ji Pavilion',
      'Culture',
      35.039,
      135.729,
      'photo-1509023464722-18d996393ca8',
      'Gold leaf reflected in a peaceful garden pond.',
    ],
    [
      'omurice',
      'Kichi Kichi Omurice',
      'Dining',
      35.009,
      135.77,
      'photo-1503899036084-c55cdd92da26',
      'Book ahead for the famous omurice performance.',
    ],
    [
      'gion',
      'Gion Evening Walk',
      'Nightlife',
      35.003,
      135.778,
      'photo-1493976040374-85c8e12f0c0e',
      'Historic streets, lanterns and a slow evening stroll.',
    ],
  ].map(([id, name, theme, latitude, longitude, image, description]) => ({
    id,
    name,
    theme,
    latitude,
    longitude,
    description,
    ai_summary: description,
    address: 'Kyoto, Japan',
    city_name: 'Kyoto',
    tags: [theme === 'Dining' ? 'restaurant' : theme === 'Nightlife' ? 'nightlife' : 'culture'],
    rating: 4.7,
    rating_tourist_priority: 4.7,
    photo_url: photo(image),
    category: theme === 'Dining' ? 'restaurant' : 'attraction',
    official_website: 'https://kyoto.travel/en/',
  }));
  const places = catalog
    .slice(0, 7)
    .map((p, i) => ({
      ...p,
      id: 'demo-place-' + p.id,
      visit_date: i < 4 ? '2026-10-14' : '2026-10-15',
      suggested_time: ['08:00', '11:30', '14:30', '19:30', '07:30', '10:30', '14:00'][i],
      suggested_duration: 90,
      remarks: p.description,
      added_by: 'demo-alex',
    }));
  const groups = [
    {
      id: 'demo-kyoto',
      name: 'Kyoto Autumn Crew',
      destination: 'Kyoto, Japan',
      description:
        'Three days of shrines, local food, and autumn colors. A little structure, plenty of room to explore.',
      destination_lat: 35.0116,
      destination_lng: 135.7681,
      start_date: '2026-10-14',
      end_date: '2026-10-16',
      estimated_budget: 5000,
      budget_currency: 'USD',
      created_by: 'demo-alex',
      member_count: 4,
      expense_group_id: 'demo-money-kyoto',
      group_image: photo('photo-1493976040374-85c8e12f0c0e'),
    },
    {
      id: 'demo-lisbon',
      name: 'Lisbon Long Weekend',
      destination: 'Lisbon, Portugal',
      description: 'Trams, tiles and time by the water.',
      destination_lat: 38.7223,
      destination_lng: -9.1393,
      start_date: '2026-11-05',
      end_date: '2026-11-08',
      estimated_budget: 2800,
      budget_currency: 'EUR',
      created_by: 'demo-alex',
      member_count: 4,
      expense_group_id: 'demo-money-lisbon',
      group_image: photo('photo-1555881400-74d7acaacd8b'),
    },
    {
      id: 'demo-alps',
      name: 'Alpine Summer Escape',
      destination: 'Zermatt, Switzerland',
      description: 'A week in the mountains with good friends.',
      destination_lat: 46.0207,
      destination_lng: 7.7491,
      start_date: '2026-07-12',
      end_date: '2026-07-18',
      estimated_budget: 4200,
      budget_currency: 'CHF',
      created_by: 'demo-alex',
      member_count: 4,
      expense_group_id: 'demo-money-alps',
      group_image: photo('photo-1502784444187-359ac186c5bb'),
    },
  ];
  const expenses = [
    {
      id: 'demo-trains',
      description: 'Shinkansen and rail passes',
      amount: 1760,
      paid_by: 'demo-alex',
      category: 'Transport',
      expense_date: '2026-10-14',
    },
    {
      id: 'demo-hotel',
      description: 'Kyoto riverside hotel',
      amount: 1200,
      paid_by: 'demo-sarah',
      category: 'Accommodation',
      expense_date: '2026-10-14',
    },
    {
      id: 'demo-dinner',
      description: 'Welcome dinner in Pontocho',
      amount: 320,
      paid_by: 'demo-marcus',
      category: 'Food',
      expense_date: '2026-10-14',
    },
    {
      id: 'demo-entry',
      description: 'Temple and museum tickets',
      amount: 140,
      paid_by: 'demo-elena',
      category: 'Activities',
      expense_date: '2026-10-15',
    },
  ].map((e) => ({
    ...e,
    group_id: 'demo-money-kyoto',
    splits: demoPeople.map((p) => ({ user_id: p.id, amount: e.amount / 4 })),
    created_at: now,
  }));
  const trips = Object.fromEntries(
    groups.map((g) => [
      g.id,
      {
        group: g,
        members: demoPeople.map((p) => ({ ...p })),
        places: g.id === 'demo-kyoto' ? places : [],
        checklist:
          g.id === 'demo-kyoto'
            ? [
                {
                  id: 'demo-check-1',
                  item: 'Confirm rail pass reservations',
                  category: 'pretrip',
                  completed: true,
                  authorId: 'demo-alex',
                  author_name: 'Alex Rivera',
                  priority: 'high',
                },
                {
                  id: 'demo-check-2',
                  item: 'Download offline maps',
                  category: 'pretrip',
                  completed: true,
                  authorId: 'demo-sarah',
                  author_name: 'Sarah Chen',
                  priority: 'medium',
                },
                {
                  id: 'demo-check-3',
                  item: 'Reserve the welcome dinner',
                  category: 'pretrip',
                  completed: false,
                  authorId: 'demo-marcus',
                  author_name: 'Marcus Williams',
                  assigned_to_id: 'demo-marcus',
                  assigned_to_name: 'Marcus Williams',
                  priority: 'high',
                },
                {
                  id: 'demo-check-4',
                  item: 'Pack a power adapter',
                  category: 'packing',
                  completed: true,
                  authorId: 'demo-elena',
                  author_name: 'Elena Rossi',
                  priority: 'medium',
                },
                {
                  id: 'demo-check-5',
                  item: 'Bring a light rain jacket',
                  category: 'packing',
                  completed: false,
                  authorId: 'demo-alex',
                  author_name: 'Alex Rivera',
                  priority: 'low',
                },
              ]
            : [],
        vault:
          g.id === 'demo-kyoto'
            ? [
                {
                  id: 'demo-vault-rail',
                  filename: 'Kyoto Rail Reservations.pdf',
                  mime_type: 'application/pdf',
                  file_size: 2048,
                  uploaded_by: 'demo-alex',
                  uploaded_by_name: 'Alex Rivera',
                  created_at: now,
                  booking_code: 'DEMO-RAIL-104',
                  title: 'Kyoto Rail Reservations',
                  visit_date: '2026-10-14',
                },
                {
                  id: 'demo-vault-hotel',
                  filename: 'Riverside Hotel Confirmation.pdf',
                  mime_type: 'application/pdf',
                  file_size: 3072,
                  uploaded_by: 'demo-sarah',
                  uploaded_by_name: 'Sarah Chen',
                  created_at: now,
                  booking_code: 'DEMO-HOTEL-208',
                  title: 'Riverside Hotel Confirmation',
                  visit_date: '2026-10-14',
                },
              ]
            : [],
        messages:
          g.id === 'demo-kyoto'
            ? [
                {
                  id: 'demo-msg-3',
                  sender_id: 'demo-elena',
                  sender_name: 'Elena Rossi',
                  content: 'I have the offline maps ready. See you at the main gate!',
                  sender_type: 'user',
                  created_at: now,
                  type: 'text',
                },
                {
                  id: 'demo-msg-2',
                  sender_id: 'demo-marcus',
                  sender_name: 'Marcus Williams',
                  content:
                    'Dinner poll is up. Pick your favorite and we can add the winner to our day.',
                  sender_type: 'user',
                  created_at: now,
                  type: 'text',
                },
                {
                  id: 'demo-msg-1',
                  sender_id: 'demo-sarah',
                  sender_name: 'Sarah Chen',
                  content: 'The rail reservations and hotel confirmation are in the Vault.',
                  sender_type: 'user',
                  created_at: now,
                  type: 'text',
                },
              ]
            : [],
        polls:
          g.id === 'demo-kyoto'
            ? [
                {
                  id: 'demo-poll-food',
                  name: 'Where should we eat on the last evening?',
                  created_by: 'demo-marcus',
                  created_by_name: 'Marcus Williams',
                  created_at: now,
                  is_multiple_choice: false,
                  options: [
                    {
                      text: 'Kichi Kichi Omurice',
                      votes: 2,
                      voted_by: ['demo-alex', 'demo-sarah'],
                    },
                    { text: 'Nishiki Market', votes: 1, voted_by: ['demo-marcus'] },
                  ],
                  voted_by: ['demo-alex', 'demo-sarah', 'demo-marcus'],
                },
                {
                  id: 'demo-poll-morning',
                  name: 'What is our early morning plan?',
                  created_by: 'demo-sarah',
                  created_by_name: 'Sarah Chen',
                  created_at: now,
                  is_multiple_choice: true,
                  options: [
                    { text: 'Bamboo grove walk', votes: 2, voted_by: ['demo-alex', 'demo-marcus'] },
                    {
                      text: 'Coffee by the river',
                      votes: 2,
                      voted_by: ['demo-sarah', 'demo-marcus'],
                    },
                  ],
                  voted_by: ['demo-alex', 'demo-sarah', 'demo-marcus'],
                },
              ]
            : [],
        activities:
          g.id === 'demo-kyoto'
            ? [
                {
                  id: 'demo-activity-4',
                  action: 'place_added',
                  entity_type: 'place',
                  user_name: 'Alex Rivera',
                  details: { name: 'Kinkaku-ji Pavilion' },
                  created_at: now,
                },
                {
                  id: 'demo-activity-3',
                  action: 'poll_created',
                  entity_type: 'poll',
                  user_name: 'Marcus Williams',
                  details: { name: 'Where should we eat on the last evening?' },
                  created_at: now,
                },
                {
                  id: 'demo-activity-2',
                  action: 'expense_added',
                  entity_type: 'expense',
                  user_name: 'Sarah Chen',
                  details: { message: 'Added Kyoto riverside hotel to the trip budget' },
                  created_at: now,
                },
                {
                  id: 'demo-activity-1',
                  action: 'vault_upload',
                  entity_type: 'vault',
                  user_name: 'Sarah Chen',
                  details: { filename: 'Riverside Hotel Confirmation.pdf' },
                  created_at: now,
                },
              ]
            : [],
        invitations: [],
        expenses: g.id === 'demo-kyoto' ? expenses : [],
        settlements: [],
      },
    ]),
  );
  for (const trip of Object.values(trips)) {
    for (const poll of trip.polls) {
      const options = poll.options;
      poll.votes = Object.fromEntries(options.map(o => [o.text, o.votes]));
      poll.votes_detail = Object.fromEntries(options.map(o => [o.text, o.voted_by]));
      poll.options = options.map(o => o.text);
    }
  }
  return { version: 1, catalog, trips };
}
