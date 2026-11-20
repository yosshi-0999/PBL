-- 相性表（場面タグ × 服タグ）
-- 提案のとき、予定の場面タグと服のタグを突き合わせて点数 α を足す。
-- is_forbidden が true の組み合わせに当たる服は候補から除外する。
-- 表にない組み合わせは 0 点として扱う。

create table public.tag_compat (
  scene_tag_id   bigint      not null,
  scene_tag_type text        not null default 'scene' check (scene_tag_type = 'scene'),
  item_tag_id    bigint      not null,
  item_tag_type  text        not null default 'item'  check (item_tag_type = 'item'),
  score          integer     not null check (score between -5 and 5),
  is_forbidden   boolean     not null default false,
  updated_at     timestamptz not null default now(),
  primary key (scene_tag_id, item_tag_id),
  -- 種類も一緒に参照して、場面タグ × 服タグ以外の組み合わせを入れられないようにする
  foreign key (scene_tag_id, scene_tag_type) references public.tags (id, type) on delete cascade,
  foreign key (item_tag_id,  item_tag_type)  references public.tags (id, type) on delete cascade
);

comment on table  public.tag_compat              is '場面タグ × 服タグ の相性表';
comment on column public.tag_compat.score        is '相性点 α（-5〜+5）。提案時に足す';
comment on column public.tag_compat.is_forbidden is 'true ならこの場面ではその服を使わない';

create index tag_compat_item_tag_id_idx on public.tag_compat (item_tag_id);

-- RLS: 誰でも読める。変更はアプリからはできず、SQL で管理する
alter table public.tag_compat enable row level security;

create policy "相性表は誰でも読める"
  on public.tag_compat for select
  using (true);

-- 初期データ（仮の点数。チームで調整する）
insert into public.tag_compat (scene_tag_id, item_tag_id, score, is_forbidden)
select s.id, i.id, v.score, v.is_forbidden
from (values
  -- 場面,        服,          α,  禁止
  ('通学',         'Tシャツ',     2, false),
  ('通学',         'パーカー',    2, false),
  ('通学',         'デニム',      2, false),
  ('通学',         'スニーカー',  2, false),
  ('通学',         'シャツ',      1, false),
  ('通学',         'スーツ',     -3, false),

  ('バイト',       'シャツ',      1, false),
  ('バイト',       'スラックス',  1, false),
  ('バイト',       'スニーカー',  2, false),

  ('面接',         'スーツ',      5, false),
  ('面接',         'ジャケット',  3, false),
  ('面接',         'シャツ',      3, false),
  ('面接',         'スラックス',  3, false),
  ('面接',         '革靴',        3, false),
  ('面接',         'Tシャツ',    -3, false),
  ('面接',         'スニーカー', -3, false),
  ('面接',         'デニム',     -5, true),
  ('面接',         'パーカー',   -5, true),
  ('面接',         'ジャージ',   -5, true),

  ('休日お出かけ', 'デニム',      3, false),
  ('休日お出かけ', 'スニーカー',  3, false),
  ('休日お出かけ', 'Tシャツ',     2, false),
  ('休日お出かけ', 'パーカー',    2, false),
  ('休日お出かけ', 'ジャケット',  1, false),
  ('休日お出かけ', 'スーツ',     -3, false),

  ('運動',         'ジャージ',    5, false),
  ('運動',         'スニーカー',  5, false),
  ('運動',         'Tシャツ',     3, false),
  ('運動',         'シャツ',     -2, false),
  ('運動',         'ジャケット', -3, false),
  ('運動',         'スラックス', -3, false),
  ('運動',         'デニム',     -3, false),
  ('運動',         'スーツ',     -5, true),
  ('運動',         '革靴',       -5, true)
) as v(scene_name, item_name, score, is_forbidden)
join public.tags s on s.type = 'scene' and s.name = v.scene_name and s.user_id is null
join public.tags i on i.type = 'item'  and i.name = v.item_name  and i.user_id is null;
