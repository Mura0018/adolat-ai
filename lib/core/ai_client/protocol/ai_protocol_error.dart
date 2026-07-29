/// Provayderdan mustaqil, simli (wire) xatolik shartnomasi.
/// `ai_service/protocol/ai_protocol_error.dart`ning klient tomonidagi
/// mustaqil ko'chirmasi -- aynan bir xil kod ro'yxati, chunki ikkalasi
/// ham bitta wire shartnomaga rioya qiladi.
///
/// **Bu klass `Failure`ning (`core/error/failure.dart`) o'rnini
/// bosmaydi:** `AiProtocolError` -- backend'dan JSON orqali kelgan
/// XOM shartnoma; `mapping/ai_response_mapper.dart` uni ilovaning
/// yagona xatolik turiga (`Failure`) tarjima qiladi, shundan keyin
/// qolgan butun ilova (`Result<T>`, `describeErrorForUser()`) buni
/// har doimgidek ishlatadi -- AI-ga xos ikkinchi xatolik ierarxiyasi
/// YO'Q.
enum AiProtocolErrorCode {
  network,
  timeout,
  rateLimited,
  providerError,
  safetyRejected,
  providerNotConfigured,
  conversationNotFound,
  conversationClosed,
  invalidRequest,
  unauthenticated,
  unauthorized,
  unknown,
}

class AiProtocolError {
  const AiProtocolError({required this.code, required this.message, required this.retryable});

  final AiProtocolErrorCode code;
  final String message;
  final bool retryable;

  Map<String, dynamic> toJson() => {'code': code.name, 'message': message, 'retryable': retryable};

  factory AiProtocolError.fromJson(Map<String, dynamic> json) {
    return AiProtocolError(
      code: AiProtocolErrorCode.values.byName(json['code'] as String),
      message: json['message'] as String,
      retryable: json['retryable'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolError &&
            other.code == code &&
            other.message == message &&
            other.retryable == retryable);
  }

  @override
  int get hashCode => Object.hash(code, message, retryable);

  @override
  String toString() => 'AiProtocolError(code: $code, retryable: $retryable)';
}
