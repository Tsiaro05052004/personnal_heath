-- =============================================================================
-- Ma Santé — schéma Supabase initial (étape 7)
--
-- À exécuter UNE fois dans Supabase : SQL Editor → New query → coller → Run.
--
-- Principes (docs/architecture.txt, section 8) :
--   * Mêmes tables que la base locale du téléphone (Drift), qui reste la
--     source de vérité ; le serveur sert à la sauvegarde et à la synchro.
--   * Les identifiants (UUID) sont créés sur le téléphone.
--   * Suppression logique (deleted) pour propager les suppressions.
--   * updated_at   : heure de modification sur le téléphone (la plus
--                    récente gagne en cas de conflit).
--     server_updated_at : heure d'arrivée sur le serveur, posée par un
--                    déclencheur ; sert à récupérer « ce qui a changé
--                    depuis la dernière synchro » sans dépendre de
--                    l'horloge du téléphone.
--   * Sécurité au niveau des lignes (RLS) sur toutes les tables :
--     chacun ne lit et n'écrit QUE ses propres lignes (user_id = auth.uid()).
--   * Supprimer le compte supprime toutes ses données (on delete cascade).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Fonctions utilitaires
-- -----------------------------------------------------------------------------

-- Pose server_updated_at à chaque écriture (le téléphone ne peut pas le
-- falsifier).
create or replace function public.set_server_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.server_updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Profils (nom affiché « Bonjour, … »)
-- -----------------------------------------------------------------------------
create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  display_name      text check (char_length(display_name) <= 100),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  server_updated_at timestamptz not null default now()
);

-- Crée le profil à l'inscription, avec le nom saisi dans l'appli
-- (options.data.display_name de signUp).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- Médicaments
-- -----------------------------------------------------------------------------
create table public.medications (
  id                  uuid primary key,
  user_id             uuid not null default auth.uid()
                      references auth.users (id) on delete cascade,
  name                text not null check (char_length(name) between 1 and 100),
  dosage              text not null default '',
  quantity_per_intake real not null default 1 check (quantity_per_intake > 0),
  unit                text not null default 'comprimé',
  meal_instruction    text not null default 'none'
                      check (meal_instruction in
                        ('none', 'beforeMeal', 'duringMeal', 'afterMeal')),
  notes               text,
  start_date          date not null,
  end_date            date check (end_date is null or end_date >= start_date),
  active              boolean not null default true,
  updated_at          timestamptz not null,
  deleted             boolean not null default false,
  server_updated_at   timestamptz not null default now()
);

-- Une heure de prise quotidienne (minutes depuis minuit, 08:00 → 480).
create table public.medication_schedules (
  id                uuid primary key,
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  medication_id     uuid not null
                    references public.medications (id) on delete cascade,
  minute_of_day     smallint not null check (minute_of_day between 0 and 1439),
  updated_at        timestamptz not null,
  deleted           boolean not null default false,
  server_updated_at timestamptz not null default now()
);

-- Une prise confirmée ou déclarée non prise. Une prise sans ligne ici est
-- « non confirmée » (jamais « oubliée » automatiquement).
create table public.intake_logs (
  id                uuid primary key,
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  medication_id     uuid not null
                    references public.medications (id) on delete cascade,
  scheduled_at      timestamptz not null,
  status            text not null check (status in ('taken', 'missed')),
  taken_at          timestamptz,
  quantity_taken    real,
  updated_at        timestamptz not null,
  deleted           boolean not null default false,
  server_updated_at timestamptz not null default now(),
  -- Une seule réponse par prise prévue.
  unique (medication_id, scheduled_at)
);

-- -----------------------------------------------------------------------------
-- Eau
-- -----------------------------------------------------------------------------
create table public.water_settings (
  id                uuid primary key,
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  goal_glasses      integer not null default 5 check (goal_glasses between 1 and 20),
  ml_per_glass      integer not null default 250 check (ml_per_glass between 50 and 1000),
  wake_minute       integer not null default 420 check (wake_minute between 0 and 1439),
  sleep_minute      integer not null default 1320 check (sleep_minute between 0 and 1439),
  reminders_enabled boolean not null default true,
  updated_at        timestamptz not null,
  deleted           boolean not null default false,
  server_updated_at timestamptz not null default now()
);

-- Un seul objectif d'eau actif par utilisateur.
create unique index water_settings_one_per_user
  on public.water_settings (user_id) where not deleted;

create table public.water_logs (
  id                uuid primary key,
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  drank_at          timestamptz not null,
  ml                integer not null check (ml between 1 and 2000),
  updated_at        timestamptz not null,
  deleted           boolean not null default false,
  server_updated_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- server_updated_at + index de synchronisation
-- -----------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'medications', 'medication_schedules',
    'intake_logs', 'water_settings', 'water_logs'
  ] loop
    execute format(
      'create trigger set_server_updated_at before insert or update on public.%I
         for each row execute function public.set_server_updated_at()', t);
  end loop;

  -- « Ce qui a changé depuis la dernière synchro », par utilisateur.
  foreach t in array array[
    'medications', 'medication_schedules',
    'intake_logs', 'water_settings', 'water_logs'
  ] loop
    execute format(
      'create index %I on public.%I (user_id, server_updated_at)',
      t || '_sync_idx', t);
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- Sécurité au niveau des lignes (RLS)
-- -----------------------------------------------------------------------------
-- Les visiteurs non connectés (rôle anon) n'ont accès à rien.
revoke all on
  public.profiles, public.medications, public.medication_schedules,
  public.intake_logs, public.water_settings, public.water_logs
  from anon;

alter table public.profiles             enable row level security;
alter table public.medications          enable row level security;
alter table public.medication_schedules enable row level security;
alter table public.intake_logs          enable row level security;
alter table public.water_settings       enable row level security;
alter table public.water_logs           enable row level security;

-- Profil : le sien seulement (créé par le déclencheur, jamais supprimé à
-- la main : il part avec le compte).
create policy "profil : lecture du sien" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profil : modification du sien" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- Autres tables : lecture, ajout, modification, suppression de SES lignes.
do $$
declare
  t text;
begin
  foreach t in array array[
    'medications', 'medication_schedules',
    'intake_logs', 'water_settings', 'water_logs'
  ] loop
    execute format(
      'create policy "propriétaire seulement" on public.%I
         for all to authenticated
         using ((select auth.uid()) = user_id)
         with check ((select auth.uid()) = user_id)', t);
  end loop;
end;
$$;

-- Un horaire ou une prise ne peut viser que SES propres médicaments
-- (sinon on pourrait rattacher une ligne au médicament de quelqu'un
-- d'autre en devinant son UUID).
create or replace function public.check_medication_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.medications m
    where m.id = new.medication_id and m.user_id = new.user_id
  ) then
    raise exception 'medication % not owned by user', new.medication_id
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger check_owner before insert or update
  on public.medication_schedules
  for each row execute function public.check_medication_owner();
create trigger check_owner before insert or update
  on public.intake_logs
  for each row execute function public.check_medication_owner();

-- -----------------------------------------------------------------------------
-- Suppression du compte ET de toutes les données (cahier des charges 6.3)
-- -----------------------------------------------------------------------------
-- Appelée par l'appli : supabase.rpc('delete_my_account').
-- Supprimer l'utilisateur supprime toutes ses lignes (on delete cascade).
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  delete from auth.users where id = me;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- Les fonctions internes ne sont pas appelables depuis l'appli.
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.check_medication_owner() from public, anon, authenticated;
revoke all on function public.set_server_updated_at() from public, anon, authenticated;
