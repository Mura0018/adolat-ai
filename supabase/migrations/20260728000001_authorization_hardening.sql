-- Pre-Phase 6 Hardening Sprint — Priority 2: case ownership/authorization
-- uchun yagona haqiqat manbai (single source of truth).
--
-- Bu migratsiya xatti-harakatni O'ZGARTIRMAYDI (pure refactor): 20260726000002
-- va 20260726000003 migratsiyalaridagi barcha admin_check/egalik tekshiruv
-- subquery'lari qayta ishlatiladigan SQL funksiyalariga ko'chiriladi.
--
-- Bundan tashqari, appeals_update policysiga 20260727000002 (hech qachon
-- commit qilinmagan, endi shu migratsiyaga birlashtirilgan) da aniqlangan
-- tuzatish kiritiladi: muallif o'z murojaatini 'draft' -> 'submitted'
-- holatiga o'tkaza olishi kerak (docs/ARCHITECTURE.md, "Case Lifecycle").
--
-- MUHIM — rekursiya xavfsizligi:
-- `is_admin()` SECURITY DEFINER qilib belgilangan, shuning uchun uning ichki
-- so'rovi profiles jadvalining RLS siyosatiga umuman bog'liq emas — bu
-- rekursiya ehtimolini butunlay yo'q qiladi (faqat boolean qaytaradi, hech
-- qanday qator ma'lumotini oshkor qilmaydi).
-- `owns_appeal()` va `is_dispute_party()` SECURITY INVOKER — ular faqat
-- BOSHQA jadvallar (case_status_history, ai_analyses, attachments, storage)
-- siyosatlarida ishlatiladi, appeals/disputes jadvalining O'Z siyosatlarida
-- ESLATMA sifatida ISHLATILMAYDI — aks holda o'z-o'ziga bog'liq rekursiya
-- xavfi tug'iladi. appeals/disputes jadvalining o'z siyosatlari joriy
-- qatorga to'g'ridan-to'g'ri ustun solishtirishni davom ettiradi
-- (masalan, `author_id = auth.uid()`).

-- ---------------------------------------------------------------------------
-- 1. Avtorizatsiya yordamchi funksiyalari
-- ---------------------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.owns_appeal(target_appeal_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1 from public.appeals
    where id = target_appeal_id and author_id = auth.uid()
  );
$$;

create or replace function public.is_dispute_party(target_dispute_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1 from public.disputes
    where id = target_dispute_id
      and (initiator_id = auth.uid() or respondent_profile_id = auth.uid())
  );
$$;

