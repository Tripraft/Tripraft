import { createDemoState, demoPeople } from './demoData';
import { DEMO_STORAGE_KEY, DEMO_VIEWER_KEY } from './demoMode';
let state;
const uploads = new Map();
const clone = (value) => JSON.parse(JSON.stringify(value));
export function getDemoState() {
  if (!state) {
    try {
      const saved = JSON.parse(localStorage.getItem(DEMO_STORAGE_KEY));
      state = saved?.version === 1 && saved.trips ? saved : createDemoState();
    } catch {
      state = createDemoState();
    }
  }
  return state;
}
function save() {
  try {
    localStorage.setItem(DEMO_STORAGE_KEY, JSON.stringify(getDemoState()));
  } catch {
    /* Demo works in memory if storage is unavailable. */
  }
  if (typeof window !== 'undefined') window.dispatchEvent(new Event('tripraft-demo-updated'));
}
export function resetDemo() {
  state = createDemoState();
  uploads.clear();
  try {
    for (const key of Object.keys(localStorage))
      if (key.startsWith('gp_demo_shortlist_')) localStorage.removeItem(key);
  } catch {
    /* Demo storage is optional. */
  }
  save();
}
export function getDemoViewer() {
  try {
    return demoPeople.find((p) => p.id === localStorage.getItem(DEMO_VIEWER_KEY)) || demoPeople[0];
  } catch {
    return demoPeople[0];
  }
}
function fail(message, status = 400) {
  throw Object.assign(new Error(message), { status });
}
function member(trip) {
  return trip.members.find((m) => m.user_id === getDemoViewer().id && m.is_active !== false);
}
function permit(trip, roles = ['creator', 'admin', 'member']) {
  if (!roles.includes(member(trip)?.role)) fail('Your demo role cannot make this change.', 403);
}
function envelope(data) {
  return { success: true, data: clone(data), meta: { pagination: { total_pages: 1 } } };
}
function activity(trip, action, name, entity_type = 'place') {
  trip.activities.unshift({
    id: 'demo-' + crypto.randomUUID(),
    action,
    entity_type,
    user_name: getDemoViewer().display_name,
    created_at: new Date().toISOString(),
    details: { name, message: name },
  });
}
function moneyGroup(trip) {
  const balances = trip.members
    .filter((m) => m.is_active !== false)
    .map((m) => ({ user_id: m.user_id, display_name: m.display_name, balance: 0, net_balance: 0 }));
  const add = (id, amount) => {
    const b = balances.find((b) => b.user_id === id);
    if (b) {
      b.balance = Math.round((b.balance + amount) * 100) / 100;
      b.net_balance = b.balance;
    }
  };
  for (const e of trip.expenses.filter((e) => !e.is_deleted)) {
    add(e.paid_by, Number(e.amount));
    for (const s of e.splits || []) add(s.user_id, -Number(s.amount));
  }
  for (const s of trip.settlements) {
    add(s.from_user, Number(s.amount));
    add(s.to_user, -Number(s.amount));
  }
  const total = trip.expenses
    .filter((e) => !e.is_deleted)
    .reduce((sum, e) => sum + Number(e.amount), 0);
  return {
    id: trip.group.expense_group_id,
    name: trip.group.name,
    currency: trip.ledger_currency || trip.group.budget_currency,
    created_by: trip.group.created_by,
    owner_id: trip.group.created_by,
    my_role: member(trip)?.role === 'creator' ? 'admin' : member(trip)?.role,
    members: trip.members.map((m) => ({
      ...m,
      role: m.role === 'creator' ? 'admin' : m.role,
      user: { id: m.id, display_name: m.display_name, email: m.email },
    })),
    balances,
    expenses: trip.expenses,
    settlements: trip.settlements,
    total_expenses: total,
    expense_pagination: { has_more: false },
    settlement_pagination: { has_more: false },
  };
}
function demoPdf(doc) {
  const escape = (text) =>
    String(text)
      .replace(/[^\x20-\x7e]/g, ' ')
      .replace(/[()\\]/g, '\\$&');
  const stream = `BT /F1 22 Tf 50 740 Td (${escape(doc.title || doc.filename)}) Tj 0 -50 Td /F1 14 Tf (DEMO BOOKING - NOT VALID FOR TRAVEL) Tj 0 -35 Td (${escape(doc.booking_code || 'Sample uploaded document')}) Tj 0 -30 Td (${escape(doc.visit_date || 'Your trip confirmation lives here.')}) Tj ET`;
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    `<< /Length ${stream.length} >>\nstream\n${stream}\nendstream`,
  ];
  let pdf = '%PDF-1.4\n',
    offsets = [0];
  objects.forEach((o, i) => {
    offsets.push(pdf.length);
    pdf += `${i + 1} 0 obj\n${o}\nendobj\n`;
  });
  const xref = pdf.length;
  pdf += `xref\n0 6\n0000000000 65535 f \n${offsets
    .slice(1)
    .map((n) => String(n).padStart(10, '0') + ' 00000 n \n')
    .join('')}trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return new Blob([pdf], { type: 'application/pdf' });
}
// Every request in the isolated demo is handled here or rejected; it never falls through to the live API.
export async function demoRequest(method, endpoint, { body = {}, responseType } = {}) {
  const url = new URL(endpoint, 'https://demo.invalid'),
    path = url.pathname,
    db = getDemoState();
  const parts = path.split('/').filter(Boolean),
    base = parts.indexOf('group-planner');
  if (path.endsWith('/places/search')) {
    const q = (url.searchParams.get('q') || '').toLowerCase();
    if (q.includes('lisbon'))
      return envelope({
        places: [
          {
            id: 'lisbon-alfama',
            name: 'Alfama Neighborhood',
            address: 'Lisbon, Portugal',
            ai_summary: 'Explore narrow lanes, tiled facades, and viewpoints.',
            theme: 'Culture',
            latitude: 38.713,
            longitude: -9.128,
            photo_url: '/images/planner-demo/lisbon.jpg',
            rating_tourist_priority: 4.6,
          },
          {
            id: 'lisbon-belem',
            name: 'Belem Riverside Walk',
            address: 'Lisbon, Portugal',
            ai_summary: 'A relaxed afternoon beside the Tagus.',
            theme: 'Culture',
            latitude: 38.692,
            longitude: -9.216,
            photo_url: '/images/planner-demo/lisbon.jpg',
            rating_tourist_priority: 4.7,
          },
        ],
      });
    if (q.includes('zermatt'))
      return envelope({
        places: [
          {
            id: 'alps-trail',
            name: 'Alpine Viewpoint Trail',
            address: 'Zermatt, Switzerland',
            ai_summary: 'A scenic mountain day with time for a picnic.',
            theme: 'Culture',
            latitude: 46.02,
            longitude: 7.75,
            photo_url: '/images/planner-demo/alps.jpg',
            rating_tourist_priority: 4.8,
          },
        ],
      });
    return envelope({ places: db.catalog });
  }
  if (path.endsWith('/destinations/autocomplete'))
    return envelope(
      Object.values(db.trips)
        .map((t) => ({
          name: t.group.destination,
          display_name: t.group.destination,
          lat: t.group.destination_lat,
          lng: t.group.destination_lng,
          type: 'city',
        }))
        .filter((d) =>
          d.name.toLowerCase().includes((url.searchParams.get('q') || '').toLowerCase()),
        ),
    );
  if (
    path.endsWith('/group-planner/events') &&
    !String(url.searchParams.get('destination')).toLowerCase().includes('kyoto')
  )
    return envelope({ events: [] });
  if (path.endsWith('/group-planner/events'))
    return envelope({
      events: [
        {
          id: 'demo-event',
          name: 'Kyoto Lantern Evening',
          venue: 'Gion',
          date: '2026-10-16',
          address: 'Gion, Kyoto',
          latitude: 35.003,
          longitude: 135.778,
          image_url: db.catalog[3].photo_url,
          url: 'https://kyoto.travel/en/',
        },
      ],
    });
  if (path.endsWith('/group-planner/user/groups'))
    return envelope(
      Object.values(db.trips)
        .filter((t) => member(t))
        .map((t) => ({
          ...t.group,
          member_count: t.members.filter((m) => m.is_active !== false).length,
        })),
    );
  if (base >= 0) {
    const route = parts.slice(base + 1);
    if (route[0] === 'groups' && route.length === 1 && method === 'POST') {
      const id = 'demo-' + crypto.randomUUID();
      const trip = {
        ...clone(Object.values(db.trips)[0]),
        group: { ...body, id, created_by: getDemoViewer().id, member_count: 1 },
        members: [{ ...getDemoViewer(), role: 'creator' }],
      };
      for (const key of [
        'places',
        'polls',
        'checklist',
        'vault',
        'messages',
        'activities',
        'expenses',
        'settlements',
        'invitations',
      ])
        trip[key] = [];
      db.trips[id] = trip;
      save();
      return envelope(trip.group);
    }
    if (route[0] === 'invitations' && method === 'POST') {
      const trip = db.trips[body.group_id];
      if (!trip) fail('Demo group not found', 404);
      permit(trip);
      const invitation = {
        id: 'demo-' + crypto.randomUUID(),
        email: body.email,
        status: 'pending',
        invite_link: window.location.origin + '/group-planner/' + trip.group.id + '?demo=1',
      };
      trip.invitations.push(invitation);
      activity(trip, 'invitation_sent', 'Invitation for ' + body.email, 'member');
      save();
      return envelope(invitation);
    }
    if (route[0] === 'messages') {
      for (const t of Object.values(db.trips)) {
        const message = t.messages.find((m) => m.id === route[1]);
        if (message) {
          if (message.sender_id !== getDemoViewer().id)
            fail('Only your messages can be removed', 403);
          t.messages = t.messages.filter((m) => m !== message);
          save();
          return envelope({});
        }
      }
      fail('Demo message not found', 404);
    }
    if (route[0] === 'checklist') {
      const trip = Object.values(db.trips).find((t) => t.checklist.some((i) => i.id === route[1]));
      if (!trip) fail('Demo task not found', 404);
      permit(trip);
      const item = trip.checklist.find((i) => i.id === route[1]);
      if (method === 'DELETE') trip.checklist = trip.checklist.filter((i) => i !== item);
      else if (route[2] === 'toggle') item.completed = !item.completed;
      else
        Object.assign(item, body, {
          item: body.text || item.item,
          assigned_to_name:
            trip.members.find((m) => m.user_id === body.assigned_to_id)?.display_name || null,
        });
      activity(trip, 'checklist_updated', item.item, 'checklist');
      save();
      return envelope(item);
    }
    const trip = db.trips[route[1]];
    if (!trip) fail('Demo group not found', 404);
    if (!member(trip)) fail('Not a member of this demo trip', 403);
    const section = route[2],
      id = route[3];
    if (!section) {
      if (method === 'GET')
        return envelope({ ...trip.group, members: trip.members, member_details: trip.members });
      if (method === 'DELETE') {
        permit(trip, ['creator']);
        delete db.trips[trip.group.id];
        save();
        return envelope({});
      }
      permit(trip, ['creator', 'admin']);
      Object.assign(
        trip.group,
        Object.fromEntries(Object.entries(body).filter(([, v]) => v !== undefined && v !== null)),
      );
      activity(trip, 'group_updated', 'Updated trip settings', 'group');
      save();
      return envelope(trip.group);
    }
    if (section === 'members') {
      if (method === 'GET') return envelope(trip.members);
      const target = trip.members.find((m) => m.user_id === id);
      if (!target) fail('Member not found', 404);
      permit(trip, method === 'DELETE' ? ['creator'] : ['creator', 'admin']);
      if (target.role === 'creator') fail('The owner role cannot be changed');
      if (method === 'DELETE') trip.members = trip.members.filter((m) => m !== target);
      else {
        if (!['admin', 'member', 'viewer'].includes(body.role)) fail('Invalid role');
        target.role = body.role;
      }
      activity(trip, 'member_updated', target.display_name + ' role changed', 'member');
      save();
      return envelope(target);
    }
    if (section === 'leave') {
      if (member(trip)?.role === 'creator') fail('The owner cannot leave their own trip.');
      trip.members = trip.members.filter((m) => m.user_id !== getDemoViewer().id);
      save();
      return envelope({});
    }
    if (section === 'ai' && route[3] === 'consent') {
      trip.consents ||= {};
      if (method !== 'GET') {
        trip.consents[getDemoViewer().id] = method === 'POST' && body.action === 'grant';
        save();
      }
      const consented = trip.consents[getDemoViewer().id] ?? true;
      return envelope({
        allowed: consented,
        needs_prompt: !consented,
        consented_member_count: Object.values(trip.consents).filter(Boolean).length,
      });
    }
    if (section === 'activities') return envelope(trip.activities);
    if (section === 'invitations') {
      permit(trip, ['creator', 'admin']);
      return envelope(trip.invitations);
    }
    if (section === 'expense-summary') {
      const money = moneyGroup(trip);
      return envelope({
        linked: true,
        expense_group_id: money.id,
        total_spent: money.total_expenses,
        per_person: money.total_expenses / Math.max(1, trip.members.length),
        estimated_budget: trip.group.estimated_budget,
        member_count: trip.members.length,
        expense_count: trip.expenses.length,
        expenses: trip.expenses,
      });
    }
    if (section === 'places') {
      if (method === 'GET') return envelope(trip.places);
      permit(trip);
      let p = trip.places.find((p) => p.id === id);
      if (method === 'POST' && !id) {
        if (trip.places.some((p) => p.name.toLowerCase() === body.name.toLowerCase()))
          fail('This place is already in the group', 409);
        p = { ...body, id: 'demo-' + crypto.randomUUID(), added_by: getDemoViewer().id };
        trip.places.push(p);
      } else if (!p) fail('Demo place not found', 404);
      else if (method === 'DELETE') trip.places = trip.places.filter((item) => item !== p);
      else Object.assign(p, body);
      activity(
        trip,
        method === 'DELETE' ? 'place_deleted' : id ? 'place_updated' : 'place_added',
        p.name,
      );
      save();
      return envelope(p);
    }
    if (section === 'checklist') {
      if (method === 'GET') return envelope(trip.checklist);
      permit(trip);
      const item = {
        ...body,
        id: 'demo-' + crypto.randomUUID(),
        item: body.text,
        completed: false,
        authorId: getDemoViewer().id,
        author_name: getDemoViewer().display_name,
        assigned_to_name: trip.members.find((m) => m.id === body.assigned_to_id)?.display_name,
      };
      trip.checklist.push(item);
      activity(trip, 'checklist_item_added', item.item, 'checklist');
      save();
      return envelope(item);
    }
    if (section === 'vault') {
      if (method === 'GET' && !id) return envelope(trip.vault);
      const doc = trip.vault.find((v) => v.id === id);
      if (method === 'GET' && doc && responseType === 'blob')
        return uploads.get(id) || demoPdf(doc);
      permit(trip);
      if (method === 'DELETE') {
        if (
          doc?.uploaded_by !== getDemoViewer().id &&
          !['creator', 'admin'].includes(member(trip)?.role)
        )
          fail('Only the uploader or an admin may remove this file', 403);
        trip.vault = trip.vault.filter((v) => v.id !== id);
        save();
        return envelope({});
      }
      const file = body.get('file');
      const uploaded = {
        id: 'demo-' + crypto.randomUUID(),
        filename: file.name,
        mime_type: file.type,
        file_size: file.size,
        uploaded_by: getDemoViewer().id,
        uploaded_by_name: getDemoViewer().display_name,
        created_at: new Date().toISOString(),
      };
      uploads.set(uploaded.id, file);
      trip.vault.push(uploaded);
      activity(trip, 'vault_upload', file.name, 'vault');
      save();
      return envelope(uploaded);
    }
    if (section === 'polls') {
      if (method === 'GET') return envelope(trip.polls);
      permit(trip);
      let poll = trip.polls.find((p) => p.id === id);
      if (!id) {
        poll = {
          ...body,
          id: 'demo-' + crypto.randomUUID(),
          created_by: getDemoViewer().id,
          created_by_name: getDemoViewer().display_name,
          created_at: new Date().toISOString(),
          options: body.options,
          votes: Object.fromEntries(body.options.map((text) => [text, 0])),
          votes_detail: Object.fromEntries(body.options.map((text) => [text, []])),
          voted_by: [],
        };
        trip.polls.push(poll);
        activity(trip, 'poll_created', poll.name, 'poll');
      } else if (!poll) fail('Poll not found', 404);
      else if (method === 'DELETE') {
        if (poll.created_by !== getDemoViewer().id)
          fail('Only the poll creator can remove it', 403);
        trip.polls = trip.polls.filter((p) => p !== poll);
      } else if (route[4] === 'vote') {
        const option = poll.options[body.option_index];
        if (!option) fail('Invalid choice');
        const userId = getDemoViewer().id;
        const selected = (poll.votes_detail[option] || []).includes(userId);
        if (!poll.is_multiple_choice)
          for (const choice of poll.options)
            poll.votes_detail[choice] = (poll.votes_detail[choice] || []).filter(
              (id) => id !== userId,
            );
        poll.votes_detail[option] = selected
          ? (poll.votes_detail[option] || []).filter((id) => id !== userId)
          : [...new Set([...(poll.votes_detail[option] || []), userId])];
        poll.votes = Object.fromEntries(
          poll.options.map((choice) => [choice, (poll.votes_detail[choice] || []).length]),
        );
        poll.voted_by = [...new Set(Object.values(poll.votes_detail).flat())];
      }
      save();
      return envelope(poll);
    }
    if (section === 'messages') {
      if (method === 'GET') return envelope({ messages: trip.messages, has_more: false });
      if (route[3] === 'read') return envelope({});
      permit(trip);
      const message = {
        ...body,
        id: 'demo-' + crypto.randomUUID(),
        sender_id: getDemoViewer().id,
        sender_name: getDemoViewer().display_name,
        sender_type: 'user',
        created_at: new Date().toISOString(),
      };
      trip.messages.unshift(message);
      save();
      return envelope({ message });
    }
    if (section === 'link-expense') {
      permit(trip, ['creator', 'admin']);
      trip.group.expense_group_id = 'demo-money-' + trip.group.id;
      save();
      return envelope({ expense_group_id: trip.group.expense_group_id });
    }
  }
  if (parts.includes('expenses')) {
    const trip = Object.values(db.trips).find(
      (t) => t.group.expense_group_id === body.group_id || parts.includes(t.group.expense_group_id),
    );
    if (!trip) fail('Demo ledger not found', 404);
    if (method === 'GET') {
      const group = moneyGroup(trip);
      if (path.endsWith('/full')) return envelope({ group });
      if (path.includes('/settlements')) return envelope({ settlements: trip.settlements });
      return envelope(group);
    }
    permit(trip);
    const e = {
      ...body,
      id: 'demo-' + crypto.randomUUID(),
      created_at: new Date().toISOString(),
      splits:
        body.splits ||
        trip.members.map((m) => ({
          user_id: m.user_id,
          amount: Number(body.amount) / trip.members.length,
        })),
    };
    if (path.includes('settlement')) {
      trip.settlements.push(e);
      activity(trip, 'settlement_created', 'Recorded a demo settlement', 'expense');
    } else {
      trip.expenses.push(e);
      activity(trip, 'expense_added', e.description, 'expense');
    }
    save();
    return envelope({ expense: e, settlement: e, ...moneyGroup(trip) });
  }
  fail('This action is not available in the demo workspace. No live request was sent.', 400);
}
