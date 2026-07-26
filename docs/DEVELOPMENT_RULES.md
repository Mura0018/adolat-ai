# DEVELOPMENT RULES v1.0

Bu hujjat **Adolat AI** loyihasi bo'yicha majburiy standart hisoblanadi.

## Asosiy tamoyil

"Sifat tezlikdan ustun."

## Kod yozish qoidalari

1. Hujjatlarsiz kod yozilmaydi.
2. Har bir modul avval hujjatlashtiriladi.
3. Claude Code hech qachon taxmin qilib kod yozmaydi.
4. Ishonch yetarli bo'lmasa, savol beradi.
5. Mavjud kod va hujjatlar o'qilmasdan yangi kod yozilmaydi.
6. Clean Architecture majburiy.
7. DRY (Don't Repeat Yourself) tamoyiliga amal qilinadi.
8. MVP chegarasidan tashqaridagi barcha g'oyalar IDEA_PARKING.md ga yoziladi.
9. Har bir API va Database o'zgarishi hujjatlashtiriladi.
10. Har bir muhim o'zgarish alohida Git commit bilan saqlanadi.

## Xavfsizlik

11. Release build'da debug loglar ishlamasligi shart.
12. Supabase RLS siyosatlari yozilmasdan Database ishlab chiqilmaydi.
13. Maxfiy kalitlar (.env) GitHub'ga yuklanmaydi.
14. Foydalanuvchi ma'lumotlari minimal ruxsat tamoyili bilan himoyalanadi.
15. AI faqat qonun va faktlarga asoslanadi.
16. AI hech qachon bir tomon foydasiga qaror chiqarmaydi.

## UX

17. Har bir xato foydalanuvchiga yechim bilan ko'rsatiladi (No Dead End Rule).
18. Foydalanuvchi hech qachon boshi berk holatda qolmaydi.
19. Har bir muhim amal uchun keyingi qadam aniq ko'rsatiladi.

## Audit

20. Har bir Sprint oxirida PROJECT_AUDIT.md yangilanadi.
21. Har bir commitdan oldin kod tekshiriladi.
22. Har bir Release oldidan:
    - Security Audit
    - Performance Audit
    - UX Audit

    majburiy.
23. Audit natijasi 95 balldan past bo'lsa, keyingi Sprint boshlanmaydi.
24. Critical xavfsizlik kamchiligi mavjud bo'lsa, Release taqiqlanadi.
25. Har bir audit kamchiligi ACTION_PLAN.md ga yoziladi va yopilgandan keyingina Sprint yakunlanadi.

## Ish tartibi

26. Har bir vazifa:
    - Reja
    - Kod
    - Test
    - Audit
    - Commit
    - Push

    ketma-ketligida bajariladi.
