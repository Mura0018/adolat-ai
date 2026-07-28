/// Qo'llab-quvvatlanadigan AI provayderlarining barqaror identifikatori.
///
/// Domain va `AIRepository` faqat shu enum bilan ishlaydi — hech qanday
/// provayderga xos SDK turi yoki sozlama domain qatlamiga sizib
/// chiqmaydi (`docs/AI_ARCHITECTURE.md`, "Provider Abstraction" bo'limi).
enum AIProviderId { openAI, gemini, claude, local }
