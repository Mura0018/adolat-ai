-- Adolat AI — Authentication foundation
--
-- Manba: docs/DATABASE.md (1-jadval `profiles`, 2-jadval `organization_profiles`)
--        docs/SECURITY.md ("Autentifikatsiya", "Avtorizatsiya" bo'limlari)
--        docs/ARCHITECTURE.md ("Authentication Flow" bo'limi)
--
-- Ko'lam (scope) — Supabase Auth.
--
-- MUHIM ESLATMA — quyidagi talablarning aksariyati SQL migratsiyasi orqali
-- amalga oshirilmaydi, chunki ular Supabase **platforma darajasidagi**
-- sozlamalar (loyiha Dashboard'i yoki `supabase/config.toml` orqali
-- boshqariladi), jadval/funksiya emas:
--
--   - Email/password autentifikatsiya — Supabase Auth'da standart yoqilgan
--     provayder; qo'shimcha SQL talab qilmaydi.
--   - Email tasdiqlash — Auth loyihasi sozlamalarida (`Confirm email`)
--     yoqiladi; email shabloni Dashboard/`config.toml`da sozlanadi.
--   - Parolni tiklash oqimi — Supabase Auth'ning tayyor
--     `resetPasswordForEmail` / recovery oqimi orqali ishlaydi, alohida
--     SQL kerak emas.
--   - Xavfsiz sessiya boshqaruvi (JWT/refresh token muddati, rotatsiya) —
--     Auth loyihasi sozlamalarida (`JWT expiry`, `Refresh token reuse
--     interval`) belgilanadi.
--
-- Ushbu migratsiyaning SQL orqali haqiqatan ham amalga oshiriladigan
-- yagona qismi — **profilni avtomatik yaratish va auth.users bilan
-- public.profiles'ni bog'lash** (quyida). Bu ilgari (20260726000001)
-- migratsiyasida ataylab qoldirilgan trigger.
--
-- Ko'lamda emas (Do NOT ro'yxatiga muvofiq):
--   - Oldingi migratsiyalarni o'zgartirish
--   - Mavjud RLS siyosatlarini o'zgartirish (yangi jadval uchun ham yangi
--     RLS siyosati qo'shilmaydi — trigger funksiyasi SECURITY DEFINER
--     sifatida ishlaydi va RLS'ni to'g'ridan-to'g'ri chetlab o'tadi,
--     xuddi service role kabi)
--   - Yangi/aloqasiz jadvallar, biznes/AI/to'lov/xabarnoma funksiyalari
--   - Seed ma'lumot

-- =============================================================================
-- public.handle_new_user() — auth.users'ga yozuv qo'shilganda avtomatik
-- ishga tushadigan funksiya
-- =============================================================================
--
-- Rol manbai: klient `supabase.auth.signUp()` chaqiruvida
-- `options.data` orqali quyidagi ixtiyoriy metama'lumotlarni yuborishi
-- mumkin (docs/UI.md, "Authentication Screens" bo'limidagi ro'yxatdan
-- o'tish shakllariga mos):
--
--   role            — 'citizen' yoki 'organization' (boshqa har qanday
--                      qiymat, shu jumladan 'admin', e'tiborga olinmaydi
--                      va xavfsiz standart 'citizen'ga tushadi — bu
--                      ro'yxatdan o'tish orqali admin bo'lib olishning
--                      oldini oladi)
--   full_name       — to'liq ism (bo'sh bo'lsa, email manzili ishlatiladi)
--   phone_number    — ixtiyoriy aloqa telefoni
--   avatar_url      — ixtiyoriy profil rasmi havolasi
--   legal_name      — faqat role='organization' uchun MAJBURIY
--   tax_id          — faqat role='organization' uchun MAJBURIY
--   legal_address   — faqat role='organization' uchun MAJBURIY
--   contact_email   — faqat role='organization' uchun ixtiyoriy
--
-- Agar role='organization' tanlangan bo'lsa-yu, legal_name/tax_id/
-- legal_address'dan biri yo'q yoki bo'sh bo'lsa, funksiya xatolik
-- qaytaradi va BUTUN ro'yxatdan o'tish tranzaksiyasi bekor qilinadi
-- (auth.users yozuvi ham yaratilmaydi). Bu ataylab qilingan, "fail-closed"
-- qaror: to'liqsiz tashkilot ma'lumoti bilan "yarim yaratilgan" hisobni
-- keyinchalik hech kim to'ldira olmasligining oldini oladi — chunki
-- organization_profiles uchun mijoz tomonidan to'g'ridan-to'g'ri INSERT
-- siyosati yo'q (docs bo'yicha faqat shu trigger orqali yaratiladi).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text;
  final_role public.profile_role;
begin
  requested_role := new.raw_user_meta_data ->> 'role';

  if requested_role in ('citizen', 'organization') then
    final_role := requested_role::public.profile_role;
  else
    final_role := 'citizen';
  end if;

  insert into public.profiles (id, role, full_name, phone_number, avatar_url)
  values (
    new.id,
    final_role,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      new.email
    ),
    new.raw_user_meta_data ->> 'phone_number',
    new.raw_user_meta_data ->> 'avatar_url'
  );

  if final_role = 'organization' then
    if
      coalesce(new.raw_user_meta_data ->> 'legal_name', '') = ''
      or coalesce(new.raw_user_meta_data ->> 'tax_id', '') = ''
      or coalesce(new.raw_user_meta_data ->> 'legal_address', '') = ''
    then
      raise exception
        'organization signup requires legal_name, tax_id and legal_address in signUp() metadata';
    end if;

    insert into public.organization_profiles (
      profile_id, legal_name, tax_id, legal_address, contact_email
    )
    values (
      new.id,
      new.raw_user_meta_data ->> 'legal_name',
      new.raw_user_meta_data ->> 'tax_id',
      new.raw_user_meta_data ->> 'legal_address',
      new.raw_user_meta_data ->> 'contact_email'
    );
  end if;

  return new;
end;
$$;

-- =============================================================================
-- Trigger — har bir yangi auth.users yozuvidan keyin ishga tushadi
-- =============================================================================

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
