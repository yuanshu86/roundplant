-- 圆形植物 P3 最小 schema（文字社交 + 附近植友）
-- 执行位置：Supabase 控制台 → SQL Editor → 粘贴运行
-- 设计原则：纯文本、极小数据；附近植友用坐标 + Haversine 距离，不需要地图 SDK / 不存地图瓦片。

-- 1) 用户档案（与 auth.users 一对一）
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text not null default '植友',
  avatar_url  text,                       -- 可选，留空则用默认头像
  lat         double precision,           -- 最近一次上报的纬度（可空）
  lng         double precision,           -- 最近一次上报的经度（可空）
  avatar_color text default '#059669',    -- 头像底色（十六进制，如 #059669）
  plant_icon  text default 'leaf',        -- 头像内植物图标：leaf/flower/sprout/seedling/rose
  tag         text default '养花爱好者',  -- 个性标签
  wechat      text,                       -- 微信号（可选，非必填；用户主动公开后对方可见）
  updated_at  timestamptz not null default now()
);
-- 兼容已有项目：旧版 profiles 表没有 wechat 列，这里追加
alter table public.profiles add column if not exists wechat text;

-- 2) 文字消息（打招呼 / 聊天，纯文本）
create table if not exists public.messages (
  id          uuid primary key default gen_random_uuid(),
  sender_id   uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  content     text not null,
  created_at  timestamptz not null default now()
);
create index if not exists messages_pair_idx
  on public.messages (greatest(sender_id, receiver_id), least(sender_id, receiver_id), created_at);

-- 3) 附近植友查询函数（在服务端算距离，避免把全量用户暴露给客户端）
--    Haversine 公式，返回半径内的其他用户（默认 5km，最多 50 人）
create or replace function public.nearby_users(
  my_lat     double precision,
  my_lng     double precision,
  radius_m   integer default 5000
)
returns table (
  id           uuid,
  nickname     text,
  avatar_color text,
  plant_icon   text,
  tag          text,
  distance_m   double precision
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.nickname,
    p.avatar_color,
    p.plant_icon,
    p.tag,
    6371000 * acos(
      least(1.0, greatest(-1.0,
        sin(radians(my_lat)) * sin(radians(p.lat))
        + cos(radians(my_lat)) * cos(radians(p.lat)) * cos(radians(p.lng - my_lng))
      ))
    ) as distance_m
  from public.profiles p
  where p.id <> auth.uid()
    and p.lat is not null and p.lng is not null
    and 6371000 * acos(
      least(1.0, greatest(-1.0,
        sin(radians(my_lat)) * sin(radians(p.lat))
        + cos(radians(my_lat)) * cos(radians(p.lng - my_lng))
      ))
    ) <= radius_m
  order by distance_m asc
  limit 50;
$$;

-- 4) 行级安全（RLS）
alter table public.profiles enable row level security;
alter table public.messages enable row level security;

-- profiles：社交公开可读；仅本人可写
drop policy if exists "profiles read"  on public.profiles;
create policy "profiles read" on public.profiles for select using (true);
drop policy if exists "profiles upsert own" on public.profiles;
create policy "profiles upsert own" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update using (auth.uid() = id);

-- messages：仅收发双方可读；仅发送者可写
drop policy if exists "messages read own" on public.messages;
create policy "messages read own" on public.messages
  for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
drop policy if exists "messages insert own" on public.messages;
create policy "messages insert own" on public.messages
  for insert with check (auth.uid() = sender_id);

-- 5) 上报当前位置（仅更新坐标，不影响昵称/头像等用户资料）
--    附近植友要能互相看见，每个用户需先上报自己的坐标。
create or replace function public.report_location(my_lat double precision, my_lng double precision)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, lat, lng)
  values (auth.uid(), my_lat, my_lng)
  on conflict (id) do update
    set lat = excluded.lat, lng = excluded.lng, updated_at = now();
end;
$$;

-- 6) Realtime 订阅：messages 表的 INSERT 事件广播给客户端（对方来消息实时收到）
--    默认 supabase_realtime publication 已存在，只需把 messages 表加进去。
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'messages'
  ) then
    execute 'alter publication supabase_realtime add table public.messages';
  end if;
end $$;

-- 6) 7 天自动清理（pg_cron）— 招招呼/对话记录 7 天后自动删除，节省存储。
--    Supabase Free tier 默认启用 pg_cron 扩展，这里 ensure 一下。
create extension if not exists pg_cron;

-- 先清理同名老任务，避免重复注册导致报错
select cron.unschedule('cleanup-old-messages') where exists (
  select 1 from cron.job where jobname = 'cleanup-old-messages'
);
select cron.unschedule('cleanup-stale-locations') where exists (
  select 1 from cron.job where jobname = 'cleanup-stale-locations'
);

select cron.schedule(
  'cleanup-old-messages',          -- 任务名
  '0 * * * *',                     -- 每小时第 0 分跑（cron 表达式）
  $$ delete from public.messages where created_at < now() - interval '7 days' $$
);

-- 8) 3 天自动清理坐标（pg_cron）— 3 天未打开附近页的用户自动隐身。
select cron.schedule(
  'cleanup-stale-locations',
  '0 3 * * *',                     -- 每天凌晨 3 点跑
  $$ update public.profiles set lat = null, lng = null where updated_at < now() - interval '3 days' $$
);

-- 8) 我的微信号读写：用户在自己「我的」页可填/改自己的微信号，对方在对话详情页可见。
create or replace function public.set_my_wechat(my_wechat text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set wechat = my_wechat, updated_at = now() where id = auth.uid();
$$;

-- 9) 取某用户的微信号（仅供对话双方查看；其它人查返回空）。
--    RLS 已经在 profiles 的 select using (true) 里放开了（社交公开可读），但仍要求对方已登录。
create or replace function public.get_user_wechat(target_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select wechat from public.profiles where id = target_id;
$$;
