-- Adolat AI — Storage foundation
--
-- Manba: docs/DATABASE.md (11-jadval `attachments`, "RLS talablari" va
--        "Boshqa jadvallar bilan bog'lanishi" bo'limlari)
--        docs/SECURITY.md ("File Upload Security" bo'limi)
--
-- Ko'lam (scope) — FAQAT quyidagilar:
--   - Supabase Storage bucket yaratish va sozlash (privacy, ruxsat etilgan
--     fayl turlari, maksimal hajm)
--   - storage.objects uchun RLS siyosatlari
--
-- Ushbu migratsiya FAQAT murojaat/nizoga biriktirilgan dalil fayllari
-- (`public.attachments` jadvaliga mos) uchun bucket yaratadi. Profil rasmi
-- (`profiles.avatar_url`) uchun alohida bucket ATAYLAB YARATILMADI — bu
-- haqda DATABASE.md/SECURITY.md'da aniq RLS/privacy talabi yo'q; loyiha
-- egasi tasdig'i bilan bu ko'lamdan tashqarida qoldirildi.
--
-- Bu migratsiyada YO'Q:
--   - Jadval sxemasi o'zgarishi yoki yangi jadval
--   - Oldingi migratsiyalardagi (public.* jadvallar) RLS siyosatlarini
--     o'zgartirish
--   - Trigger, funksiya, seed ma'lumot
--
-- Fayl yo'li (storage_path) konventsiyasi — DATABASE.md aniq yo'l formatini
-- belgilamagan; siyosatlarni amalga oshirish uchun quyidagi konventsiya
-- ushbu migratsiyada qabul qilinadi va hujjatlashtiriladi:
--
--     {case_type}/{case_id}/{fayl_nomi}
--
--     masalan: appeal/3fa85f64-5717-4562-b3fc-2c963f66afa6/dalil.pdf
--              dispute/7c9e6679-7425-40de-944b-e07fc1f90ae7/xat.pdf
--
-- `case_type` qat'iy ravishda 'appeal' yoki 'dispute' (public.case_type
-- enum qiymatlariga mos), `case_id` esa tegishli appeals.id yoki
-- disputes.id. Bu konventsiya RLS siyosatlarida standart Supabase
-- funksiyasi `storage.foldername(name)` orqali o'qiladi (funksiya
-- yaratilmaydi — Supabase Storage kengaytmasi tomonidan oldindan
-- ta'minlangan tayyor funksiya ishlatiladi, xuddi `auth.uid()` kabi).
-- Bu yondashuv `public.attachments` yozuvi hali mavjud bo'lmagan holatda
-- ham (masalan fayl DB yozuvidan oldin yuklanganda) egalikni to'g'ridan-
-- to'g'ri `appeals`/`disputes` jadvaliga tekshirish orqali aniqlash
-- imkonini beradi.

-- =============================================================================
-- Bucket yaratish va sozlash
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'case-attachments',
  'case-attachments',
  false, -- private: RLS siyosatlarisiz hech kim (service role'dan tashqari)
         -- kira olmaydi (docs/SECURITY.md, "File Upload Security" bo'limi)
  10485760, -- 10 MB — DATABASE.md/SECURITY.md aniq son belgilamagan;
            -- oqilona standart qiymat sifatida tanlandi, kelgusida loyiha
            -- talabiga qarab qayta ko'rib chiqilishi kerak
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ] -- docs/SECURITY.md, "File Upload Security": "rasm va PDF formatlari"
);

-- storage.objects'da RLS Supabase tomonidan standart holatda allaqachon
-- yoqilgan bo'ladi; bu yerda aniqlik va takrorlanuvchanlik uchun qayta
-- tasdiqlanadi (idempotent — xato bermaydi).
alter table storage.objects enable row level security;

-- =============================================================================
-- storage.objects — RLS siyosatlari (faqat 'case-attachments' bucket uchun)
-- =============================================================================

-- SELECT (ko'rish/yuklab olish): tegishli appeal/dispute egasi (dispute
-- uchun ikkala tomon) va admin — public.attachments_select siyosati bilan
-- bir xil egalik mantig'i, lekin fayl yo'lidagi (case_type/case_id)
-- ma'lumotdan o'qiladi.
create policy case_attachments_select on storage.objects
for select
to authenticated
using (
  bucket_id = 'case-attachments'
  and (
    exists (
      select 1 from public.profiles admin_check
      where admin_check.id = auth.uid() and admin_check.role = 'admin'
    )
    or (
      (storage.foldername(name))[1] = 'appeal'
      and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and exists (
        select 1 from public.appeals a
        where a.id = ((storage.foldername(name))[2])::uuid
        and a.author_id = auth.uid()
      )
    )
    or (
      (storage.foldername(name))[1] = 'dispute'
      and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and exists (
        select 1 from public.disputes d
        where d.id = ((storage.foldername(name))[2])::uuid
        and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
      )
    )
  )
);

-- INSERT (yuklash): tegishli appeal/dispute egasi (dispute uchun ikkala
-- tomon) va admin — public.attachments_insert siyosati bilan bir xil
-- egalik mantig'i. Fayl turi va hajmi yuqoridagi bucket sozlamalari
-- (allowed_mime_types, file_size_limit) orqali Storage darajasida
-- avtomatik ta'minlanadi.
create policy case_attachments_insert on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'case-attachments'
  and (
    exists (
      select 1 from public.profiles admin_check
      where admin_check.id = auth.uid() and admin_check.role = 'admin'
    )
    or (
      (storage.foldername(name))[1] = 'appeal'
      and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and exists (
        select 1 from public.appeals a
        where a.id = ((storage.foldername(name))[2])::uuid
        and a.author_id = auth.uid()
      )
    )
    or (
      (storage.foldername(name))[1] = 'dispute'
      and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      and exists (
        select 1 from public.disputes d
        where d.id = ((storage.foldername(name))[2])::uuid
        and (d.initiator_id = auth.uid() or d.respondent_profile_id = auth.uid())
      )
    )
  )
);

-- DELETE: faqat yuklagan foydalanuvchi (agar tegishli case hali
-- yopilmagan bo'lsa) yoki admin — public.attachments_delete siyosati
-- bilan bir xil mantiq. Yuklovchi Supabase tomonidan avtomatik
-- belgilanadigan `storage.objects.owner` ustuni orqali aniqlanadi.
create policy case_attachments_delete on storage.objects
for delete
to authenticated
using (
  bucket_id = 'case-attachments'
  and (
    exists (
      select 1 from public.profiles admin_check
      where admin_check.id = auth.uid() and admin_check.role = 'admin'
    )
    or (
      owner = auth.uid()
      and (
        (
          (storage.foldername(name))[1] = 'appeal'
          and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
          and exists (
            select 1 from public.appeals a
            where a.id = ((storage.foldername(name))[2])::uuid
            and a.status <> 'closed'
          )
        )
        or (
          (storage.foldername(name))[1] = 'dispute'
          and (storage.foldername(name))[2] ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
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

-- UPDATE: yo'q — public.attachments jadvalida ham UPDATE siyosati yo'q
-- (fayl metadatasi tahrirlanmaydi, faqat o'chirib qayta yuklanadi); shu
-- tamoyil Storage darajasida ham qo'llaniladi.

-- service_role: alohida siyosat kerak emas — Supabase'da service_role
-- RLS'ni butunlay chetlab o'tadi (bypass), shuning uchun u 'case-attachments'
-- bucket'idagi istalgan faylda cheklovsiz amal bajara oladi.
