import 'package:supabase_flutter/supabase_flutter.dart';

class HomeController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch dashboard line chart data from Supabase
  Future<List<Map<String, dynamic>>> getLiquidityTrend({
    required String shopId,
    required String duration,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_chart_trend_data',
        params: {'p_shop_id': shopId, 'p_duration': duration},
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      throw Exception('Failed to load liquidity trend: $e');
    }
  }

  //////////////// Bar Chart Funtion Call From supabase //////
  Future<List<Map<String, dynamic>>> getTopProductsBySales({
    required String shopId,
    required String duration,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_top_products_stats',
        params: {'p_shop_id': shopId, 'p_duration': duration},
      );
      if (response == null) {
        return [];
      }
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load top products: $e');
    }
  }

  ///////////////// Dashboard Metrices Function Call //////
  Future<Map<String, dynamic>> getDashboardMetrics({
    required String shopId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_dashboard_metrics',
        params: {'p_shop_id': shopId},
      );

      if (response == null) {
        return {};
      }

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      return {};
    } catch (e) {
      throw Exception('Failed to load dashboard metrics: $e');
    }
  }
}
