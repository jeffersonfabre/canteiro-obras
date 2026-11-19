-- Canteiro — gestão de obras (DomDevLabs)
-- Banco no projeto Supabase "Araleo Fragrances", porém totalmente independente:
-- tabelas próprias (prefixo cant_), lista própria de usuários, bucket próprio de fotos.
-- Nenhuma ligação com as tabelas da loja (products, orders...) nem do Hub (hub_*).
-- Já aplicado em 19/11/2026. Mantido aqui como referência.

create table public.cant_membros (
  email text primary key check (email = lower(email)),
  nome text,
  papel text not null default 'editor' check (papel in ('admin','editor','leitor')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);

create table public.cant_registros (
  id text primary key,
  colecao text not null check (colecao in ('obras','etapas','itens','rdos','medicoes','tarefas','lanc','fornec','solic','mov','estmin')),
  obra_id text,
  dados jsonb not null,
  atualizado_em timestamptz not null default now(),
  atualizado_por text default lower(auth.jwt()->>'email')
);
create index cant_registros_colecao_idx on public.cant_registros (colecao);
create index cant_registros_obra_idx on public.cant_registros (obra_id);

create or replace function public.cant_papel() returns text
language sql stable security definer set search_path = public as $$
  select papel from public.cant_membros
  where email = lower(coalesce(auth.jwt()->>'email','')) and ativo
$$;
revoke all on function public.cant_papel() from public, anon;
grant execute on function public.cant_papel() to authenticated;

create or replace function public.cant_touch() returns trigger language plpgsql set search_path = public as $$
begin new.atualizado_em := now(); new.atualizado_por := lower(coalesce(auth.jwt()->>'email', new.atualizado_por)); return new; end $$;
create trigger cant_registros_touch before insert or update on public.cant_registros for each row execute function public.cant_touch();

alter table public.cant_membros enable row level security;
alter table public.cant_registros enable row level security;

create policy cant_membros_sel on public.cant_membros for select to authenticated using (public.cant_papel() is not null);
create policy cant_membros_ins on public.cant_membros for insert to authenticated with check (public.cant_papel() = 'admin');
create policy cant_membros_upd on public.cant_membros for update to authenticated using (public.cant_papel() = 'admin') with check (public.cant_papel() = 'admin');
create policy cant_membros_del on public.cant_membros for delete to authenticated using (public.cant_papel() = 'admin');

create policy cant_reg_sel on public.cant_registros for select to authenticated using (public.cant_papel() is not null);
create policy cant_reg_ins on public.cant_registros for insert to authenticated with check (public.cant_papel() in ('admin','editor'));
create policy cant_reg_upd on public.cant_registros for update to authenticated using (public.cant_papel() in ('admin','editor')) with check (public.cant_papel() in ('admin','editor'));
create policy cant_reg_del on public.cant_registros for delete to authenticated using (public.cant_papel() in ('admin','editor'));

revoke all on public.cant_membros, public.cant_registros from anon;
grant select, insert, update, delete on public.cant_membros, public.cant_registros to authenticated;

alter table public.cant_registros replica identity full;
alter publication supabase_realtime add table public.cant_registros;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('canteiro-fotos','canteiro-fotos', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy cant_fotos_sel on storage.objects for select to authenticated using (bucket_id = 'canteiro-fotos' and public.cant_papel() is not null);
create policy cant_fotos_ins on storage.objects for insert to authenticated with check (bucket_id = 'canteiro-fotos' and public.cant_papel() in ('admin','editor'));
create policy cant_fotos_del on storage.objects for delete to authenticated using (bucket_id = 'canteiro-fotos' and public.cant_papel() in ('admin','editor'));

insert into public.cant_membros (email, nome, papel) values ('jeffersonfabre@gmail.com','Jefferson Fabre','admin');
