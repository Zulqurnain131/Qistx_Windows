class ViewCustomerModel {
  final String? customerAccountId;
  final String id;
  final String fullName;
  final String cnicNo;
  final String whatsappNo;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;

  final String? profileImageUrl;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;

  final double? currentBalance;
  final double? maxCreditLimit;
  final bool isBlocked;

  final List<GuarantorModel> guarantors;

  ViewCustomerModel({
    this.customerAccountId,
    required this.id,
    required this.fullName,
    required this.cnicNo,
    required this.whatsappNo,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.currentBalance,
    this.maxCreditLimit,
    required this.isBlocked,
    required this.guarantors,
  });

  factory ViewCustomerModel.fromJson(Map<String, dynamic> json) {
    final accountData = json['customer_accounts'];
    print("Customer Account Data :$accountData");

    Map<String, dynamic>? account;

    if (accountData is List && accountData.isNotEmpty) {
      account = Map<String, dynamic>.from(accountData.first);
    } else if (accountData is Map) {
      account = Map<String, dynamic>.from(accountData);
    }
    print("Customer ID: ${json['id']}");
    print("Customer Account ID: ${account?['id']}");

    final guarantorData = json['guarantors'];

    List<GuarantorModel> guarantors = [];

    if (guarantorData is List) {
      guarantors = guarantorData
          .map(
            (item) => GuarantorModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return ViewCustomerModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      cnicNo: json['cnic_no'] ?? '',
      whatsappNo: json['whatsapp_no'] ?? '',
      customerAccountId: account?['id'],
      email: json['email'],
      address: json['address'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,

      profileImageUrl: json['profile_image_url'],
      cnicFrontUrl: json['cnic_front_url'],
      cnicBackUrl: json['cnic_back_url'],

      currentBalance: account?['current_balance'] != null
          ? (account!['current_balance'] as num).toDouble()
          : null,

      maxCreditLimit: account?['max_credit_limit'] != null
          ? (account!['max_credit_limit'] as num).toDouble()
          : null,

      isBlocked: account?['is_blocked'] ?? false,

      guarantors: guarantors,
    );
  }

  String get balanceText {
    if (currentBalance == null) {
      return 'No Khata Amount';
    }

    return 'PKR ${currentBalance!.abs().toStringAsFixed(0)}';
  }

  String get balanceType {
    if (currentBalance == null) {
      return 'no_khata';
    }

    if (currentBalance == 0) {
      return 'clear';
    }

    if (currentBalance! > 0) {
      return 'extra_payment';
    }

    return 'udhaar';
  }
}

class GuarantorModel {
  final String id;
  final String customerId;

  final String fullName;
  final String cnicNo;
  final String whatsappNo;

  final String? email;
  final String? address;

  final double? latitude;
  final double? longitude;

  final String? profileImageUrl;
  final String? cnicFrontUrl;
  final String? cnicBackUrl;

  final bool isActive;

  GuarantorModel({
    required this.id,
    required this.customerId,
    required this.fullName,
    required this.cnicNo,
    required this.whatsappNo,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    required this.isActive,
  });

  factory GuarantorModel.fromJson(Map<String, dynamic> json) {
    return GuarantorModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      fullName: json['full_name'] ?? '',
      cnicNo: json['cnic_no'] ?? '',
      whatsappNo: json['whatsapp_no'] ?? '',
      email: json['email'],
      address: json['address'],

      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,

      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,

      profileImageUrl: json['profile_image_url'],
      cnicFrontUrl: json['cnic_front_url'],
      cnicBackUrl: json['cnic_back_url'],

      isActive: json['is_active'] ?? false,
    );
  }
}
