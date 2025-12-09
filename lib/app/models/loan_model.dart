class LoanModel {
  final String id;
  final String loanOfficerId;
  final String borrowerName;
  final String? borrowerEmail;
  final String? borrowerPhone;
  final double loanAmount;
  final double interestRate;
  final int termInMonths;
  final String loanType; // 'conventional', 'FHA', 'VA', 'USDA', 'jumbo', etc.
  final String status; // 'draft', 'pending', 'approved', 'funded', 'closed'
  final String? propertyAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanModel({
    required this.id,
    required this.loanOfficerId,
    required this.borrowerName,
    this.borrowerEmail,
    this.borrowerPhone,
    required this.loanAmount,
    required this.interestRate,
    required this.termInMonths,
    required this.loanType,
    required this.status,
    this.propertyAddress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: (json['id'] ?? '') as String,
      loanOfficerId: (json['loanOfficerId'] ?? '') as String,
      borrowerName: (json['borrowerName'] ?? '') as String,
      borrowerEmail: json['borrowerEmail'] as String?,
      borrowerPhone: json['borrowerPhone'] as String?,
      loanAmount: (json['loanAmount'] ?? 0.0).toDouble(),
      interestRate: (json['interestRate'] ?? 0.0).toDouble(),
      termInMonths: (json['termInMonths'] ?? 0) as int,
      loanType: (json['loanType'] ?? 'conventional') as String,
      status: (json['status'] ?? 'draft') as String,
      propertyAddress: json['propertyAddress'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanOfficerId': loanOfficerId,
      'borrowerName': borrowerName,
      'borrowerEmail': borrowerEmail,
      'borrowerPhone': borrowerPhone,
      'loanAmount': loanAmount,
      'interestRate': interestRate,
      'termInMonths': termInMonths,
      'loanType': loanType,
      'status': status,
      'propertyAddress': propertyAddress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LoanModel copyWith({
    String? id,
    String? loanOfficerId,
    String? borrowerName,
    String? borrowerEmail,
    String? borrowerPhone,
    double? loanAmount,
    double? interestRate,
    int? termInMonths,
    String? loanType,
    String? status,
    String? propertyAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      loanOfficerId: loanOfficerId ?? this.loanOfficerId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerEmail: borrowerEmail ?? this.borrowerEmail,
      borrowerPhone: borrowerPhone ?? this.borrowerPhone,
      loanAmount: loanAmount ?? this.loanAmount,
      interestRate: interestRate ?? this.interestRate,
      termInMonths: termInMonths ?? this.termInMonths,
      loanType: loanType ?? this.loanType,
      status: status ?? this.status,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
