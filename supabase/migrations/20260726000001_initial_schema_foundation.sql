-- Adolat AI — Initial schema foundation
--
-- Manba: docs/DATABASE.md (MVP ma'lumotlar bazasi dizayni)
--
-- Ko'lam (scope) — FAQAT quyidagilar:
--   - Jadvallar (tables)
--   - Primary key'lar
--   - Foreign key'lar
--   - CHECK cheklovlari (constraints)
--   - Indekslar
--
-- Bu migratsiyada RLS **yoqiladi** (deny-all, hali siyosatsiz) — Supabase'da
-- `anon`/`authenticated` rollariga standart granted huquqlar avtomatik
-- berilgani sababli, RLS yoqilmagan jadval darhol tashqariga ochiq bo'lib
-- qoladi. Bu yerda faqat `ENABLE ROW LEVEL SECURITY` qo'llaniladi — haqiqiy
-- siyosatlar (SELECT/INSERT/UPDATE/DELETE qoidalari) hali YO'Q, shuning uchun
-- RLS yoqilgach ham hech kim (service role'dan tashqari) hech narsaga
-- kira olmaydi, toki siyosatlar keyingi migratsiyada qo'shilmaguncha.
--
-- Bu migratsiyada YO'Q (keyingi migratsiyalarga qoldirilgan):
--   - RLS siyosatlarining o'zi (SELECT/INSERT/UPDATE/DELETE qoidalari)
--   - Trigger'lar (masalan avtomatik profil yaratish, updated_at yangilash)
--   - Seed/namunaviy ma'lumot
--   - Funksiyalar (function/procedure)
--
-- Jadval tartibi FK bog'liqligiga mos ravishda tanlangan — har bir jadval
-- faqat o'zidan oldin yaratilgan jadvalga ishora qiladi.

-- =============================================================================
-- Enum turlari
-- =============================================================================

create type public.profile_role as enum ('citizen', 'organization', 'admin');

create type public.appeal_status as enum ('draft', 'submitted', 'in_review', 'answered', 'rejected', 'closed');

create type public.dispute_status as enum ('open', 'ai_analyzing', 'ai_analyzed', 'resolved', 'closed');

create type public.dispute_respondent_type as enum ('citizen', 'organization', 'unregistered');

-- `case_status_history`, `ai_analyses`, `attachments`, `notifications` jadvallarida
-- ishlatiladigan "mutually exclusive FK" naqshi uchun umumiy enum
-- (docs/DATABASE.md, "Umumiy konventsiyalar" bo'limi).
create type public.case_type as enum ('appeal', 'dispute');

-- =============================================================================
-- 1. profiles
-- (docs/DATABASE.md, 1-jadval)
-- =============================================================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.profile_role not null,
  full_name text not null,
  phone_number text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_idx on public.profiles (role);

-- =============================================================================
-- 2. organization_profiles
-- (docs/DATABASE.md, 2-jadval)
-- =============================================================================

create table public.organization_profiles (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  legal_name text not null,
  tax_id text not null,
  legal_address text not null,
  contact_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index organization_profiles_tax_id_key on public.organization_profiles (tax_id);

-- =============================================================================
-- 3. legal_categories
-- (docs/DATABASE.md, 3-jadval)
-- =============================================================================

create table public.legal_categories (
  id uuid primary key default gen_random_uuid(),
  name_uz text not null,
  name_en text,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index legal_categories_name_uz_key on public.legal_categories (name_uz);

-- =============================================================================
-- 4. government_bodies
-- (docs/DATABASE.md, 4-jadval)
-- =============================================================================

create table public.government_bodies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  region text,
  contact_email text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index government_bodies_name_idx on public.government_bodies (name);

-- =============================================================================
-- 5. appeals
-- (docs/DATABASE.md, 5-jadval)
-- =============================================================================

create table public.appeals (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id),
  category_id uuid not null references public.legal_categories (id),
  recipient_body_id uuid not null references public.government_bodies (id),
  title text not null,
  body_text text not null,
  ai_draft_text text,
  status public.appeal_status not null default 'draft',
  official_response_text text,
  submitted_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index appeals_author_id_idx on public.appeals (author_id);
create index appeals_category_id_idx on public.appeals (category_id);
create index appeals_recipient_body_id_idx on public.appeals (recipient_body_id);
create index appeals_status_idx on public.appeals (status);
create index appeals_author_id_status_idx on public.appeals (author_id, status);
create index appeals_created_at_idx on public.appeals (created_at);

-- =============================================================================
-- 6. disputes
-- (docs/DATABASE.md, 6-jadval)
-- =============================================================================

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  initiator_id uuid not null references public.profiles (id),
  respondent_profile_id uuid references public.profiles (id),
  respondent_display_name text,
  respondent_type public.dispute_respondent_type not null,
  category_id uuid not null references public.legal_categories (id),
  title text not null,
  description text not null,
  respondent_statement text,
  status public.dispute_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz,

  -- Foydalanuvchi o'ziga qarshi nizo ochishi taqiqlanadi.
  constraint disputes_initiator_not_respondent_check
    check (respondent_profile_id is null or respondent_profile_id <> initiator_id),

  -- respondent_type / respondent_profile_id / respondent_display_name mosligi.
  constraint disputes_respondent_consistency_check
    check (
      (respondent_type = 'unregistered' and respondent_profile_id is null and respondent_display_name is not null)
      or
      (respondent_type in ('citizen', 'organization') and respondent_profile_id is not null)
    )
);

create index disputes_initiator_id_idx on public.disputes (initiator_id);
create index disputes_respondent_profile_id_idx on public.disputes (respondent_profile_id);
create index disputes_category_id_idx on public.disputes (category_id);
create index disputes_status_idx on public.disputes (status);
create index disputes_created_at_idx on public.disputes (created_at);

-- =============================================================================
-- 7. case_status_history
-- (docs/DATABASE.md, 7-jadval)
-- =============================================================================

create table public.case_status_history (
  id uuid primary key default gen_random_uuid(),
  case_type public.case_type not null,
  appeal_id uuid references public.appeals (id) on delete cascade,
  dispute_id uuid references public.disputes (id) on delete cascade,
  from_status text,
  to_status text not null,
  changed_by uuid references public.profiles (id),
  note text,
  created_at timestamptz not null default now(),

  -- "Mutually exclusive FK" naqshi (docs/DATABASE.md, "Umumiy konventsiyalar" bo'limi).
  constraint case_status_history_case_type_fk_check
    check (
      (case_type = 'appeal' and appeal_id is not null and dispute_id is null)
      or
      (case_type = 'dispute' and dispute_id is not null and appeal_id is null)
    )
);

create index case_status_history_appeal_id_idx on public.case_status_history (appeal_id);
create index case_status_history_dispute_id_idx on public.case_status_history (dispute_id);
create index case_status_history_changed_by_idx on public.case_status_history (changed_by);
create index case_status_history_created_at_idx on public.case_status_history (created_at);

-- =============================================================================
-- 8. ai_analyses
-- (docs/DATABASE.md, 8-jadval)
-- =============================================================================

create table public.ai_analyses (
  id uuid primary key default gen_random_uuid(),
  case_type public.case_type not null,
  appeal_id uuid references public.appeals (id) on delete cascade,
  dispute_id uuid references public.disputes (id) on delete cascade,
  analysis_text text not null,
  legal_basis_summary text,
  confidence_score numeric,
  model_version text not null,
  created_at timestamptz not null default now(),

  -- "Mutually exclusive FK" naqshi (docs/DATABASE.md, "Umumiy konventsiyalar" bo'limi).
  constraint ai_analyses_case_type_fk_check
    check (
      (case_type = 'appeal' and appeal_id is not null and dispute_id is null)
      or
      (case_type = 'dispute' and dispute_id is not null and appeal_id is null)
    )
);

create index ai_analyses_appeal_id_idx on public.ai_analyses (appeal_id);
create index ai_analyses_dispute_id_idx on public.ai_analyses (dispute_id);
create index ai_analyses_created_at_idx on public.ai_analyses (created_at);

-- =============================================================================
-- 9. laws
-- (docs/DATABASE.md, 9-jadval)
-- =============================================================================

create table public.laws (
  id uuid primary key default gen_random_uuid(),
  code_name text not null,
  article_number text not null,
  title text,
  summary_text text not null,
  source_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index laws_code_name_article_number_key on public.laws (code_name, article_number);

-- AI'ning tegishli moddani tez topishi uchun full-text qidiruv indeksi
-- (docs/DATABASE.md, 9-jadval, "Indekslar" bo'limi).
create index laws_summary_text_fts_idx on public.laws using gin (to_tsvector('simple', summary_text));

-- =============================================================================
-- 10. ai_analysis_law_references
-- (docs/DATABASE.md, 10-jadval)
-- =============================================================================

create table public.ai_analysis_law_references (
  ai_analysis_id uuid not null references public.ai_analyses (id) on delete cascade,
  law_id uuid not null references public.laws (id) on delete restrict,
  created_at timestamptz not null default now(),

  primary key (ai_analysis_id, law_id)
);

create index ai_analysis_law_references_law_id_idx on public.ai_analysis_law_references (law_id);

-- =============================================================================
-- 11. attachments
-- (docs/DATABASE.md, 11-jadval)
-- =============================================================================

create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  case_type public.case_type not null,
  appeal_id uuid references public.appeals (id) on delete cascade,
  dispute_id uuid references public.disputes (id) on delete cascade,
  uploaded_by uuid not null references public.profiles (id),
  storage_path text not null,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null,
  created_at timestamptz not null default now(),

  -- "Mutually exclusive FK" naqshi (docs/DATABASE.md, "Umumiy konventsiyalar" bo'limi).
  constraint attachments_case_type_fk_check
    check (
      (case_type = 'appeal' and appeal_id is not null and dispute_id is null)
      or
      (case_type = 'dispute' and dispute_id is not null and appeal_id is null)
    )
);

create index attachments_appeal_id_idx on public.attachments (appeal_id);
create index attachments_dispute_id_idx on public.attachments (dispute_id);
create index attachments_uploaded_by_idx on public.attachments (uploaded_by);

-- =============================================================================
-- 12. notifications
-- (docs/DATABASE.md, 12-jadval)
-- =============================================================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id),
  case_type public.case_type,
  appeal_id uuid references public.appeals (id) on delete cascade,
  dispute_id uuid references public.disputes (id) on delete cascade,
  title text not null,
  body_text text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),

  -- "Mutually exclusive FK" naqshi, bu yerda case_type umuman bo'sh (null) bo'lishi
  -- ham mumkin — umumiy tizim xabarlari uchun (docs/DATABASE.md, 12-jadval, "Cheklov").
  constraint notifications_case_type_fk_check
    check (
      (case_type = 'appeal' and appeal_id is not null and dispute_id is null)
      or
      (case_type = 'dispute' and dispute_id is not null and appeal_id is null)
      or
      (case_type is null and appeal_id is null and dispute_id is null)
    )
);

create index notifications_recipient_id_is_read_idx on public.notifications (recipient_id, is_read);
create index notifications_appeal_id_idx on public.notifications (appeal_id);
create index notifications_dispute_id_idx on public.notifications (dispute_id);
create index notifications_created_at_idx on public.notifications (created_at);

-- =============================================================================
-- 13. audit_log
-- (docs/DATABASE.md, 13-jadval)
-- =============================================================================

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id),
  action text not null,
  entity_type text not null,
  entity_id uuid not null,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index audit_log_entity_type_entity_id_idx on public.audit_log (entity_type, entity_id);
create index audit_log_actor_id_idx on public.audit_log (actor_id);
create index audit_log_created_at_idx on public.audit_log (created_at);

-- =============================================================================
-- Row Level Security — yoqish (deny-all, hali siyosatsiz)
--
-- Har bir jadvalda RLS yoqiladi, lekin hech qanday siyosat (policy) hali
-- qo'shilmaydi. RLS yoqilgan, lekin siyosati bo'lmagan jadvalga hech kim
-- (service role'dan tashqari) kira olmaydi — bu "fail-closed" xavfsiz
-- boshlang'ich holat. Haqiqiy SELECT/INSERT/UPDATE/DELETE siyosatlari
-- keyingi migratsiyada qo'shiladi (docs/SECURITY.md, "Supabase RLS
-- Security" bo'limi).
-- =============================================================================

alter table public.profiles enable row level security;
alter table public.organization_profiles enable row level security;
alter table public.legal_categories enable row level security;
alter table public.government_bodies enable row level security;
alter table public.appeals enable row level security;
alter table public.disputes enable row level security;
alter table public.case_status_history enable row level security;
alter table public.ai_analyses enable row level security;
alter table public.laws enable row level security;
alter table public.ai_analysis_law_references enable row level security;
alter table public.attachments enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_log enable row level security;