create or replace function public.can_access_case(
  p_case_type public.case_type,
  p_appeal_id uuid,
  p_dispute_id uuid
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    public.is_admin()
    or (
      p_case_type = 'appeal'
      and p_appeal_id is not null
      and public.owns_appeal(p_appeal_id)
    )
    or (
      p_case_type = 'dispute'
      and p_dispute_id is not null
      and public.is_dispute_party(p_dispute_id)
    );
$$;

-- ---------------------------------------------------------------------------
-- 2. profiles
-- ---------------------------------------------------------------------------

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
for select
to authenticated
using (
  id = auth.uid() or public.is_admin()
);

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
for update
to authenticated
using (
  id = auth.uid() or public.is_admin()
)
with check (
  public.is_admin()
  or (
    id = auth.uid()
    and role = (
      select p_old.role from public.profiles p_old where p_old.id = profiles.id
    )
  )
);

-- ---------------------------------------------------------------------------
-- 3. organization_profiles
-- ---------------------------------------------------------------------------

drop policy if exists organization_profiles_select on public.organization_profiles;
create policy organization_profiles_select on public.organization_profiles
for select
to authenticated
using (
  profile_id = auth.uid() or public.is_admin()
);

drop policy if exists organization_profiles_update on public.organization_profiles;
create policy organization_profiles_update on public.organization_profiles
for update
to authenticated
using (
  profile_id = auth.uid() or public.is_admin()
)
with check (
  profile_id = auth.uid() or public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 4. legal_categories
-- ---------------------------------------------------------------------------

drop policy if exists legal_categories_insert_admin on public.legal_categories;
create policy legal_categories_insert_admin on public.legal_categories
for insert
to authenticated
with check (
  public.is_admin()
);

drop policy if exists legal_categories_update_admin on public.legal_categories;
create policy legal_categories_update_admin on public.legal_categories
for update
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 5. government_bodies
-- ---------------------------------------------------------------------------

drop policy if exists government_bodies_insert_admin on public.government_bodies;
create policy government_bodies_insert_admin on public.government_bodies
for insert
to authenticated
with check (
  public.is_admin()
);

drop policy if exists government_bodies_update_admin on public.government_bodies;
create policy government_bodies_update_admin on public.government_bodies
for update
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 6. appeals (author_id = auth.uid() to'g'ridan-to'g'ri solishtiruv sifatida
-- qoladi — bu jadvalning o'z siyosatida owns_appeal() ISHLATILMAYDI, aks
-- holda o'z-o'ziga bog'liq rekursiya xavfi bo'ladi)
-- ---------------------------------------------------------------------------

drop policy if exists appeals_select on public.appeals;
create policy appeals_select on public.appeals
for select
to authenticated
using (
  author_id = auth.uid() or public.is_admin()
);

-- appeals_update: 20260727000002 dagi tuzatish shu yerga birlashtirildi —
-- muallif qoralamani tahrirlashi ('draft') VA uni yuborishi ('draft' ->
-- 'submitted') mumkin, lekin rasmiy javob kelgandan keyin (official_response_text
-- to'ldirilgach) o'zgartira olmaydi.
drop policy if exists appeals_update on public.appeals;
create policy appeals_update on public.appeals
for update
to authenticated
using (
  (author_id = auth.uid() and status = 'draft') or public.is_admin()
)
with check (
  public.is_admin()
  or (
    author_id = auth.uid()
    and status in ('draft', 'submitted')
    and official_response_text is null
  )
);

-- ---------------------------------------------------------------------------
-- 7. disputes (initiator_id/respondent_profile_id to'g'ridan-to'g'ri
-- solishtiruv sifatida qoladi — shu sababli disputes_update_initiator/
-- disputes_update_respondent o'zgarishsiz qoladi)
-- ---------------------------------------------------------------------------

drop policy if exists disputes_select on public.disputes;
create policy disputes_select on public.disputes
for select
to authenticated
using (
  initiator_id = auth.uid()
  or respondent_profile_id = auth.uid()
  or public.is_admin()
);

drop policy if exists disputes_update_admin on public.disputes;
create policy disputes_update_admin on public.disputes
for update
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 8. case_status_history
-- ---------------------------------------------------------------------------

drop policy if exists case_status_history_select on public.case_status_history;
create policy case_status_history_select on public.case_status_history
for select
to authenticated
using (
  public.can_access_case(case_type, appeal_id, dispute_id)
);

drop policy if exists case_status_history_insert_admin on public.case_status_history;
create policy case_status_history_insert_admin on public.case_status_history
for insert
to authenticated
with check (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 9. ai_analyses
-- ---------------------------------------------------------------------------

drop policy if exists ai_analyses_select on public.ai_analyses;
create policy ai_analyses_select on public.ai_analyses
for select
to authenticated
using (
  public.can_access_case(case_type, appeal_id, dispute_id)
);

-- ---------------------------------------------------------------------------
-- 10. laws
-- ---------------------------------------------------------------------------

drop policy if exists laws_insert_admin on public.laws;
create policy laws_insert_admin on public.laws
for insert
to authenticated
with check (
  public.is_admin()
);

drop policy if exists laws_update_admin on public.laws;
create policy laws_update_admin on public.laws
for update
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

drop policy if exists laws_delete_admin on public.laws;
create policy laws_delete_admin on public.laws
for delete
to authenticated
using (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 11. ai_analysis_law_references
-- ---------------------------------------------------------------------------

drop policy if exists ai_analysis_law_references_select on public.ai_analysis_law_references;
create policy ai_analysis_law_references_select on public.ai_analysis_law_references
for select
to authenticated
using (
  exists (
    select 1 from public.ai_analyses ai
    where ai.id = ai_analysis_law_references.ai_analysis_id
      and public.can_access_case(ai.case_type, ai.appeal_id, ai.dispute_id)
  )
);

-- ---------------------------------------------------------------------------
-- 12. attachments
-- ---------------------------------------------------------------------------

drop policy if exists attachments_select on public.attachments;
create policy attachments_select on public.attachments
for select
to authenticated
using (
  public.can_access_case(case_type, appeal_id, dispute_id)
);

drop policy if exists attachments_insert on public.attachments;
create policy attachments_insert on public.attachments
for insert
to authenticated
with check (
  uploaded_by = auth.uid()
  and public.can_access_case(case_type, appeal_id, dispute_id)
);

-- attachments_delete: "biriktiruvchi + ish hali yopilmagan" tekshiruvi
-- can_access_case()dan farqli — bu yerda muhim narsa keng "ish ishtirokchisi"
-- emas, balki aynan "faylni YUKLAGAN shaxs" ekanligi, shuning uchun bu qism
-- o'z holicha aniq (inline) qoladi, faqat admin_check is_admin()ga ko'chirildi.
drop policy if exists attachments_delete on public.attachments;
create policy attachments_delete on public.attachments
for delete
to authenticated
using (
  public.is_admin()
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

-- ---------------------------------------------------------------------------
-- 13. audit_log
-- ---------------------------------------------------------------------------

drop policy if exists audit_log_select_admin on public.audit_log;
create policy audit_log_select_admin on public.audit_log
for select
to authenticated
using (
  public.is_admin()
);

-- ---------------------------------------------------------------------------
-- 14. storage.objects (case-attachments) — can_access_case() BU YERDA
-- ISHLATILMAYDI: case_type storage yo'lidan olingan xom text segment
-- (`(storage.foldername(name))[1]`), uni public.case_type enumiga cast
-- qilish keraksiz xavf qo'shadi. Shu sababli mavjud xavfsiz text
-- solishtiruv + UUID regex guard + cast tuzilmasi saqlanadi, faqat
-- admin_check/egalik subquery'lari funksiyalarga almashtiriladi.
-- ---------------------------------------------------------------------------

drop policy if exists case_attachments_select on storage.objects;
create policy case_attachments_select on storage.objects
for select
to authenticated
using (
  bucket_id = 'case-attachments'
  and (
    public.is_admin()
    or (
      (storage.foldername(name))[1] = 'appeal'
      and (storage.foldername(name))[2] ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and public.owns_appeal(((storage.foldername(name))[2])::uuid)
    )
    or (
      (storage.foldername(name))[1] = 'dispute'
      and (storage.foldername(name))[2] ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and public.is_dispute_party(((storage.foldername(name))[2])::uuid)
    )
  )
);

drop policy if exists case_attachments_insert on storage.objects;
create policy case_attachments_insert on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'case-attachments'
  and (
    public.is_admin()
    or (
      (storage.foldername(name))[1] = 'appeal'
      and (storage.foldername(name))[2] ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and public.owns_appeal(((storage.foldername(name))[2])::uuid)
    )
    or (
      (storage.foldername(name))[1] = 'dispute'
      and (storage.foldername(name))[2] ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and public.is_dispute_party(((storage.foldername(name))[2])::uuid)
    )
  )
);

drop policy if exists case_attachments_delete on storage.objects;
create policy case_attachments_delete on storage.objects
for delete
to authenticated
using (
  bucket_id = 'case-attachments'
  and (
    public.is_admin()
    or (
      owner = auth.uid()
      and (
        (
          (storage.foldername(name))[1] = 'appeal'
          and (storage.foldername(name))[2] ~
            '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
          and exists (
            select 1 from public.appeals a
            where a.id = ((storage.foldername(name))[2])::uuid
              and a.status <> 'closed'
          )
        )
        or (
          (storage.foldername(name))[1] = 'dispute'
          and (storage.foldername(name))[2] ~
            '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
          and exists (
            select 1 from public.disputes d
            where d.id = ((storage.foldername(name))[2])::uuid
              and d.status <> 'closed'
          )
        )
      )
    )
  )
);
