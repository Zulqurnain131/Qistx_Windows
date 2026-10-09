import 'package:qistx_app/Models/ProductStockModel.dart';

class Cartitem {
  final Productstockmodel product;
  double quantity;

  Cartitem({required this.product, this.quantity = 1});

  double get subtotal => product.salePrice * quantity;
}
