class OrderSummary {
  final int id;
  final String status;
  final double totalAmount;
  final String trackingCode;

  OrderSummary({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.trackingCode,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int,
      status: json['status'] as String? ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      trackingCode: json['tracking_code'] as String? ?? '',
    );
  }
}
