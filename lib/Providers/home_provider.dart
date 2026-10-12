import 'package:flutter/material.dart';
import '../Controllers/home_controller.dart';

class HomeProvider extends ChangeNotifier {
  final HomeController _controller = HomeController();

  // ============================================================
  // Liquidity Trend
  // ============================================================

  List<Map<String, dynamic>> liquidityTrend = [];

  bool isLiquidityLoading = false;
  String? liquidityError;

  String selectedLiquidityDuration = 'yearly';

  Future<void> getLiquidityTrend({
    required String shopId,
    required String duration,
  }) async {
    try {
      isLiquidityLoading = true;
      liquidityError = null;
      selectedLiquidityDuration = duration;

      notifyListeners();

      liquidityTrend = await _controller.getLiquidityTrend(
        shopId: shopId,
        duration: duration,
      );
    } catch (e) {
      liquidityTrend = [];
      liquidityError = e.toString();
    } finally {
      isLiquidityLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // Top Products / Bar Chart
  // ============================================================

  List<Map<String, dynamic>> topProducts = [];

  bool isTopProductsLoading = false;
  String? topProductsError;

  String selectedBarDuration = 'yearly';

  Future<void> getTopProductsBySales({
    required String shopId,
    required String duration,
  }) async {
    try {
      isTopProductsLoading = true;
      topProductsError = null;
      selectedBarDuration = duration;

      notifyListeners();

      topProducts = await _controller.getTopProductsBySales(
        shopId: shopId,
        duration: duration,
      );
    } catch (e) {
      topProducts = [];
      topProductsError = e.toString();
    } finally {
      isTopProductsLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // Dashboard Metrics
  // ============================================================

  Map<String, dynamic> dashboardMetrics = {};

  bool isDashboardLoading = false;
  String? dashboardError;

  Future<void> getDashboardMetrics({required String shopId}) async {
    try {
      isDashboardLoading = true;
      dashboardError = null;

      notifyListeners();

      dashboardMetrics = await _controller.getDashboardMetrics(shopId: shopId);
    } catch (e) {
      dashboardMetrics = {};
      dashboardError = e.toString();
    } finally {
      isDashboardLoading = false;
      notifyListeners();
    }
  }
}
