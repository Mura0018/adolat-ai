# DATABASE.md — Adolat AI ma'lumotlar bazasi dizayni (MVP)

Bu hujjat **faqat dizayn hujjati** — SQL yoki kod yo'q. Maqsad: MVP uchun kerak bo'lgan barcha jadvallarni tasdiqlash. Backend **Supabase (PostgreSQL)**.

## MVP doirasi bo'yicha qabul qilingan qarorlar

Loyihalash quyidagi tasdiqlangan ko'lam asosida qilindi:

1. **Ikkala asosiy oqim** qo'llab-quvvatlanadi: (a) davlat organiga murojaat yuborish, (b) ikki tomon o'rtasidagi nizoni AI orqali (tarafsiz) tahlil qilish.
2. **MVP'da faqat AI ishtirok etadi** — yurist/operator roli va tayinlash (assignment) mexanizmi hozircha yo'q.
3. **Fayl/hujjat biriktirish kerak** — dalil va hujjatlar uchun.
4. **Foydalanuvchi rollari:** Fuqaro (`citizen`), Tashkilot (`organization`), Admin (`admin`).

Bu qarorlar `docs/DEVELOPMENT_RULES.md`ga muvofiq hujjatlashtirildi — kelajakda o'zgarsa, shu bo'lim yangilanishi kerak.

## Umumiy konventsiyalar

- **Primary Key:** barcha jadvallarda `uuid` (Supabase standart konventsiyasi), bog'lovchi (junction) jadvaldan tashqari — u composite PK ishlatadi.
- **Vaqt ustunlari:** `created_at` barcha jadvallarda; `updated_at` faqat yozuv holati o'zgarishi mumkin bo'lgan jadvallarda.
- **"Mutually exclusive FK" naqshi:** bir nechta jadval (`case_status_history`, `ai_analyses`, `attachments`, `notifications`) ham `appeals`, ham `disputes` bilan bog'lanishi kerak. Postgresda haqiqiy polimorfik FK yo'qligi sababli, bu jadvallarda **ikkita nullable FK** (`appeal_id`, `dispute_id`) + bitta `case_type` enum ustuni ishlatiladi. Bu invariant **DB darajasidagi CHECK constraint bilan majburiy ta'minlanadi** (ilova darajasidagi tekshiruv bilan emas — aks holda race condition orqali ikkala FK ham to'ldirilishi yoki ikkalasi ham bo'sh qolishi mumkin): (a) `appeal_id` va `dispute_id`dan **aynan bittasi** to'ldirilgan bo'lishi, (b) `case_type` qiymati to'ldirilgan FK'ga mos kelishi shart (`case_type='appeal'` ⇔ `appeal_id IS NOT NULL`). Bu naqsh har bir tegishli jadvalda alohida takrorlanmaydi — shu yerda bir marta tushuntirildi.
- **RLS umumiy strategiyasi:** har bir "egalik" (ownership) asosidagi jadvalda foydalanuvchi faqat `auth.uid()` unga tegishli qatorlarni ko'radi/tahrirlaydi; `admin` roli barcha qatorlarni ko'radi; AI/tizim tomonidan yoziladigan jadvallar (masalan `ai_analyses`, `audit_log`) faqat **service role** orqali yoziladi, client to'g'ridan-to'g'ri yoza olmaydi (soxtalashtirish xavfini oldini olish uchun).

## Jadvallar ro'yxati (tezkor indeks)

