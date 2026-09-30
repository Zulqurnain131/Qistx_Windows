import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerAccountModel {
  final String customerId;
  final double currentBalance;
  final double maxCreditLimit;
  final String billingCycle;
  final bool autoBlockUdhaar;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerAccountModel({
    required this.customerId,
    this.currentBalance = 0,
    required this.maxCreditLimit,
    required this.billingCycle,
    required this.autoBlockUdhaar,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Customer Account / Khata
  static Future<String> createKhata({
    required String customerId,
    required double maxCreditLimit,
    required String billingCycle,
    required bool autoBlockUdhaar,
  }) async {
    final supabase = Supabase.instance.client;

    final now = DateTime.now();

    final response = await supabase
        .from('customer_accounts')
        .insert({
          'customer_id': customerId,
          'current_balance': 0,
          'max_credit_limit': maxCreditLimit,
          'billing_cycle': billingCycle,
          'auto_block_udhaar': autoBlockUdhaar,
          'is_blocked': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select('id')
        .single();
    print("Khata created for customer ID: $customerId");
    final String accountId = response['id'].toString();
    return accountId;
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'current_balance': currentBalance,
      'max_credit_limit': maxCreditLimit,
      'billing_cycle': billingCycle,
      'auto_block_udhaar': autoBlockUdhaar,
      'is_blocked': isBlocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
