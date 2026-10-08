import 'package:supabase_flutter/supabase_flutter.dart';

class Statisticscontroller {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get Advanced Statistics cards metrices
  Future<Map<String, dynamic>> getStatsMetrics(String shopId) async {
    try {
      final response = await _supabase.rpc(
        'get_stats_metrics',
        params: {'p_shop_id': shopId},
      );
      print("STATISTICS METRICES CARD :$response");

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch statistics metrics: $e');
    }
  }

  /// Statistice Screen Pie Chart Function
  Future<List<dynamic>> getPaymentMethodStatistics(
    String shopId,
    String duration,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_payment_method_stats',
        params: {'p_shop_id': shopId, 'p_duration': duration},
      );
      print("Payment Method Statistics Screen Response :$response");

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payment method statistics: $e');
    }
  }

  /// Statistics Screen - Top 5 Debtors
  Future<List<dynamic>> getTopDebtors(String shopId) async {
    try {
      final response = await _supabase.rpc(
        'get_top_debtors',
        params: {'p_shop_id': shopId},
      );

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch top debtors: $e');
    }
  }
}