| # | Jadval | Maqsadi (bir qatorda) |
|---|---|---|
| 1 | `profiles` | `auth.users`ni kengaytiruvchi umumiy profil va rol |
| 2 | `organization_profiles` | Tashkilot-rolidagi profillarga xos qo'shimcha ma'lumot |
| 3 | `legal_categories` | Murojaat/nizo mavzusi bo'yicha boshqariladigan tasnif |
| 4 | `government_bodies` | Murojaat yuborilishi mumkin bo'lgan davlat organlari ro'yxati |
| 5 | `appeals` | Davlat organiga yuboriladigan murojaat/shikoyat |
| 6 | `disputes` | Ikki tomon o'rtasidagi nizo (AI tahlili uchun) |
| 7 | `case_status_history` | Murojaat/nizo holati o'zgarishlarining audit izi |
| 8 | `ai_analyses` | AI tomonidan berilgan huquqiy tahlil natijasi |
| 9 | `laws` | Iqtibos keltiriladigan qonun moddalari lug'ati |
| 10 | `ai_analysis_law_references` | AI tahlili ↔ qonun moddasi bog'lovchisi (N:N) |
| 11 | `attachments` | Murojaat/nizoga biriktirilgan fayl metadatasi |
| 12 | `notifications` | Foydalanuvchiga muhim voqealar haqida xabar |
| 13 | `audit_log` | Nozik amallarning muvofiqlik (compliance) jurnali |

---

## 1. `profiles`

**Maqsadi:** Supabase `auth.users` jadvalini kengaytirib, ilova ichidagi umumiy profil ma'lumotlari va rolni saqlaydi. Har bir tizim foydalanuvchisi uchun bitta yozuv.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | `auth.users.id` bilan bir xil qiymat |
| `role` | enum (`citizen`, `organization`, `admin`) | Foydalanuvchi roli |
| `full_name` | text | To'liq ism / tashkilot vakili ismi |
| `phone_number` | text, nullable | Aloqa telefoni |
| `avatar_url` | text, nullable | Profil rasmi (Supabase Storage) |
| `created_at` | timestamptz | Yaratilgan vaqti |
| `updated_at` | timestamptz | Oxirgi yangilanish vaqti |

**Primary Key:** `id`

**Foreign Key:** `id` → `auth.users.id` (1:1, `ON DELETE CASCADE`)

