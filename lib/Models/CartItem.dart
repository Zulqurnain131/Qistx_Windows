import 'package:qistx_app/Models/ProductStockModel.dart';

class CartItem {
  final ProductStockModel product;
  double quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.salePrice * quantity;
}
