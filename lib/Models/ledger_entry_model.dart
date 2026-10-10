import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class LedgerEntryModel {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save Payment / Credit Ledger Entry
  ///
  /// Balance manually update nahi hota.
  /// Supabase trigger automatically customer_accounts.current_balance
  /// ko update karega jab ledger_entries mein insert hoga.
  Future<String> saveLedgerEntry({
    required String accountId,
    required String entryType,
    required String paymentMethod,
    required double amount,
    String? remarks,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    try {
      // -----------------------------------------
      // 1. Validate Account ID
      // -----------------------------------------

      if (accountId.trim().isEmpty) {
        throw Exception('Customer account ID is required.');
      }

      // -----------------------------------------
      // 2. Validate Entry Type
      // -----------------------------------------

      if (entryType != 'payment' && entryType != 'credit') {
        throw Exception(
          'Invalid ledger entry type. Use "payment" or "credit".',
        );
      }

      // -----------------------------------------
      // 3. Validate Amount
      // -----------------------------------------

      if (amount <= 0) {
        throw Exception('Amount must be greater than 0.');
      }

      // -----------------------------------------
      // 4. Check Account Exists
      // -----------------------------------------

      final accountResponse = await _supabase
          .from('customer_accounts')
          .select('id')
          .eq('id', accountId)
          .maybeSingle();

      if (accountResponse == null) {
        throw Exception('Customer account not found.');
      }

      // -----------------------------------------
      // 5. Upload Receipt Image
      // -----------------------------------------

      String? receiptPhotoUrl;

      if (receiptBytes != null && receiptBytes.isNotEmpty) {
        final String extension = _getFileExtension(receiptFileName);

        final String filePath =
            '$accountId/'
            '${DateTime.now().millisecondsSinceEpoch}.$extension';

        await _supabase.storage
            .from('customer-account')
            .uploadBinary(
              filePath,
              receiptBytes,
              fileOptions: const FileOptions(upsert: false),
            );

        receiptPhotoUrl = _supabase.storage
            .from('customer-account')
            .getPublicUrl(filePath);
      }

      // -----------------------------------------
      // 6. Insert Ledger Entry
      // -----------------------------------------
      //
      // IMPORTANT:
      // current_balance yahan update nahi karna.
      //
      // Supabase trigger automatically:
      //
      // payment -> balance decrease
      // credit  -> balance increase
      //
      // -----------------------------------------

      final response = await _supabase
          .from('ledger_entries')
          .insert({
            'account_id': accountId,
            'entry_type': entryType,
            'amount': amount,
            'remarks': remarks,
            'receipt_photo_url': receiptPhotoUrl,
            'payment_method': paymentMethod,
          })
          .select('id')
          .single();
      final String ledgerid = response['id'].toString();

      // -----------------------------------------
      // Done
      // -----------------------------------------

      return ledgerid;
    } catch (e) {
      throw Exception('Failed to save ledger entry: $e');
    }
  }

  // -----------------------------------------
  // Get File Extension
  // -----------------------------------------

  String _getFileExtension(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return 'jpg';
    }

    if (!fileName.contains('.')) {
      return 'jpg';
    }

    final String extension = fileName.split('.').last.toLowerCase();

    // Supported image extensions
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      return 'jpg';
    }

    return extension;
  }
}
