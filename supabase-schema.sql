-- Run this entire file once in Supabase: Project -> SQL Editor -> New query -> Run

create table if not exists patients (
  id text primary key,
  name text not null,
  mrn text not null,
  phone text,
  indication text,
  target_low numeric default 2,
  target_high numeric default 3,
  duration text,
  created_at timestamptz default now()
);

create table if not exists visits (
  id text primary key,
  patient_id text references patients(id) on delete cascade,
  date date,
  twd numeric,
  inr numeric,
  factors text[],
  others_text text,
  admit_date date,
  admit_dx text,
  plan_action text,
  plan_days integer,
  new_twd numeric,
  next_appt date,
  clinical_note text,
  created_at timestamptz default now()
);

create table if not exists dosing_rules (
  id integer primary key default 1,
  rules jsonb not null
);

insert into dosing_rules (id, rules) values (
  1,
  '{
    "below": [
      {"maxDeficit": 0.3, "increasePct": 5, "note": "Mild sub-therapeutic INR."},
      {"maxDeficit": 0.5, "increasePct": 10, "note": "Moderate sub-therapeutic INR; consider extra dose."},
      {"maxDeficit": 999, "increasePct": 20, "note": "Markedly sub-therapeutic INR; consider loading dose and review compliance."}
    ],
    "above": [
      {"maxExcess": 0.5, "reducePct": 10, "withholdDays": 0, "note": "Mildly supra-therapeutic INR."},
      {"maxExcess": 1.0, "reducePct": 15, "withholdDays": 1, "note": "Moderately high INR; withhold one dose then reduce."},
      {"maxExcess": 999, "reducePct": 20, "withholdDays": 2, "note": "Markedly high INR; withhold doses, monitor for bleeding, consider vitamin K per local protocol."}
    ]
  }'
) on conflict (id) do nothing;

-- Row Level Security: only signed-in users (added by you in the Supabase dashboard)
-- can read or write data. There is no public sign-up in this app, so access is
-- restricted to whoever you manually invite.

alter table patients enable row level security;
alter table visits enable row level security;
alter table dosing_rules enable row level security;

drop policy if exists "allow all - patients" on patients;
drop policy if exists "allow all - visits" on visits;
drop policy if exists "allow all - dosing_rules" on dosing_rules;

create policy "authenticated only - patients" on patients
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated only - visits" on visits
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "authenticated only - dosing_rules" on dosing_rules
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- If you previously ran the older schema with a reference_docs table, you can drop it:
drop table if exists reference_docs;
