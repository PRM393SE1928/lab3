import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app_lab_2/shared/services/ai_error_message.dart';

void main() {
  test('availability and quota errors have distinct actionable messages', () {
    expect(aiErrorMessage(503), contains('thử lại sau'));
    expect(aiErrorMessage(429), contains('giới hạn'));
    expect(aiErrorMessage(401), contains('đăng nhập lại'));
    expect(aiErrorMessage(502), isNot(contains('Groq')));
    expect(aiErrorMessage(503), isNot(contains('Gemini')));
  });
}
