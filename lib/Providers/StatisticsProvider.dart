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

  /// All Overdue Accounts
  List<dynamic> overdueAccounts = [];
  bool isOverdueAccountsLoading = false;
  String? overdueAccountsError;

  Future<void> loadOverdueAccounts(String shopId) async {
    isOverdueAccountsLoading = true;
    overdueAccountsError = null;
    notifyListeners();

    try {
      overdueAccounts = await _controller.getOverdueAccounts(shopId);
    } catch (e) {
      overdueAccountsError = e.toString();
    } finally {
      isOverdueAccountsLoading = false;
      notifyListeners();
    }
  }

  /// Dead Stock
  List<dynamic> deadStock = [];
  bool isDeadStockLoading = false;
  String? deadStockError;

  Future<void> loadDeadStock(String shopId) async {
    isDeadStockLoading = true;
    deadStockError = null;
    notifyListeners();

    try {
      deadStock = await _controller.getDeadStock(shopId);
    } catch (e) {
      deadStockError = e.toString();
    } finally {
      isDeadStockLoading = false;
      notifyListeners();
    }
  }

  /// Top 5 Selling Products
  List<dynamic> topSellingProducts = [];
  bool isTopSellingProductsLoading = false;
  String? topSellingProductsError;
  String selectedTopProductsDuration = 'yearly';

  Future<void> loadTopSellingProducts(String shopId, String duration) async {
    selectedTopProductsDuration = duration;
    isTopSellingProductsLoading = true;
    topSellingProductsError = null;
    notifyListeners();

    try {
      topSellingProducts = await _controller.getTopSellingProducts(
        shopId,
        duration,
      );
    } catch (e) {
      topSellingProductsError = e.toString();
    } finally {
      isTopSellingProductsLoading = false;
      notifyListeners();
    }
  }

  /// Product Profit Margin Analysis
  List<dynamic> productProfitMargins = [];
  bool isProductProfitMarginsLoading = false;
  String? productProfitMarginsError;
  String selectedProfitMarginDuration = 'yearly';

  Future<void> loadProductProfitMargins(String shopId, String duration) async {
    selectedProfitMarginDuration = duration;
    isProductProfitMarginsLoading = true;
    productProfitMarginsError = null;
    notifyListeners();

    try {
      productProfitMargins = await _controller.getProductProfitMargins(
        shopId,
        duration,
      );
    } catch (e) {
      productProfitMarginsError = e.toString();
    } finally {
      isProductProfitMarginsLoading = false;
      notifyListeners();
    }
  }
}
