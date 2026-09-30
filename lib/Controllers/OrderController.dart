import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qistx_app/Models/CartItem.dart';

class OrderController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createOrder({
    required String shopId,
    String? customerId,
    required String orderType,
    required String paymentMethod,
    required double subtotal,
    required double discount,
    required double netTotal,
    required List<CartItem> items,
  }) async {
    try {
      // CartItem -> JSON
      final List<Map<String, dynamic>> orderItems = items.map((item) {
        return {'product_id': item.product.id, 'quantity': item.quantity};
      }).toList();

      // Supabase PostgreSQL Function
      final response = await _supabase.rpc(
        'create_order_transaction',
        params: {
          'p_shop_id': shopId,
          'p_order_type': orderType,
          'p_payment_method': paymentMethod,
          'p_subtotal': subtotal,
          'p_discount': discount,
          'p_net_total': netTotal,
          'p_items': orderItems,
          'p_customer_id': customerId,
        },
      );

      return response.toString();
    } catch (e) {
      print('CREATE ORDER RPC ERROR: $e');

      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
