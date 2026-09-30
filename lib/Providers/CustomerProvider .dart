import 'package:flutter/material.dart';
import 'package:qistx_app/Controllers/CustomerController.dart';
import 'package:qistx_app/Models/view_customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerController _controller = CustomerController();

  // ================= CUSTOMERS =================

  List<ViewCustomerModel> customers = [];

  bool isLoading = false;
  String? errorMessage;

  // ================= FETCH CUSTOMERS =================

  Future<void> fetchCustomers({String? search}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      customers = await _controller.fetchCustomers(search: search);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= FETCH KHATA CUSTOMERS =================

  Future<void> fetchKhataCustomers({required String shopId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      customers = await _controller.fetchKhataCustomers(shopId: shopId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= LEDGER ENTRIES =================

  List<Map<String, dynamic>> recentLedgerEntries = [];

  bool isLedgerLoading = false;
  String? ledgerErrorMessage;

  Future<void> fetchRecentLedgerEntries(String customerAccountId) async {
    try {
      isLedgerLoading = true;
      ledgerErrorMessage = null;
      notifyListeners();

      recentLedgerEntries = await _controller.fetchRecentLedgerEntries(
        customerAccountId,
      );
    } catch (e) {
      ledgerErrorMessage = e.toString();
    } finally {
      isLedgerLoading = false;
      notifyListeners();
    }
  }

  // ================= GET SHOP ID =================

  String? currentShopId;

  bool isShopLoading = false;

  Future<void> getCurrentShopId() async {
    try {
      isShopLoading = true;
      errorMessage = null;
      notifyListeners();

      currentShopId = await _controller.getCurrentShopId();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isShopLoading = false;
      notifyListeners();
    }
  }

  // ================= CLEAR ERROR =================

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearLedgerError() {
    ledgerErrorMessage = null;
    notifyListeners();
  }
}
