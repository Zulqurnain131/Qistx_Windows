import 'package:qistx_app/Models/view_customer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ViewCustomerModel>> fetchCustomers({String? search}) async {
    try {
      var query = _supabase.from('customers').select('''
      id,
      full_name,
      cnic_no,
      whatsapp_no,
      email,
      address,
      latitude,
      longitude,
      profile_image_url,
      cnic_front_url,
      cnic_back_url,
      customer_accounts(
        id,
        current_balance,
        max_credit_limit,
        is_blocked
      )
    ''');

      if (search != null && search.trim().isNotEmpty) {
        final value = search.trim();

        query = query.or('full_name.ilike.%$value%,cnic_no.ilike.%$value%');
      }

      final response = await query.order('created_at', ascending: false);

      final data = response as List;

      final customers = await Future.wait(
        data.map((item) async {
          final json = Map<String, dynamic>.from(item);

          // Only profile image for customer list
          final urls = await Future.wait([
            _getSignedUrl(json['profile_image_url']),
            _getSignedUrl(json['cnic_front_url']),
            _getSignedUrl(json['cnic_back_url']),
          ]);

          json['profile_image_url'] = urls[0];
          json['cnic_front_url'] = urls[1];
          json['cnic_back_url'] = urls[2];

          json['guarantors'] = [];

          return ViewCustomerModel.fromJson(json);
        }),
      );

      return customers;
    } catch (e) {
      print('FETCH CUSTOMERS ERROR: $e');

      throw Exception('Failed to fetch customers: $e');
    }
  }
  // =====================================================
  // GET SIGNED URL
  // =====================================================

  Future<String?> _getSignedUrl(dynamic value) async {
    try {
      if (value == null) {
        return null;
      }

      final url = value.toString().trim();

      if (url.isEmpty) {
        return null;
      }

      final path = _extractStoragePath(url);

      if (path == null || path.isEmpty) {
        return null;
      }

      final signedUrl = await _supabase.storage
          .from('kyc-documents')
          .createSignedUrl(path, 3600);

      return signedUrl;
    } catch (e) {
      print('SIGNED URL ERROR: $e');
      return null;
    }
  }

  // =====================================================
  // EXTRACT STORAGE PATH
  // =====================================================

  String? _extractStoragePath(String value) {
    try {
      // -----------------------------------------------
      // Case 1:
      // Full Supabase public URL
      // -----------------------------------------------

      if (value.startsWith('http')) {
        const marker = '/storage/v1/object/public/kyc-documents/';

        final index = value.indexOf(marker);

        if (index == -1) {
          return null;
        }

        return value.substring(index + marker.length);
      }

      // -----------------------------------------------
      // Case 2:
      // public/kyc-documents/...
      // -----------------------------------------------

      const publicPrefix = 'public/kyc-documents/';

      if (value.startsWith(publicPrefix)) {
        return value.substring(publicPrefix.length);
      }

      // -----------------------------------------------
      // Case 3:
      // Already storage path
      // -----------------------------------------------

      return value;
    } catch (e) {
      print('FAILED TO EXTRACT STORAGE PATH: $e');

      return null;
    }
  }

  ///// ledger Entries Function
  Future<List<Map<String, dynamic>>> fetchRecentLedgerEntries(
    String customerAccountId,
  ) async {
    try {
      final response = await _supabase
          .from('ledger_entries')
          .select('''
          id,
          account_id,
          amount,
          entry_type,
          remarks,
          created_at
        ''')
          .eq('account_id', customerAccountId)
          .order('created_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('FETCH LEDGER ERROR: $e');

      throw Exception('Failed to fetch recent activity: $e');
    }
  }

  /////// Fetch Customer Khata //////////////
  Future<List<ViewCustomerModel>> fetchKhataCustomers({
    required String shopId,
  }) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('''
          id,
          shop_id,
          full_name,
          cnic_no,
          whatsapp_no,
          email,
          address,
          latitude,
          longitude,
          profile_image_url,
          cnic_front_url,
          cnic_back_url,

          customer_accounts!inner(
            id,
            current_balance,
            max_credit_limit,
            is_blocked
          ),

          guarantors(
            id,
            customer_id,
            full_name,
            cnic_no,
            whatsapp_no,
            email,
            address,
            latitude,
            longitude,
            profile_image_url,
            cnic_front_url,
            cnic_back_url,
            is_active
          )
        ''')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      final data = response as List;

      final List<ViewCustomerModel> customers = [];

      for (final item in data) {
        final json = Map<String, dynamic>.from(item);

        // Customer profile image
        final urls = await Future.wait([
          _getSignedUrl(json['profile_image_url']),
          _getSignedUrl(json['cnic_front_url']),
          _getSignedUrl(json['cnic_back_url']),
        ]);

        json['profile_image_url'] = urls[0];
        json['cnic_front_url'] = urls[1];
        json['cnic_back_url'] = urls[2];

        // Guarantors
        final guarantorData = json['guarantors'];

        if (guarantorData is List) {
          final List<Map<String, dynamic>> updatedGuarantors = [];

          for (final guarantor in guarantorData) {
            final guarantorJson = Map<String, dynamic>.from(guarantor);

            final guarantorUrls = await Future.wait([
              _getSignedUrl(guarantorJson['profile_image_url']),
              _getSignedUrl(guarantorJson['cnic_front_url']),
              _getSignedUrl(guarantorJson['cnic_back_url']),
            ]);

            guarantorJson['profile_image_url'] = guarantorUrls[0];
            guarantorJson['cnic_front_url'] = guarantorUrls[1];
            guarantorJson['cnic_back_url'] = guarantorUrls[2];

            updatedGuarantors.add(guarantorJson);
          }

          json['guarantors'] = updatedGuarantors;
        }

        customers.add(ViewCustomerModel.fromJson(json));
      }

      return customers;
    } catch (e) {
      print('FETCH KHATA CUSTOMERS ERROR: $e');

      throw Exception('Failed to fetch Khata customers: $e');
    }
  }

  //////////// Get Current Shop id
  Future<String?> getCurrentShopId() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      final response = await _supabase
          .from('shops')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['id']?.toString();
    } catch (e) {
      print('GET SHOP ID ERROR: $e');

      throw Exception('Failed to get current shop');
    }
  }
}
