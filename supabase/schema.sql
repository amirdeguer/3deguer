-- Ejecutar en el editor SQL de Supabase. Requiere usuarios de Supabase Auth.
create table if not exists public.filaments (
 owner_id uuid not null references auth.users(id) on delete cascade,
 name text not null,
 grams integer not null default 0 check (grams>=0),
 color_hex text not null default '#999999',
 primary key(owner_id,name)
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 name text not null,
 category text not null,
 price numeric(12,2) not null check(price>=0),
 unique(owner_id,name)
);
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 client text not null,
 product text not null,
 qty integer not null check(qty>0),
 price numeric(12,2) not null check(price>=0),
 status text not null default 'Pendiente' check(status in ('Pendiente','En producción','Hecho')),
 colors jsonb not null default '[]'::jsonb,
 created_at timestamptz not null default now()
);
create table if not exists public.stock_movements (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 filament_name text not null,
 delta_grams integer not null,
 order_id uuid references public.orders(id),
 reason text not null,
 created_at timestamptz not null default now()
);
-- No exponer datos de un usuario a otro.
alter table public.filaments enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.stock_movements enable row level security;
create policy "own filaments" on public.filaments for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "own products" on public.products for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "own orders" on public.orders for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "read own movements" on public.stock_movements for select to authenticated using(owner_id=auth.uid());
-- Un único procedimiento atómico crea pedido y descuenta inventario.
create or replace function public.create_order_with_stock(p_client text,p_product text,p_qty integer,p_price numeric,p_colors jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid();v_id uuid;v_color record;v_count integer;v_needed integer;
begin
 if v_user is null then raise exception 'Sesión requerida';end if;
 if nullif(trim(p_client),'') is null or p_qty<1 or p_price<0 or p_colors is null or jsonb_typeof(p_colors)<>'array' or jsonb_array_length(p_colors)<1 or jsonb_array_length(p_colors)>4 then raise exception 'Pedido inválido';end if;
 if not exists(select 1 from public.products where owner_id=v_user and name=p_product) then raise exception 'Producto no encontrado';end if;
 for v_color in select key as name,sum(value::integer) as grams from (
   select elem->>'name' as key,elem->>'g' as value from jsonb_array_elements(p_colors) elem
 ) q group by key order by key loop
   if v_color.name is null or v_color.grams is null or v_color.grams<=0 then raise exception 'Filamento inválido';end if;
   update public.filaments set grams=grams-v_color.grams where owner_id=v_user and name=v_color.name and grams>=v_color.grams;
   get diagnostics v_count=row_count;
   if v_count<>1 then raise exception 'Stock insuficiente: %',v_color.name;end if;
 end loop;
 insert into public.orders(owner_id,client,product,qty,price,colors) values(v_user,p_client,p_product,p_qty,p_price,p_colors) returning id into v_id;
 for v_color in select key as name,sum(value::integer) as grams from (
   select elem->>'name' as key,elem->>'g' as value from jsonb_array_elements(p_colors) elem
 ) q group by key loop
 insert into public.stock_movements(owner_id,filament_name,delta_grams,order_id,reason) values(v_user,v_color.name,-v_color.grams,v_id,'Consumo por pedido');
 end loop;
 return v_id;
end $$;
create or replace function public.replenish_stock(p_name text,p_grams integer)
returns void language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=auth.uid();v_count integer;
begin
 if v_user is null or p_grams is null or p_grams<=0 then raise exception 'Reposición inválida';end if;
 update public.filaments set grams=grams+p_grams where owner_id=v_user and name=p_name;
 get diagnostics v_count=row_count;
 if v_count<>1 then raise exception 'Filamento no encontrado';end if;
 insert into public.stock_movements(owner_id,filament_name,delta_grams,reason) values(v_user,p_name,p_grams,'Reposición');
end $$;
revoke all on function public.create_order_with_stock(text,text,integer,numeric,jsonb) from public,anon;
revoke all on function public.replenish_stock(text,integer) from public,anon;
grant execute on function public.create_order_with_stock(text,text,integer,numeric,jsonb) to authenticated;
grant execute on function public.replenish_stock(text,integer) to authenticated;
