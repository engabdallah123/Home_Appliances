class LoginRequest {
  final String username;
  final String password;
  final String? shopCode;

  LoginRequest({
    required this.username,
    required this.password,
    this.shopCode,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (shopCode != null && shopCode!.isNotEmpty) 'shopCode': shopCode,
  };
}

class RegisterRequest {
  final String fullName;
  final String username;
  final String password;
  final String? phone;
  final String? shopCode;

  RegisterRequest({
    required this.fullName,
    required this.username,
    required this.password,
    this.phone,
    this.shopCode,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'username': username,
    'password': password,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (shopCode != null && shopCode!.isNotEmpty) 'shopCode': shopCode,
  };
}

class AuthResponse {
  final String token;
  final String userId;
  final String fullName;
  final String role;
  final String tenantId;
  final String tenantName;
  final String tenantCode;
  final DateTime expiresAt;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.tenantId,
    required this.tenantName,
    required this.tenantCode,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      tenantId: json['tenantId'] ?? '',
      tenantName: json['tenantName'] ?? '',
      tenantCode: json['tenantCode'] ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    );
  }
}
