import 'package:qistx_app/Models/ProductStockModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Productstock {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Productstockmodel>> fetchProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('''
            id,
            product_name,
            sku,
            category,
            product_photo_url,
            base_unit,
            warning_qty,
            allow_fractional_sales,
            product_batches (
              initial_stock,
              sale_price
            )
          ''')
          .order('created_at', ascending: false);

      final List<dynamic> data = response;

      return data
          .map(
            (item) => Productstockmodel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  //////////// Delete
  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }
}
