# features/

Har bir biznes imkoniyat (feature) o'z papkasida, **Clean Architecture** ning uchta qatlamiga bo'lingan holda joylashadi.

## Mavjud feature'lar (2026-07-28 holatiga)

- **`appeals`** — Murojaat (appeal) yaratish, tahrirlash, yuborish, holatini kuzatish. To'liq uch qatlam (`data`/`domain`/`presentation`, jumladan `usecases` va `screens`) — quyidagi konventsiyaning to'liq namunasi.
- **`disputes`** — Nizo (dispute) yaratish, tomonlar faktlarini kiritish, AI tahlilini kutish/ko'rish. `appeals` bilan bir xil to'liq tuzilma.
- **`attachments`** — Murojaat/nizoga fayl biriktirish (Storage integratsiyasi). Soddalashtirilgan tuzilma — `presentation/screens`/`widgets` va `domain/usecases` yo'q, chunki bu feature mustaqil ekranga ega emas, `appeals`/`disputes` ekranlari ichida providerlar orqali ishlatiladi.
- **`ai_analyses`** — AI tahlil natijasini faqat o'qish (read-only). Soddalashtirilgan tuzilma — sabab `attachments`dagi bilan bir xil: mustaqil ekran/usecase yo'q, yozuv huquqi umuman client'ga berilmaydi (faqat service role, `docs/DATABASE.md`, 8-jadval).
- **`legal_reference`** — Huquqiy kategoriyalar va davlat organlari lug'ati (dropdown ma'lumotlari). Soddalashtirilgan tuzilma — faqat o'qish uchun ma'lumotnoma, mustaqil ekran/usecase yo'q.

**Muhim:** yuqoridagi soddalashtirish (usecases/screens/widgets qatlamlarini tashlab ketish) qasddan qilingan — bu feature'lar mustaqil foydalanuvchi oqimiga ega emas, faqat boshqa feature'lar tomonidan providerlar orqali iste'mol qilinadi. Yangi, mustaqil ekranga ega feature qo'shilganda, quyidagi to'liq konventsiyaga (`usecases`/`screens`/`widgets` bilan) amal qilinishi kerak — `appeals`/`disputes` namunasidek.

## Konventsiya

```
features/
└── <feature_nomi>/                  masalan: auth, appeals, profile
    ├── data/
    │   ├── datasources/              Supabase/API/lokal manba bilan bevosita ishlaydi
    │   ├── models/                   Freezed DTO'lar (JSON serialization bilan)
    │   └── repositories/             domain/repositories shartnomasining implementatsiyasi
    ├── domain/
    │   ├── entities/                 Sof Dart klasslari, tashqi kutubxonalarga bog'liq emas
    │   ├── repositories/             Abstrakt shartnoma (interface), data qatlami buni amalga oshiradi
    │   └── usecases/                 Bitta aniq biznes amal (Single Responsibility)
    └── presentation/
        ├── providers/                Riverpod providerlar (holat boshqaruvi)
        ├── screens/                  To'liq ekranlar (GoRouter marshrutlari shu yerga ishora qiladi)
        └── widgets/                  Shu feature'ga xos, qayta ishlatilmaydigan widgetlar
```

## Qatlamlar orasidagi bog'liqlik yo'nalishi

`presentation` → `domain` ← `data`

`domain` qatlami hech qanday tashqi paket (Dio, Supabase, Riverpod)ga bog'liq bo'lmaydi — bu Clean Architecture'ning asosiy qoidasi. Batafsil: [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md), "Ichki Kod Arxitekturasi (Clean Architecture)" bo'limi.
