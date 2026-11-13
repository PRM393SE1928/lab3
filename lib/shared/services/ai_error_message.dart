/// Keep provider diagnostics on the server; show actionable messages in the UI.
String aiErrorMessage(int statusCode) => switch (statusCode) {
  401 => 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại để sử dụng AI.',
  403 => 'Tài khoản chưa có quyền sử dụng dịch vụ AI.',
  429 => 'AI đang giới hạn số yêu cầu. Hãy chờ một lúc rồi thử lại.',
  503 => 'Dịch vụ AI đang bận hoặc tạm thời không khả dụng. Hãy thử lại sau ít phút.',
  502 || 504 => 'Chưa nhận được kết quả từ dịch vụ AI. Hãy thử lại sau.',
  _ => 'Không thể hoàn tất phân tích AI. Hãy thử lại.',
};
