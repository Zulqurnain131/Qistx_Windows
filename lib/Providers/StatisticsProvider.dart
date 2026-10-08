import 'package:flutter/foundation.dart';
import 'package:qistx_app/Controllers/StatisticsController.dart';

class Statisticsprovider extends ChangeNotifier {
  final Statisticscontroller _controller = Statisticscontroller();

  /// Get Advanced Statistics cards metrices
  Map<String, dynamic>? statsMetrics;
  bool isStatsMetricsLoading = false;
  String? statsMetricsError;

  Future<void> loadStatsMetrics(String shopId) async {
    isStatsMetricsLoading = true;
    statsMetricsError = null;
    notifyListeners();

    try {
      statsMetrics = await _controller.getStatsMetrics(shopId);
    } catch (e) {
      statsMetricsError = e.toString();
    } finally {
      isStatsMetricsLoading = false;
      notifyListeners();
    }
  }

  /// Statistice Screen Pie Chart Function
  List<dynamic> paymentMethodStatistics = [];
  bool isPaymentMethodLoading = false;
  String? paymentMethodError;
  String selectedPaymentDuration = 'yearly';

  void setPaymentDuration(String duration) {
    selectedPaymentDuration = duration;
    notifyListeners();
  }

  Future<void> loadPaymentMethodStatistics(
    String shopId,
    String duration,
  ) async {
    selectedPaymentDuration = duration;
    isPaymentMethodLoading = true;
    paymentMethodError = null;
    notifyListeners();

    try {
      paymentMethodStatistics = await _controller.getPaymentMethodStatistics(
        shopId,
        duration,
      );
    } catch (e) {
      paymentMethodError = e.toString();
    } finally {
      isPaymentMethodLoading = false;
      notifyListeners();
    }
  }

  /// Statistics Screen - Top 5 Debtors
  List<dynamic> topDebtors = [];

  bool isTopDebtorsLoading = false;
  String? topDebtorsError;

  Future<void> loadTopDebtors(String shopId) async {
    isTopDebtorsLoading = true;
    topDebtorsError = null;
    notifyListeners();

    try {
      topDebtors = await _controller.getTopDebtors(shopId);
    } catch (e) {
      topDebtorsError = e.toString();
    } finally {
      isTopDebtorsLoading = false;
      notifyListeners();
    }
  }
}
