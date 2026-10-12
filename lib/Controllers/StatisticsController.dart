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

  /// All Overdue Accounts
  Future<List<dynamic>> getOverdueAccounts(String shopId) async {
    try {
      final response = await _supabase.rpc(
        'get_all_overdue_accounts',
        params: {'p_shop_id': shopId},
      );

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch overdue accounts: $e');
    }
  }

  /// Statistics Screen - Dead Stock
  Future<List<dynamic>> getDeadStock(String shopId) async {
    try {
      final response = await _supabase.rpc(
        'get_dead_stock',
        params: {'p_shop_id': shopId},
      );

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch dead stock: $e');
    }
  }

  /// Statistics Screen - Top 5 Selling Products
  Future<List<dynamic>> getTopSellingProducts(
    String shopId,
    String duration,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_top_products',
        params: {'p_shop_id': shopId, 'p_duration': duration},
      );

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch top selling products: $e');
    }
  }

  /// Statistics Screen - Product Profit Margin Analysis
  Future<List<dynamic>> getProductProfitMargins(
    String shopId,
    String duration,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_gross_margin_breakdown',
        params: {'p_shop_id': shopId, 'p_duration': duration},
      );

      return List<dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch product profit margins: $e');
    }
  }
}
