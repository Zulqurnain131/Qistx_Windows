import 'package:flutter/material.dart';
import 'package:qistx_app/Controllers/ProductStock.dart';
import 'package:qistx_app/Models/ProductStockModel.dart';

class Productstockprovider extends ChangeNotifier {
  final Productstock _controller = Productstock();
  // Product List
  List<Productstockmodel> products = [];
  // Loading
  bool isLoading = false;
  // Error
  String? errorMessage;

  // ================= Fetch Products =================
  Future<void> fetchProducts() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      products = await _controller.fetchProducts();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= Delete Product =================
  Future<void> deleteProduct(String productId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _controller.deleteProduct(productId);

      // Local list se bhi remove kar dein
      products.removeWhere((product) => product.id == productId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= Clear Error =================
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
