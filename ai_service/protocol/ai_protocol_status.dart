/// `AIResponseEnvelope.status`ning yakuniy holati -- oqim tugagandan
/// keyingi (yoki oqimsiz, bitta martalik so'rovdagi) natija.
///
/// `AIProtocolStreamEvent`ning uchta YAKUNIY (terminal) varianti --
/// `Completed`/`Cancelled`/`Failed` -- bilan bir xil uchta holatga mos
/// keladi (`started`/`chunk` -- oraliq holatlar, yakuniy javob
/// konvertida ular uchun alohida status qiymati kerak emas).
enum AIProtocolStatus { completed, failed, cancelled }
