-- Adolat AI — Row Level Security policies
--
-- Manba: docs/DATABASE.md (har bir jadvalning "RLS talablari" bo'limi)
--        docs/SECURITY.md ("Avtorizatsiya" va "Supabase RLS Security" bo'limlari)
--
-- Ko'lam (scope) — FAQAT quyidagilar:
--   - Barcha 13 jadval uchun RLS siyosatlari (CREATE POLICY)
--
-- RLS'ning o'zi (ENABLE ROW LEVEL SECURITY) allaqachon birinchi migratsiyada
-- (20260726000001_initial_schema_foundation.sql) yoqilgan — bu migratsiya
-- faqat siyosatlarni qo'shadi. Jadval sxemasi, trigger, funksiya yoki
-- seed ma'lumot BU YERDA O'ZGARTIRILMAYDI/QO'SHILMAYDI.
--
-- Rol modeli haqida eslatma (docs/SECURITY.md, "Avtorizatsiya" bo'limi):
--   Supabase darajasida faqat bitta "authenticated" Postgres roli mavjud —
--   Fuqaro, Tashkilot va Admin barchasi shu bitta rol ostida ishlaydi;
--   ular orasidagi farq faqat `profiles.role` ustunidagi qiymat orqali
--   aniqlanadi. Shuning uchun:
--     - "Citizen" va "Organization" uchun alohida-alohida siyosat YOZILMAYDI —
--       ikkalasi ham SECURITY.md'ga muvofiq "bir xil huquqqa ega" bo'lgani
--       uchun bitta umumiy egalik-asosidagi (ownership-based) siyosat
--       ikkalasini ham qamrab oladi.
--     - "Admin" tekshiruvi har bir kerakli siyosatda quyidagi bir xil
--       ichki so'rov (subquery) orqali amalga oshiriladi (funksiya
--       yaratilmagani sababli har joyda takrorlanadi):
--
--         exists (
--           select 1 from public.profiles admin_check
--           where admin_check.id = auth.uid() and admin_check.role = 'admin'
--         )
--
--       Bu so'rov xavfsiz: `profiles` jadvalining o'z SELECT siyosati
--       (`id = auth.uid()`) har doim foydalanuvchining o'z qatorini o'qishga
--       ruxsat beradi, shuning uchun bu ichki so'rov cheksiz rekursiyaga
--       olib kelmaydi.
--     - "Service role" orqali bajariladigan amallar (masalan `ai_analyses`,
--       `audit_log`ga yozish) uchun siyosat YOZILMAYDI — Supabase'da
--       `service_role` RLS'ni butunlay chetlab o'tadi (bypass), shuning
--       uchun bunday amallar uchun `authenticated` rolига hech qanday
--       siyosat berilmasa, ular avtomatik ravishda taqiqlangan bo'ladi.

-- =============================================================================
-- 1. profiles
-- (docs/DATABASE.md, 1-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: foydalanuvchi faqat o'z qatorini ko'radi; admin — barchasini.
create policy profiles_select on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- INSERT: yo'q — yozuv auth.users yaratilganda faqat service role/trigger
-- orqali hosil bo'ladi (client to'g'ridan-to'g'ri insert qila olmaydi).

-- UPDATE: foydalanuvchi o'z qatorini yangilaydi, lekin `role`ni o'zgartira
-- olmaydi; admin istalgan qatorni (rol bilan birga) yangilaydi.
create policy profiles_update on public.profiles
for update
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (
    id = auth.uid()
    and role = (
      select p_old.role from public.profiles p_old where p_old.id = profiles.id
    )
  )
);

-- DELETE: yo'q — taqiqlanadi (auth.users o'chirilganda cascade orqali).

-- =============================================================================
-- 2. organization_profiles
-- (docs/DATABASE.md, 2-jadval, "RLS talablari")
-- =============================================================================

-- profiles bilan bir xil egalik mantig'i — egasi (profile_id = auth.uid())
-- va admin ko'radi/tahrirlaydi; boshqa foydalanuvchilarga yopiq.
create policy organization_profiles_select on public.organization_profiles
for select
to authenticated
using (
  profile_id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

create policy organization_profiles_update on public.organization_profiles
for update
to authenticated
using (
  profile_id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  profile_id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- INSERT/DELETE: yo'q — hujjatda faqat "ko'radi/tahrirlaydi" (SELECT/UPDATE)
-- belgilangan; yaratish profil yaratish oqimining bir qismi sifatida
-- service role orqali amalga oshiriladi.

-- =============================================================================
-- 3. legal_categories
-- (docs/DATABASE.md, 3-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: barcha autentifikatsiyalangan foydalanuvchilarga ochiq (lug'at jadvali).
create policy legal_categories_select on public.legal_categories
for select
to authenticated
using (true);

-- INSERT/UPDATE: faqat admin.
create policy legal_categories_insert_admin on public.legal_categories
for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

create policy legal_categories_update_admin on public.legal_categories
for update
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- DELETE: yo'q — taqiqlanadi (faqat is_active = false bilan yumshoq o'chiriladi).

-- =============================================================================
-- 4. government_bodies
-- (docs/DATABASE.md, 4-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: public read (autentifikatsiyalangan foydalanuvchilar).
create policy government_bodies_select on public.government_bodies
for select
to authenticated
using (true);

-- INSERT/UPDATE: faqat admin.
create policy government_bodies_insert_admin on public.government_bodies
for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

create policy government_bodies_update_admin on public.government_bodies
for update
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- DELETE: yo'q — taqiqlanadi (faqat is_active = false bilan yumshoq o'chiriladi).

-- =============================================================================
-- 5. appeals
-- (docs/DATABASE.md, 5-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: author_id = auth.uid() bo'lgan foydalanuvchi o'z murojaatini
-- ko'radi; admin — barchasini.
create policy appeals_select on public.appeals
for select
to authenticated
using (
  author_id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- INSERT: faqat author_id = auth.uid() bilan yaratish mumkin.
create policy appeals_insert on public.appeals
for insert
to authenticated
with check (author_id = auth.uid());

-- UPDATE: status = 'draft' bo'lganda faqat muallif tahrirlaydi; admin
-- istalgan holatda yangilay oladi (status/official_response_text va h.k.).
create policy appeals_update on public.appeals
for update
to authenticated
using (
  (author_id = auth.uid() and status = 'draft')
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (author_id = auth.uid() and status = 'draft')
);

-- DELETE: faqat draft holatidagi o'z yozuvini muallif o'chira oladi.
create policy appeals_delete on public.appeals
for delete
to authenticated
using (author_id = auth.uid() and status = 'draft');

-- =============================================================================
-- 6. disputes
-- (docs/DATABASE.md, 6-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: initiator_id = auth.uid() YOKI respondent_profile_id = auth.uid()
-- bo'lgan foydalanuvchi ko'radi; admin — barchasini.
create policy disputes_select on public.disputes
for select
to authenticated
using (
  initiator_id = auth.uid()
  or respondent_profile_id = auth.uid()
  or exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- INSERT: faqat initiator_id = auth.uid() bilan yaratish mumkin.
create policy disputes_insert on public.disputes
for insert
to authenticated
with check (initiator_id = auth.uid());

-- UPDATE — uchta alohida siyosat, har biri o'z egasi bilan cheklangan:
--   (a) initiator: title/description, faqat status = 'open' bo'lganda,
--       respondent_statement o'zgarishsiz qolishi shart;
--   (b) respondent: respondent_statement, status IN ('open','ai_analyzing')
--       bo'lganda, title/description o'zgarishsiz qolishi shart;
--   (c) admin: cheklovsiz (status ham faqat shu yo'l — yoki service role —
--       orqali o'zgaradi).
create policy disputes_update_initiator on public.disputes
for update
to authenticated
using (initiator_id = auth.uid() and status = 'open')
with check (
  initiator_id = auth.uid()
  and status = 'open'
  and respondent_statement is not distinct from (
    select d_old.respondent_statement from public.disputes d_old where d_old.id = disputes.id
  )
);

create policy disputes_update_respondent on public.disputes
for update
to authenticated
using (respondent_profile_id = auth.uid() and status in ('open', 'ai_analyzing'))
with check (
  respondent_profile_id = auth.uid()
  and status = (select d_old.status from public.disputes d_old where d_old.id = disputes.id)
  and title = (select d_old.title from public.disputes d_old where d_old.id = disputes.id)
  and description = (select d_old.description from public.disputes d_old where d_old.id = disputes.id)
);

create policy disputes_update_admin on public.disputes
for update
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- DELETE: faqat open holatida initiator tomonidan.
create policy disputes_delete on public.disputes
for delete
to authenticated
using (initiator_id = auth.uid() and status = 'open');

-- =============================================================================
-- 7. case_status_history
-- (docs/DATABASE.md, 7-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: tegishli appeal/dispute egasi (dispute uchun ikkala tomon) va admin.
create policy case_status_history_select on public.case_status_history
for select
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (
    case_type = 'appeal'
    and exists (
      select 1 from public.appeals a
      where a.id = case_status_history.appeal_id and a.author_id = auth.uid()
    )
  )
  or (
    case_type = 'dispute'
    and exists (
      select 1 from public.disputes d
      where d.id = case_status_history.dispute_id
      and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
    )
  )
);

-- INSERT: faqat service role yoki admin.
create policy case_status_history_insert_admin on public.case_status_history
for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- UPDATE/DELETE: yo'q — taqiqlanadi (o'zgarmas audit yozuvi).

-- =============================================================================
-- 8. ai_analyses
-- (docs/DATABASE.md, 8-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: tegishli appeal/dispute egasi (dispute uchun ikkala tomon) va admin.
create policy ai_analyses_select on public.ai_analyses
for select
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (
    case_type = 'appeal'
    and exists (
      select 1 from public.appeals a
      where a.id = ai_analyses.appeal_id and a.author_id = auth.uid()
    )
  )
  or (
    case_type = 'dispute'
    and exists (
      select 1 from public.disputes d
      where d.id = ai_analyses.dispute_id
      and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
    )
  )
);

-- INSERT/UPDATE/DELETE: yo'q — **faqat service role** (admin ham client
-- sifatida yoza olmaydi; AI xulosasini soxtalashtirish xavfini oldini olish
-- uchun bu yerda admin uchun ham insert siyosati qo'shilmaydi).

-- =============================================================================
-- 9. laws
-- (docs/DATABASE.md, 9-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: public read (barcha autentifikatsiyalangan foydalanuvchi).
create policy laws_select on public.laws
for select
to authenticated
using (true);

-- INSERT/UPDATE/DELETE: faqat admin.
create policy laws_insert_admin on public.laws
for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

create policy laws_update_admin on public.laws
for update
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
)
with check (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

create policy laws_delete_admin on public.laws
for delete
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- =============================================================================
-- 10. ai_analysis_law_references
-- (docs/DATABASE.md, 10-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: ai_analyses uchun RLS bilan bir xil egalik mantig'i, parent
-- jadval (ai_analyses) orqali meros qilib olinadi.
create policy ai_analysis_law_references_select on public.ai_analysis_law_references
for select
to authenticated
using (
  exists (
    select 1 from public.ai_analyses ai
    where ai.id = ai_analysis_law_references.ai_analysis_id
    and (
      exists (
        select 1 from public.profiles admin_check
        where admin_check.id = auth.uid() and admin_check.role = 'admin'
      )
      or (
        ai.case_type = 'appeal'
        and exists (
          select 1 from public.appeals a
          where a.id = ai.appeal_id and a.author_id = auth.uid()
        )
      )
      or (
        ai.case_type = 'dispute'
        and exists (
          select 1 from public.disputes d
          where d.id = ai.dispute_id
          and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
        )
      )
    )
  )
);

-- INSERT/UPDATE/DELETE: yo'q — faqat service role.

-- =============================================================================
-- 11. attachments
-- (docs/DATABASE.md, 11-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: tegishli appeal/dispute egasi (dispute uchun ikkala tomon) va admin.
create policy attachments_select on public.attachments
for select
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (
    case_type = 'appeal'
    and exists (
      select 1 from public.appeals a
      where a.id = attachments.appeal_id and a.author_id = auth.uid()
    )
  )
  or (
    case_type = 'dispute'
    and exists (
      select 1 from public.disputes d
      where d.id = attachments.dispute_id
      and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
    )
  )
);

-- INSERT: tegishli appeal/dispute egasi (dispute uchun ikkala tomon) va
-- admin; yuklovchi faqat o'zini uploaded_by sifatida ko'rsata oladi.
create policy attachments_insert on public.attachments
for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and (
    exists (
      select 1 from public.profiles admin_check
      where admin_check.id = auth.uid() and admin_check.role = 'admin'
    )
    or (
      case_type = 'appeal'
      and exists (
        select 1 from public.appeals a
        where a.id = attachments.appeal_id and a.author_id = auth.uid()
      )
    )
    or (
      case_type = 'dispute'
      and exists (
        select 1 from public.disputes d
        where d.id = attachments.dispute_id
        and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
      )
    )
  )
);

-- DELETE: faqat yuklagan foydalanuvchi (agar tegishli case hali yopilmagan
-- bo'lsa) yoki admin.
create policy attachments_delete on public.attachments
for delete
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
  or (
    uploaded_by = auth.uid()
    and (
      (
        case_type = 'appeal'
        and exists (
          select 1 from public.appeals a
          where a.id = attachments.appeal_id and a.status <> 'closed'
        )
      )
      or (
        case_type = 'dispute'
        and exists (
          select 1 from public.disputes d
          where d.id = attachments.dispute_id and d.status <> 'closed'
        )
      )
    )
  )
);

-- UPDATE: yo'q — fayl metadatasi tahrirlanmaydi, faqat o'chirib qayta
-- yuklanadi.

-- =============================================================================
-- 12. notifications
-- (docs/DATABASE.md, 12-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: faqat recipient_id = auth.uid() (admin uchun alohida bypass yo'q —
-- hujjatda shunday belgilangan).
create policy notifications_select on public.notifications
for select
to authenticated
using (recipient_id = auth.uid());

-- UPDATE (is_read belgilash): faqat recipient_id = auth.uid(); xabar
-- mazmuni (title/body_text/case_type/appeal_id/dispute_id) o'zgarishsiz
-- qolishi shart — faqat is_read yangilanadi.
create policy notifications_update on public.notifications
for update
to authenticated
using (recipient_id = auth.uid())
with check (
  recipient_id = auth.uid()
  and title = (select n_old.title from public.notifications n_old where n_old.id = notifications.id)
  and body_text = (select n_old.body_text from public.notifications n_old where n_old.id = notifications.id)
  and case_type is not distinct from (select n_old.case_type from public.notifications n_old where n_old.id = notifications.id)
  and appeal_id is not distinct from (select n_old.appeal_id from public.notifications n_old where n_old.id = notifications.id)
  and dispute_id is not distinct from (select n_old.dispute_id from public.notifications n_old where n_old.id = notifications.id)
);

-- INSERT: yo'q — faqat service role (tizim tomonidan avtomatik generatsiya
-- qilinadi).

-- DELETE: foydalanuvchi o'z xabarini o'chirishi mumkin (ixtiyoriy).
create policy notifications_delete on public.notifications
for delete
to authenticated
using (recipient_id = auth.uid());

-- =============================================================================
-- 13. audit_log
-- (docs/DATABASE.md, 13-jadval, "RLS talablari")
-- =============================================================================

-- SELECT: faqat admin.
create policy audit_log_select_admin on public.audit_log
for select
to authenticated
using (
  exists (
    select 1 from public.profiles admin_check
    where admin_check.id = auth.uid() and admin_check.role = 'admin'
  )
);

-- INSERT/UPDATE/DELETE: yo'q — faqat service role, o'zgarmas audit trail.
