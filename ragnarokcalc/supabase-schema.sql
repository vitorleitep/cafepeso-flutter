-- Cole isso no SQL Editor do Supabase e clique Run.
-- (1 tabela + 3 policies pra leitura/escrita/delete anônima.)

create table if not exists public.sessions (
  id                text primary key,
  saved_at          timestamptz not null default now(),
  client_saved_at   bigint,
  player_nick       text,
  player_class      text,
  duration_minutes  int,
  buffs_pct         int,
  stamina           numeric,
  multiplier        numeric,
  total_expected    numeric,
  total_realized    numeric,
  total_kills       numeric,
  data              jsonb not null
);

create index if not exists sessions_saved_at_idx
  on public.sessions (saved_at desc);

create index if not exists sessions_player_nick_idx
  on public.sessions (player_nick);

alter table public.sessions enable row level security;

-- Qualquer um (anon key) pode LER tudo
drop policy if exists "public read" on public.sessions;
create policy "public read"
  on public.sessions for select
  to anon
  using (true);

-- Qualquer um pode INSERIR (gravar nova sessão)
drop policy if exists "public insert" on public.sessions;
create policy "public insert"
  on public.sessions for insert
  to anon
  with check (true);

-- Qualquer um pode APAGAR pelo id (sem identidade real ainda).
-- Se quiser travar isso depois, é só rodar:
--   drop policy "public delete" on public.sessions;
drop policy if exists "public delete" on public.sessions;
create policy "public delete"
  on public.sessions for delete
  to anon
  using (true);
