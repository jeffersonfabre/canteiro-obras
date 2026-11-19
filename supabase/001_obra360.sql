-- Obra 360 — gestão de obras (DomDevLabs)
-- Banco no projeto Supabase "Araleo Fragrances", porém totalmente independente:
-- tabelas próprias (prefixo o360_), lista própria de usuários, bucket próprio de fotos.
-- Nenhuma ligação com as tabelas da loja (products, orders...) nem do Hub (hub_*).
-- Já aplicado em 19/11/2026 (criado como cant_*, renomeado para o360_* no mesmo dia). Referência.

create table public.o360_membros (
  email text primary key check (email = lower(email)),
  nome text,
  papel text not null default 'editor' check (papel in ('admin','editor','leitor')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);

create table public.o360_registros (
  id text primary key,
  colecao text not null check (colecao in ('obras','etapas','itens','rdos','medicoes','tarefas','lanc','fornec','solic','mov','estmin')),
  obra_id text,
  dados jsonb not null,
  atualizado_em timestamptz not null default now(),
  atualizado_por text default lower(auth.jwt()->>'email')
);
create index o360_registros_colecao_idx on public.o360_registros (colecao);
create index o360_registros_obra_idx on public.o360_registros (obra_id);

create or replace function public.o360_papel() returns text
language sql stable security definer set search_path = public as $$
  select papel from public.o360_membros
  where email = lower(coalesce(auth.jwt()->>'email','')) and ativo
$$;
revoke all on function public.o360_papel() from public, anon;
grant execute on function public.o360_papel() to authenticated;

create or replace function public.o360_touch() returns trigger language plpgsql set search_path = public as $$
begin new.atualizado_em := now(); new.atualizado_por := lower(coalesce(auth.jwt()->>'email', new.atualizado_por)); return new; end $$;
create trigger o360_registros_touch before insert or update on public.o360_registros for each row execute function public.o360_touch();

alter table public.o360_membros enable row level security;
alter table public.o360_registros enable row level security;

create policy o360_membros_sel on public.o360_membros for select to authenticated using (public.o360_papel() is not null);
create policy o360_membros_ins on public.o360_membros for insert to authenticated with check (public.o360_papel() = 'admin');
create policy o360_membros_upd on public.o360_membros for update to authenticated using (public.o360_papel() = 'admin') with check (public.o360_papel() = 'admin');
create policy o360_membros_del on public.o360_membros for delete to authenticated using (public.o360_papel() = 'admin');

create policy o360_reg_sel on public.o360_registros for select to authenticated using (public.o360_papel() is not null);
create policy o360_reg_ins on public.o360_registros for insert to authenticated with check (public.o360_papel() in ('admin','editor'));
create policy o360_reg_upd on public.o360_registros for update to authenticated using (public.o360_papel() in ('admin','editor')) with check (public.o360_papel() in ('admin','editor'));
create policy o360_reg_del on public.o360_registros for delete to authenticated using (public.o360_papel() in ('admin','editor'));

revoke all on public.o360_membros, public.o360_registros from anon;
grant select, insert, update, delete on public.o360_membros, public.o360_registros to authenticated;

alter table public.o360_registros replica identity full;
alter publication supabase_realtime add table public.o360_registros;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('obra360-fotos','obra360-fotos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy o360_fotos_sel on storage.objects for select to authenticated using (bucket_id = 'obra360-fotos' and public.o360_papel() is not null);
create policy o360_fotos_ins on storage.objects for insert to authenticated with check (bucket_id = 'obra360-fotos' and public.o360_papel() in ('admin','editor'));
create policy o360_fotos_del on storage.objects for delete to authenticated using (bucket_id = 'obra360-fotos' and public.o360_papel() in ('admin','editor'));

insert into public.o360_membros (email, nome, papel) values ('jeffersonfabre@gmail.com','Jefferson Fabre','admin');
