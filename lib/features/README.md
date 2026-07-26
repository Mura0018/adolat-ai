# features/

Har bir biznes imkoniyat (feature) o'z papkasida, **Clean Architecture** ning uchta qatlamiga bo'lingan holda joylashadi. Bu papka hozircha bo'sh — birinchi feature qo'shilganda quyidagi konventsiyaga amal qilinadi.

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

`domain` qatlami hech qanday tashqi paket (Dio, Supabase, Riverpod)ga bog'liq bo'lmaydi — bu Clean Architecture'ning asosiy qoidasi. Batafsil: [`docs/architecture.md`](../../docs/architecture.md).
