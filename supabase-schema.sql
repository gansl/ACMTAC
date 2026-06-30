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
  factor_notes jsonb,
  admit_date date,
  admit_dx text,
  plan_action text,
  plan_days integer,
  plan_load_mg numeric,
  plan_sub_action text,
  plan_sub_pct numeric,
  new_twd numeric,
  next_appt date,
  clinical_note text,
  created_at timestamptz default now()
);

-- If you already created this table with the older schema, run these to add the new columns:
alter table visits add column if not exists factor_notes jsonb;
alter table visits add column if not exists plan_load_mg numeric;
alter table visits add column if not exists plan_sub_action text;
alter table visits add column if not exists plan_sub_pct numeric;
alter table visits drop column if exists others_text;

create table if not exists dosing_rules (
  id integer primary key default 1,
  rules jsonb not null
);

insert into dosing_rules (id, rules) values (
  1,
  '{
    "below": [
      {"maxDeficit": 0.5, "increasePct": 10, "note": "Increase weekly dose by 10%."},
      {"maxDeficit": 999, "increasePct": 20, "note": "Give a stat dose (double the new daily dose), then increase weekly dose by 20%."}
    ],
    "above": [
      {"maxExcess": 0.09, "reducePct": 0, "withholdDays": 0, "note": "No change. Within acceptable buffer above target."},
      {"maxExcess": 0.59, "reducePct": 0, "withholdDays": 0, "note": "No change. Recheck INR in 1 week; if persistently elevated, decrease weekly dose by 5-10%."},
      {"maxExcess": 1.09, "reducePct": 10, "withholdDays": 1, "note": "Omit 1 dose, then decrease weekly dose by 10%."},
      {"maxExcess": 2.0, "reducePct": 10, "withholdDays": 2, "note": "Omit 2 doses, then decrease weekly dose by 10%."},
      {"maxExcess": 999, "reducePct": 0, "withholdDays": 0, "note": "INR critically high — refer to doctor immediately. Do not adjust dose without medical review."}
    ]
  }'
) on conflict (id) do nothing;
-- Note: this only inserts if no row exists yet, so it never overwrites rules you've already
-- edited in the Dosing rules tab. To reset to these defaults on an existing database, run:
-- delete from dosing_rules where id = 1; then re-run this INSERT block.

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
