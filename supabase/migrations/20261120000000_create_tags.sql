-- タグ テーブル
-- システムタグ（user_id が NULL）とユーザー独自タグ（user_id あり）を同じテーブルで管理する。
-- 種類（type）: scene = 場面 / item = 服 / style = テイスト

create table public.tags (
  id          bigint generated always as identity primary key,
  type        text        not null check (type in ('scene', 'item', 'style')),
  name        text        not null check (char_length(name) between 1 and 30),
  user_id     uuid        references auth.users (id) on delete cascade,
  sort_order  integer     not null default 0,
  created_at  timestamptz not null default now()
);

comment on table  public.tags         is '服・コーデにつけるタグ。user_id が NULL のものはシステムタグ';
comment on column public.tags.type    is 'scene: 場面 / item: 服 / style: テイスト';
comment on column public.tags.user_id is 'NULL ならシステムタグ。値があればそのユーザーの独自タグ';

-- 同じ種類の中で名前が重複しないようにする（システムタグ同士・同じユーザーのタグ同士）
create unique index tags_system_type_name_key
  on public.tags (type, name) where user_id is null;
create unique index tags_user_type_name_key
  on public.tags (user_id, type, name) where user_id is not null;

create index tags_user_id_idx on public.tags (user_id);

-- tag_compat から「id と種類の組み合わせ」で参照するための一意制約
alter table public.tags add constraint tags_id_type_key unique (id, type);

-- RLS（行単位のアクセス制御）
-- 読み取り: システムタグは誰でも、独自タグは本人だけ
-- 書き込み: 独自タグを本人だけ。システムタグはアプリから変更できない（SQL で管理する）
alter table public.tags enable row level security;

create policy "システムタグと自分のタグを読める"
  on public.tags for select
  using (user_id is null or user_id = (select auth.uid()));

create policy "自分のタグを追加できる"
  on public.tags for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy "自分のタグを更新できる"
  on public.tags for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "自分のタグを削除できる"
  on public.tags for delete to authenticated
  using (user_id = (select auth.uid()));