**Indexlar:** `role` ustuniga index (admin panelda rol bo'yicha filtrlash uchun)

**RLS talablari:**
- `SELECT`: foydalanuvchi faqat `id = auth.uid()` bo'lgan qatorni ko'radi; `admin` — barchasini
- `INSERT`: to'g'ridan-to'g'ri client insert **taqiqlanadi** — yozuv `auth.users` yaratilganda trigger/service role orqali avtomatik hosil bo'ladi
- `UPDATE`: foydalanuvchi faqat o'z qatorini yangilaydi, lekin `role` ustunini o'zgartira olmaydi (alohida policy yoki trigger bilan cheklanadi); `admin` istalgan qatorni yangilaydi
- `DELETE`: taqiqlanadi (auth.users o'chirilganda cascade orqali)

**Boshqa jadvallar bilan bog'lanishi:** `organization_profiles` (1:1), `appeals.author_id`, `disputes.initiator_id`/`respondent_profile_id`, `attachments.uploaded_by`, `notifications.recipient_id`, `case_status_history.changed_by`, `audit_log.actor_id` — barchasi shu jadvalga FK bilan bog'lanadi (N:1).

---

## 2. `organization_profiles`

**Maqsadi:** `role = organization` bo'lgan profillarga xos qo'shimcha ma'lumotlarni saqlaydi (STIR, yuridik manzil). `profiles` jadvalini fuqarolarga tegishli bo'lmagan ustunlar bilan "bo'kaytirmaslik" uchun alohida jadval.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `profile_id` | uuid | Tegishli profil |
| `legal_name` | text | Tashkilotning rasmiy nomi |
| `tax_id` | text | STIR/INN |
| `legal_address` | text | Yuridik manzil |
| `contact_email` | text, nullable | Rasmiy aloqa email |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

**Primary Key:** `profile_id`

**Foreign Key:** `profile_id` → `profiles.id` (1:1, `ON DELETE CASCADE`)

**Indexlar:** `tax_id` bo'yicha **unique** index (bitta STIR bilan ikkita tashkilot ro'yxatdan o'tmasligi uchun)

**RLS talablari:** `profiles` bilan bir xil egalik mantig'i — egasi (`profile_id = auth.uid()`) va `admin` ko'radi/tahrirlaydi; boshqa foydalanuvchilarga yopiq.

**Boshqa jadvallar bilan bog'lanishi:** `profiles` bilan 1:1.

---

## 3. `legal_categories`

**Maqsadi:** Murojaat va nizolarning huquqiy yo'nalishi bo'yicha boshqariladigan tasnifi (mehnat huquqi, uy-joy, oilaviy, mulkiy va h.k.) — AI tahlili yo'naltirish va statistika uchun.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `name_uz` | text | Kategoriya nomi (o'zbekcha) |
| `name_en` | text, nullable | Kategoriya nomi (inglizcha, lokalizatsiya uchun) |
| `description` | text, nullable | Qisqacha tavsif |
| `is_active` | boolean (default `true`) | Yashirin/faol holati |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** yo'q

**Indexlar:** `name_uz` bo'yicha unique index

**RLS talablari:**
- `SELECT`: barcha autentifikatsiyalangan foydalanuvchilarga ochiq (public read, lug'at jadvali)
- `INSERT`/`UPDATE`: faqat `admin`
- `DELETE`: **taqiqlanadi** (RLS'da DELETE policy umuman berilmaydi). `appeals`/`disputes` bu jadvalga FK bilan bog'langani sababli jismoniy o'chirish tarixiy yozuvlarni buzadi — kategoriya endi kerak bo'lmasa, `admin` uni faqat `is_active = false` qilib "yumshoq o'chiradi"

**Boshqa jadvallar bilan bog'lanishi:** `appeals.category_id`, `disputes.category_id` shu jadvalga FK bilan bog'lanadi (1:N).

---

## 4. `government_bodies`

**Maqsadi:** Murojaat yuborilishi mumkin bo'lgan davlat organlari/muassasalarining boshqariladigan ro'yxati. Bu tashkilotlar tizim foydalanuvchisi **emas** — faqat qabul qiluvchi tomon ma'lumoti sifatida saqlanadi.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `name` | text | Masalan "Adliya vazirligi", "Tuman hokimligi" |
| `region` | text, nullable | Hududiy tegishlilik (agar kerak bo'lsa) |
| `contact_email` | text, nullable | Rasmiy murojaat qabul qilish manzili |
| `is_active` | boolean (default `true`) | |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** yo'q

**Indexlar:** `name` bo'yicha index (tanlash formasida qidiruv uchun)

**RLS talablari:**
- `SELECT`: public read (autentifikatsiyalangan foydalanuvchilar)
- `INSERT`/`UPDATE`: faqat `admin`
- `DELETE`: **taqiqlanadi** (RLS'da DELETE policy umuman berilmaydi) — sababi `legal_categories`dagi bilan bir xil: `appeals` bu jadvalga FK bilan bog'langan. Faol bo'lmagan organ faqat `is_active = false` qilib "yumshoq o'chiriladi"

**Boshqa jadvallar bilan bog'lanishi:** `appeals.recipient_body_id` shu jadvalga FK bilan bog'lanadi (1:N).

---

## 5. `appeals`

**Maqsadi:** Fuqaro yoki tashkilot tomonidan davlat organiga yuboriladigan yuridik murojaat/shikoyat. AI matn tayyorlashda yordam beradi, holati kuzatiladi.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `author_id` | uuid | Murojaat muallifi |
| `category_id` | uuid | Huquqiy yo'nalish |
| `recipient_body_id` | uuid | Qabul qiluvchi davlat organi |
| `title` | text | Murojaat sarlavhasi |
| `body_text` | text | Yakuniy (foydalanuvchi tasdiqlagan) matn |
| `ai_draft_text` | text, nullable | AI taklif qilgan dastlabki qoralama |
| `status` | enum (`draft`, `submitted`, `in_review`, `answered`, `rejected`, `closed`) | Murojaat holati |
| `official_response_text` | text, nullable | Davlat organidan kelgan javob (MVP'da qo'lda kiritiladi) |
| `submitted_at` | timestamptz, nullable | Yuborilgan vaqt |
| `closed_at` | timestamptz, nullable | Yopilgan vaqt |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `author_id` → `profiles.id`; `category_id` → `legal_categories.id`; `recipient_body_id` → `government_bodies.id`

**Indexlar:** `author_id`; `status`; composite `(author_id, status)` (foydalanuvchi dashboardida filtrlash uchun); `created_at` (saralash/pagination uchun)

**RLS talablari:**
- `SELECT`: `author_id = auth.uid()` bo'lgan foydalanuvchi o'z murojaatini ko'radi; `admin` — barchasini
- `INSERT`: faqat `author_id = auth.uid()` bilan yaratish mumkin
- `UPDATE`: `status = 'draft'` bo'lganda faqat muallif matnni tahrirlashi mumkin; yuborilgach (`submitted` va undan keyingi holatlar) faqat `admin` `status`/`official_response_text` ustunlarini yangilay oladi
- `DELETE`: faqat `draft` holatidagi o'z yozuvini muallif o'chira oladi

**Boshqa jadvallar bilan bog'lanishi:** `case_status_history`, `ai_analyses`, `attachments`, `notifications` shu yozuvga (`appeal_id` orqali, mutually exclusive naqsh bilan) bog'lanadi (1:N).

---

## 6. `disputes`

**Maqsadi:** Ikki tomon (fuqaro–fuqaro yoki fuqaro–tashkilot) o'rtasidagi nizoni AI'ga qonun va faktlar asosida, taraflardan biriga yon bosmasdan tahlil qildirish.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `initiator_id` | uuid | Nizoni boshlagan foydalanuvchi |
| `respondent_profile_id` | uuid, nullable | Qarshi tomon (agar u ham tizim foydalanuvchisi bo'lsa) |
| `respondent_display_name` | text, nullable | Qarshi tomon nomi (agar tizimda ro'yxatdan o'tmagan bo'lsa) |
| `respondent_type` | enum (`citizen`, `organization`, `unregistered`) | Qarshi tomon turi |
| `category_id` | uuid | Huquqiy yo'nalish |
| `title` | text | Nizo sarlavhasi |
| `description` | text | Nizo mazmuni, **initiator** tomonidan taqdim etilgan faktlar |
| `respondent_statement` | text, nullable | Nizo bo'yicha **respondent** tomonidan taqdim etilgan faktlar — respondent ro'yxatdan o'tgan (`respondent_profile_id` to'ldirilgan) va javob bergan bo'lsagina to'ldiriladi |
| `status` | enum (`open`, `ai_analyzing`, `ai_analyzed`, `resolved`, `closed`) | Nizo holati |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |
| `closed_at` | timestamptz, nullable | |

**Primary Key:** `id`

**Foreign Key:** `initiator_id` → `profiles.id`; `respondent_profile_id` → `profiles.id` (nullable); `category_id` → `legal_categories.id`

**Cheklov:**
- `initiator_id ≠ respondent_profile_id` — foydalanuvchi o'ziga qarshi nizo ochishi taqiqlanadi (DB darajasidagi CHECK)
- `respondent_type`/`respondent_profile_id`/`respondent_display_name` mosligi CHECK bilan ta'minlanadi: `respondent_type = 'unregistered'` bo'lsa `respondent_profile_id` bo'sh va `respondent_display_name` to'ldirilgan bo'lishi shart; `respondent_type IN ('citizen', 'organization')` bo'lsa aksincha — `respondent_profile_id` to'ldirilgan bo'lishi shart

**Indexlar:** `initiator_id`; `respondent_profile_id`; `status`; `created_at`

**RLS talablari:**
- `SELECT`: `initiator_id = auth.uid()` **YOKI** `respondent_profile_id = auth.uid()` bo'lgan foydalanuvchi ko'radi; `admin` — barchasini
- `INSERT`: faqat `initiator_id = auth.uid()` bilan yaratish mumkin
- `UPDATE`: `title`/`description` faqat `status = 'open'` holatida **initiator** tomonidan tahrirlanadi; **`respondent_statement`** faqat `respondent_profile_id = auth.uid()` bo'lgan foydalanuvchi tomonidan, `status IN ('open', 'ai_analyzing')` bo'lganda yoziladi (boshqa ustunlarni respondent o'zgartira olmaydi); `status` faqat AI jarayoni (service role) yoki `admin` tomonidan o'zgartiriladi
- `DELETE`: faqat `open` holatida initiator tomonidan

**Boshqa jadvallar bilan bog'lanishi:** `case_status_history`, `ai_analyses`, `attachments`, `notifications` shu yozuvga (`dispute_id` orqali) bog'lanadi.

> **Muhim qoida (AI xolisligi bilan bog'liq):** `DEVELOPMENT_RULES.md`ning 16-bandi ("AI hech qachon bir tomon foydasiga qaror chiqarmaydi") shu jadval darajasida shu tarzda ta'minlanadi — AI tahlili (`ai_analyses`) boshlanishidan oldin ikkala tomonning faktlari (`description` va `respondent_statement`) mavjudligi tekshirilishi shart. Agar `respondent_type = 'unregistered'` bo'lsa yoki `respondent_statement IS NULL` qolsa, AI tahlili **bir tomonlama ma'lumot asosida** ekanligini aniq belgilashi majburiy (masalan `ai_analyses.analysis_text`da ochiq ko'rsatilishi kerak) — bu tomonlardan biriga "yon bosish" emas, balki tahlil to'liqligi haqidagi shaffoflik talabi.

> **Ochiq qarordagi cheklov:** MVP faqat ikki tomonli nizolarni qo'llab-quvvatlaydi (`respondent_*` ustunlari orqali). Kelgusida ko'p tomonli nizolar kerak bo'lsa, bu alohida `dispute_parties` junction jadvaliga evolyutsiya qilinishi kerak — MVP bosqichida bu ortiqcha murakkablik bo'lgani uchun qo'shilmadi.

---

## 7. `case_status_history`

**Maqsadi:** `appeals` va `disputes` jadvallaridagi holat o'zgarishlarini vaqt bo'yicha kuzatish (audit trail) — "qachon, kim tomonidan, qaysi holatdan qaysi holatga" savoliga javob.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `case_type` | enum (`appeal`, `dispute`) | Qaysi jadvalga tegishli |
| `appeal_id` | uuid, nullable | (mutually exclusive naqsh) |
| `dispute_id` | uuid, nullable | (mutually exclusive naqsh) |
| `from_status` | text, nullable | Oldingi holat |
| `to_status` | text | Yangi holat |
| `changed_by` | uuid, nullable | O'zgartirgan foydalanuvchi (tizim/AI bo'lsa `null`) |
| `note` | text, nullable | Izoh |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `appeal_id` → `appeals.id` (nullable); `dispute_id` → `disputes.id` (nullable); `changed_by` → `profiles.id` (nullable)

**Cheklov:** `appeal_id`/`dispute_id`/`case_type` uchun yuqoridagi "Umumiy konventsiyalar" bo'limida tavsiflangan DB darajasidagi CHECK constraint majburiy qo'llaniladi.

**Indexlar:** `appeal_id`; `dispute_id`; `created_at`

**RLS talablari:**
- `SELECT`: tegishli `appeal`/`dispute` egasi (yoki dispute uchun ikkala tomon) va `admin` ko'radi — egalik mantig'i parent jadval orqali tekshiriladi
- `INSERT`: faqat service role yoki `admin` — to'g'ridan-to'g'ri client insert taqiqlanadi
- `UPDATE`/`DELETE`: taqiqlanadi (o'zgarmas audit yozuvi)

**Boshqa jadvallar bilan bog'lanishi:** `appeals` va `disputes` bilan N:1 (mutually exclusive).

---

## 8. `ai_analyses`

**Maqsadi:** AI tomonidan berilgan huquqiy tahlil natijasini saqlaydi — murojaat uchun (matnni yaxshilash/qonuniy asos taklifi) yoki nizo uchun (ikki tomon tahlili, tarafsiz xulosa).

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `case_type` | enum (`appeal`, `dispute`) | |
| `appeal_id` | uuid, nullable | (mutually exclusive naqsh) |
| `dispute_id` | uuid, nullable | (mutually exclusive naqsh) |
| `analysis_text` | text | AI xulosasi/tavsiyasi |
| `legal_basis_summary` | text, nullable | Qaysi qonun asosida xulosa chiqarilgani haqida qisqacha |
| `confidence_score` | numeric, nullable | AI ishonch darajasi (0–1) |
| `model_version` | text | Ishlatilgan AI model/versiyasi (audit uchun muhim) |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `appeal_id` → `appeals.id` (nullable); `dispute_id` → `disputes.id` (nullable)

**Cheklov:** `appeal_id`/`dispute_id`/`case_type` uchun yuqoridagi "Umumiy konventsiyalar" bo'limida tavsiflangan DB darajasidagi CHECK constraint majburiy qo'llaniladi.

**Indexlar:** `appeal_id`; `dispute_id`; `created_at`

**RLS talablari:**
- `SELECT`: tegishli `appeal`/`dispute` egasi (dispute uchun ikkala tomon) va `admin`
- `INSERT`: **faqat service role** (AI backend jarayoni) — client to'g'ridan-to'g'ri yoza olmaydi, bu AI xulosasini soxtalashtirish xavfini oldini oladi
- `UPDATE`/`DELETE`: taqiqlanadi (o'zgarmas audit yozuvi)

**Boshqa jadvallar bilan bog'lanishi:** `appeals`/`disputes` bilan N:1 (mutually exclusive); `ai_analysis_law_references` orqali `laws` bilan N:N.

---

## 9. `laws`

**Maqsadi:** AI tahlilida iqtibos keltiriladigan O'zbekiston qonunchiligi moddalari/kodekslarining boshqariladigan ma'lumotlar bazasi — "AI faqat qonun va faktlarga asoslanadi" qoidasini (`DEVELOPMENT_RULES.md`, 15-band) amalda ta'minlash uchun izlanadigan manba.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `code_name` | text | Masalan "Mehnat kodeksi", "Fuqarolik kodeksi" |
| `article_number` | text | Masalan "88-modda" |
| `title` | text, nullable | Modda nomi |
| `summary_text` | text | Moddaning qisqacha mazmuni |
| `source_url` | text, nullable | Rasmiy manbaga (masalan lex.uz) havola |
| `is_active` | boolean (default `true`) | Qonun bekor qilingan/o'zgargan bo'lsa `false` |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** yo'q

**Indexlar:** `(code_name, article_number)` composite unique index; `summary_text` ustida full-text qidiruv indeksi (AI'ning tegishli moddani tez topishi uchun tavsiya etiladi)

**RLS talablari:**
- `SELECT`: public read (barcha autentifikatsiyalangan foydalanuvchi)
- `INSERT`/`UPDATE`/`DELETE`: faqat `admin` (qonunchilik yangilanishi qo'lda/admin panel orqali boshqariladi)

**Boshqa jadvallar bilan bog'lanishi:** `ai_analysis_law_references` orqali `ai_analyses` bilan N:N.

---

## 10. `ai_analysis_law_references`

**Maqsadi:** Bitta AI tahlili bir nechta qonun moddasiga asoslanishi, va bitta modda bir nechta tahlilda iqtibos keltirilishi mumkin — shuning uchun N:N bog'lovchi jadval.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `ai_analysis_id` | uuid | |
| `law_id` | uuid | |
| `created_at` | timestamptz | |

**Primary Key:** composite (`ai_analysis_id`, `law_id`)

**Foreign Key:** `ai_analysis_id` → `ai_analyses.id` (`ON DELETE CASCADE`); `law_id` → `laws.id` (`ON DELETE RESTRICT` — modda tahlilga bog'langan bo'lsa o'chirilmasligi kerak)

**Indexlar:** `law_id` bo'yicha alohida index (teskari yo'nalishda — "bu modda qaysi tahlillarda ishlatilgan" — qidiruv uchun)

**RLS talablari:**
- `SELECT`: `ai_analyses` uchun RLS bilan bir xil egalik mantig'i orqali (parent jadval orqali) meros qilib olinadi
- `INSERT`/`UPDATE`/`DELETE`: faqat service role

**Boshqa jadvallar bilan bog'lanishi:** `ai_analyses` va `laws` orasidagi N:N bog'lovchisi.

---

## 11. `attachments`

**Maqsadi:** Murojaat yoki nizoga biriktirilgan dalil/hujjat fayllarining metadatasi (haqiqiy fayl Supabase Storage'da saqlanadi, bu jadval faqat unga ishora qiladi).

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `case_type` | enum (`appeal`, `dispute`) | |
| `appeal_id` | uuid, nullable | (mutually exclusive naqsh) |
| `dispute_id` | uuid, nullable | (mutually exclusive naqsh) |
| `uploaded_by` | uuid | Faylni yuklagan foydalanuvchi |
| `storage_path` | text | Supabase Storage'dagi fayl yo'li |
| `file_name` | text | Asl fayl nomi |
| `mime_type` | text | Fayl turi |
| `size_bytes` | bigint | Fayl hajmi |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `appeal_id` → `appeals.id` (nullable); `dispute_id` → `disputes.id` (nullable); `uploaded_by` → `profiles.id`

**Cheklov:** `appeal_id`/`dispute_id`/`case_type` uchun yuqoridagi "Umumiy konventsiyalar" bo'limida tavsiflangan DB darajasidagi CHECK constraint majburiy qo'llaniladi.

**Indexlar:** `appeal_id`; `dispute_id`; `uploaded_by`

**RLS talablari:**
- `SELECT`/`INSERT`: tegishli `appeal`/`dispute` egasi (dispute uchun ikkala tomon) va `admin`
- `DELETE`: faqat yuklagan foydalanuvchi (agar tegishli case hali yopilmagan bo'lsa) yoki `admin`
- Supabase **Storage bucket policy** ham shu RLS mantig'iga mos ravishda alohida sozlanishi kerak (`storage.objects` jadvalida)

**Boshqa jadvallar bilan bog'lanishi:** `appeals`/`disputes` bilan N:1 (mutually exclusive); `profiles` bilan N:1 (`uploaded_by`).

---

## 12. `notifications`

**Maqsadi:** Foydalanuvchiga muhim voqealar (murojaat holati o'zgardi, AI tahlili tayyor, rasmiy javob keldi) haqida xabar berish — `DEVELOPMENT_RULES.md`dagi "No Dead End Rule" (17–19-band) UX qoidasini ma'lumotlar bazasi darajasida ta'minlash.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `recipient_id` | uuid | Xabar qabul qiluvchi |
| `case_type` | enum (`appeal`, `dispute`), nullable | Umumiy tizim xabarlari uchun `null` bo'lishi mumkin |
| `appeal_id` | uuid, nullable | (mutually exclusive naqsh) |
| `dispute_id` | uuid, nullable | (mutually exclusive naqsh) |
| `title` | text | Xabar sarlavhasi |
| `body_text` | text | Xabar matni |
| `is_read` | boolean (default `false`) | O'qilgan/o'qilmagan holati |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `recipient_id` → `profiles.id`; `appeal_id` → `appeals.id` (nullable); `dispute_id` → `disputes.id` (nullable)

**Cheklov:** `appeal_id`/`dispute_id`/`case_type` uchun yuqoridagi "Umumiy konventsiyalar" bo'limida tavsiflangan DB darajasidagi CHECK constraint majburiy qo'llaniladi — bu yerda farq shuki, `case_type` **umuman bo'sh** (`null`) bo'lishi ham mumkin (umumiy tizim xabarlari uchun), bu holda `appeal_id` va `dispute_id` ikkalasi ham `null` bo'lishi shart.

**Indexlar:** composite `(recipient_id, is_read)` (o'qilmagan xabarlarni tez olish uchun); `created_at`

**RLS talablari:**
- `SELECT`/`UPDATE` (`is_read` belgilash): faqat `recipient_id = auth.uid()`
- `INSERT`: faqat service role (tizim tomonidan avtomatik generatsiya qilinadi)
- `DELETE`: foydalanuvchi o'z xabarini o'chirishi mumkin (ixtiyoriy)

**Boshqa jadvallar bilan bog'lanishi:** `profiles` bilan N:1; `appeals`/`disputes` bilan N:1 (ixtiyoriy, mutually exclusive).

---

## 13. `audit_log`

**Maqsadi:** Enterprise/muvofiqlik (compliance) talabi sifatida tizimdagi nozik amallarni (profil o'zgarishi, murojaat/nizo holati o'zgarishi, admin amallari) kuzatish — `DEVELOPMENT_RULES.md` 9-band talabini va xavfsizlik auditi (`PROJECT_AUDIT.md`) talablarini qondirish uchun.

**Ustunlari:**

| Ustun | Tur | Tavsif |
|---|---|---|
| `id` | uuid | |
| `actor_id` | uuid, nullable | Amalni bajargan foydalanuvchi (tizim/AI bo'lsa `null`) |
| `action` | text | Masalan `appeal.status_changed`, `profile.updated` |
| `entity_type` | text | Masalan `appeal`, `dispute`, `profile` |
| `entity_id` | uuid | Tegishli yozuv identifikatori |
| `metadata` | jsonb, nullable | O'zgarish tafsilotlari (eski/yangi qiymat va h.k.) |
| `created_at` | timestamptz | |

**Primary Key:** `id`

**Foreign Key:** `actor_id` → `profiles.id` (nullable). **Eslatma:** `entity_id` haqiqiy FK emas — u bir nechta turli jadvalga (`entity_type` orqali) ishora qilishi mumkin, shuning uchun bog'lanish faqat ilova darajasida tekshiriladi (soft reference).

**Indexlar:** composite `(entity_type, entity_id)`; `actor_id`; `created_at`

**RLS talablari:**
- `SELECT`: faqat `admin`
- `INSERT`: faqat service role — client hech qachon to'g'ridan-to'g'ri yozmaydi
- `UPDATE`/`DELETE`: taqiqlanadi (o'zgarmas audit trail)

**Boshqa jadvallar bilan bog'lanishi:** `profiles` bilan N:1 (ixtiyoriy); boshqa jadvallarga `entity_type`/`entity_id` orqali yumshoq (soft) bog'lanish.

---

## Umumiy bog'lanish xulosasi

```
auth.users (Supabase)
  └── profiles (1:1)
        └── organization_profiles (1:1, role=organization bo'lsa)

profiles → appeals (author_id, 1:N)
profiles → disputes (initiator_id / respondent_profile_id, 1:N)

legal_categories → appeals, disputes (1:N)
government_bodies → appeals (1:N)

appeals ⟍
          ├── case_status_history (mutually exclusive)
disputes ⟋
          ├── ai_analyses (mutually exclusive) → ai_analysis_law_references → laws (N:N)
          ├── attachments (mutually exclusive) → profiles (uploaded_by)
          └── notifications (mutually exclusive, ixtiyoriy) → profiles (recipient_id)

profiles → audit_log (actor_id, ixtiyoriy, soft reference boshqa jadvallarga)
```

## Kelgusi bosqichlar uchun ataylab qoldirilgan (MVP'dan tashqarida)

Quyidagilar `docs/IDEA_PARKING.md`ga yozilishi tavsiya etiladi (`DEVELOPMENT_RULES.md`, 8-band):

- Yurist/operator roli va murojaat/nizoni tayinlash (assignment) jadvali
- Ko'p tomonli nizolar uchun `dispute_parties` junction jadvali
- Davlat organlari bilan avtomatik integratsiya (hozircha `official_response_text` qo'lda kiritiladi)
- Xabarnoma yetkazish kanallari (SMS/push/email) uchun alohida `notification_channels` jadvali
- Qonun moddalari versiyalash tarixi (`laws` jadvali hozircha faqat joriy holatni saqlaydi)
