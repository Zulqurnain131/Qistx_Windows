import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qistx_app/Models/guarantermodel.dart';
import 'package:uuid/uuid.dart';

class CustomerModel {
  String? fullName;
  String? cnicNo;
  String? whatsappNo;
  String? email;
  String? address;

  double? latitude;
  double? longitude;

  Uint8List? profileBytes;
  Uint8List? frontCnicBytes;
  Uint8List? backCnicBytes;

  List<GuarantorModel> guarantors = [];

  final supabase = Supabase.instance.client;
  final uuid = const Uuid();

  Future<void> saveCustomer() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final shop = await supabase
        .from("shops")
        .select("id")
        .eq("user_id", user.id)
        .single();

    final shopId = shop["id"];
    final customerId = uuid.v4();

    List<String> uploadedPaths = [];
    bool customerInserted = false;

    final customerBasePath = "${user.id}/$shopId/$customerId";
    String? profileUrl;
    String? frontUrl;
    String? backUrl;
    try {
      // ---------------- Profile Image ----------------
      if (profileBytes != null) {
        final profilePath = "$customerBasePath/pic_$customerId.jpg";

        uploadedPaths.add(profilePath);

        await supabase.storage
            .from("kyc-documents")
            .uploadBinary(
              profilePath,
              profileBytes!,
              fileOptions: const FileOptions(
                contentType: "image/jpeg",
                upsert: true,
              ),
            );

        profileUrl = supabase.storage
            .from("kyc-documents")
            .getPublicUrl(profilePath);
      }

      // ---------------- Front CNIC ----------------
      if (frontCnicBytes != null) {
        final frontPath = "$customerBasePath/front_cnic_$customerId.jpg";

        uploadedPaths.add(frontPath);

        await supabase.storage
            .from("kyc-documents")
            .uploadBinary(
              frontPath,
              frontCnicBytes!,
              fileOptions: const FileOptions(
                contentType: "image/jpeg",
                upsert: true,
              ),
            );

        frontUrl = supabase.storage
            .from("kyc-documents")
            .getPublicUrl(frontPath);
      }

      // ---------------- Back CNIC ----------------
      if (backCnicBytes != null) {
        final backPath = "$customerBasePath/back_cnic_$customerId.jpg";

        uploadedPaths.add(backPath);

        await supabase.storage
            .from("kyc-documents")
            .uploadBinary(
              backPath,
              backCnicBytes!,
              fileOptions: const FileOptions(
                contentType: "image/jpeg",
                upsert: true,
              ),
            );

        backUrl = supabase.storage.from("kyc-documents").getPublicUrl(backPath);
      }

      // ---------------- Save Customer ----------------
      await supabase.from("customers").insert({
        "id": customerId,
        "shop_id": shopId,
        "full_name": fullName,
        "cnic_no": cnicNo,
        "whatsapp_no": whatsappNo,
        "email": email,
        "address": address,
        "latitude": latitude,
        "longitude": longitude,
        "profile_image_url": profileUrl,
        "cnic_front_url": frontUrl,
        "cnic_back_url": backUrl,
      });

      customerInserted = true;

      // ---------------- Save Guarantors ----------------
      for (final g in guarantors) {
        final guarantorId = uuid.v4();
        final guarantorBasePath = "$customerBasePath/$guarantorId";
        String? profileUrl;
        String? frontUrl;
        String? backUrl;

        // Profile Image
        if (g.profileBytes != null) {
          final path = "$guarantorBasePath/pic_$guarantorId.jpg";

          uploadedPaths.add(path);

          await supabase.storage
              .from("kyc-documents")
              .uploadBinary(
                path,
                g.profileBytes!,
                fileOptions: const FileOptions(
                  contentType: "image/jpeg",
                  upsert: true,
                ),
              );

          profileUrl = supabase.storage
              .from("kyc-documents")
              .getPublicUrl(path);
        }

        // Front CNIC
        if (g.frontCnicBytes != null) {
          final path = "$guarantorBasePath/front_cnic_$guarantorId.jpg";

          uploadedPaths.add(path);

          await supabase.storage
              .from("kyc-documents")
              .uploadBinary(
                path,
                g.frontCnicBytes!,
                fileOptions: const FileOptions(
                  contentType: "image/jpeg",
                  upsert: true,
                ),
              );

          frontUrl = supabase.storage.from("kyc-documents").getPublicUrl(path);
        }

        // Back CNIC
        if (g.backCnicBytes != null) {
          final path = "$guarantorBasePath/back_cnic_$guarantorId.jpg";

          uploadedPaths.add(path);

          await supabase.storage
              .from("kyc-documents")
              .uploadBinary(
                path,
                g.backCnicBytes!,
                fileOptions: const FileOptions(
                  contentType: "image/jpeg",
                  upsert: true,
                ),
              );

          backUrl = supabase.storage.from("kyc-documents").getPublicUrl(path);
        }

        await supabase.from("guarantors").insert({
          "id": guarantorId,
          "customer_id": customerId,

          "full_name": g.fullName,
          "cnic_no": g.cnicNo,
          "whatsapp_no": g.whatsappNo,
          "email": g.email,
          "address": g.address,

          "latitude": g.latitude,
          "longitude": g.longitude,

          "profile_image_url": profileUrl,
          "cnic_front_url": frontUrl,
          "cnic_back_url": backUrl,

          "is_active": true,
        });
      }
    } catch (e) {
      print("KYC Failed: ${e.toString()}");

      // Customer delete
      if (customerInserted) {
        try {
          await supabase.from("customers").delete().eq("id", customerId);
        } catch (_) {}
      }

      // Storage cleanup
      if (uploadedPaths.isNotEmpty) {
        try {
          await supabase.storage.from("kyc-documents").remove(uploadedPaths);
        } catch (_) {}
      }

      rethrow;
    }
  }
}
