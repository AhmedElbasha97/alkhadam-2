class FinanceModel {
  final String status;
  final bool isPaid;
  final String message;

  const FinanceModel({
    required this.status,
    required this.isPaid,
    required this.message,
  });

  factory FinanceModel.fromJson(Map<String, dynamic> json) {
    return FinanceModel(
      status: json['status'] as String,
      isPaid: json['is_paid'] as bool,
      message: json['message'] as String,
    );
  }
}
