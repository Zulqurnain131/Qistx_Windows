import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerKhata extends StatefulWidget {
  const CustomerKhata({super.key});

  @override
  State<CustomerKhata> createState() => _CreateCustomerProfileState();
}

class _CreateCustomerProfileState extends State<CustomerKhata> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _maxCreditLimitController =
      TextEditingController();

  String? _selectedBillingCycle = "Billing Cycle";
  bool _autoBlockUdhaar = true;
  bool _isLoading = false;

  final List<String> _billingCycleOptions = [
    "Billing Cycle",
    "Weekly",
    "Bi-Weekly",
    "Monthly",
    "Custom",
  ];

  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
  }

  Future<void> _saveCurrentScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("last_screen", "create_customer_profile");
    } catch (e) {
      debugPrint("SharedPreferences Error: $e");
    }
  }

  @override
  void dispose() {
    _maxCreditLimitController.dispose();
    super.dispose();
  }

  Future<void> _openKhata() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Yahan aap apna customer/khata database insert logic likh sakte hain
      await Future.delayed(const Duration(seconds: 1)); // Mock network call

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer Khata opened successfully.")),
      );

      // Agli screen ka navigation yahan lagayein
    } catch (e) {
      debugPrint("Open Khata Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to open khata.\n$e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Bottom Right Wave Decorative Graphic (Desktop Only)
                if (isDesktop && constraints.maxWidth > 320)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.85,
                          child: Image.asset(
                            "assets/images/auth_confirmation_pin.png",
                            width: screenWidth * 0.32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Top Left Brand Logo (Desktop Only)
                if (isDesktop && constraints.maxWidth > 350)
                  Positioned(
                    top: 20,
                    left: 40,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          "assets/Icons/Qist_Logo_trans.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Main Content Body Layout
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48.0 : 20.0,
                        vertical: 40.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 950 : 400,
                        ),
                        child: Form(
                          key: _formKey,
                          child: isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildHeaderSection(isDesktop),
                                          const SizedBox(height: 50),
                                          _buildOpenKhataButton(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 60),
                                    Expanded(
                                      flex: 5,
                                      child: _buildFormFieldsSection(isDesktop),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeaderSection(isDesktop),
                                    const SizedBox(height: 24),
                                    _buildFormFieldsSection(isDesktop),
                                    const SizedBox(height: 28),
                                    _buildOpenKhataButton(),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Header Text Block
  Widget _buildHeaderSection(bool isDesktop) {
    return Padding(
      // The large bottom padding is only needed on desktop, where it
      // reserves vertical space so the header lines up with the
      // form fields column (which is itself pushed down). On mobile
      // the header sits directly above the form, so no extra gap.
      padding: EdgeInsets.only(bottom: isDesktop ? 140 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Open Customer\nKhata",
            style: TextStyle(
              fontSize: isDesktop ? 34 : 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Define this customer's credit limit (Udhaar limit), enter any opening balance, and select when their payments will be due.",
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Form Fields Section (Right Side on Desktop)
  ///
  /// Only Max Credit Limit, the auto-block checkbox, and the Billing
  /// Cycle dropdown are shown now (Opening Balance dropdown and
  /// Amount field were removed). Desktop keeps the checkbox above the
  /// Billing Cycle dropdown; mobile puts Billing Cycle before the
  /// checkbox, matching the two reference screenshots.
  Widget _buildFormFieldsSection(bool isDesktop) {
    return Padding(
      // Same reasoning as the header: the 90px top padding is a
      // desktop-only alignment offset. Mobile stacks naturally so it
      // needs none.
      padding: EdgeInsets.only(top: isDesktop ? 90 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: isDesktop
            ? [
                _buildMaxCreditLimitField(),
                const SizedBox(height: 30),
                _buildAutoBlockCheckboxRow(),
                const SizedBox(height: 30),
                _buildBillingCycleDropdown(),
              ]
            : [
                _buildMaxCreditLimitField(),
                const SizedBox(height: 18),
                _buildBillingCycleDropdown(),
                const SizedBox(height: 20),
                _buildAutoBlockCheckboxRow(),
              ],
      ),
    );
  }

  Widget _buildMaxCreditLimitField() {
    return _buildTextField(
      controller: _maxCreditLimitController,
      hintText: "Max Credit Limit",
      icon: Icons.balance_outlined,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return "Please enter max credit limit";
        }
        return null;
      },
    );
  }

  Widget _buildBillingCycleDropdown() {
    return _buildDropdownField(
      value: _selectedBillingCycle,
      items: _billingCycleOptions,
      icon: Icons.autorenew_rounded,
      onChanged: (val) => setState(() => _selectedBillingCycle = val),
    );
  }

  /// Checkbox row with explanatory text — uses a circular orange
  /// checkmark to match the design instead of the default square
  /// Material checkbox.
  Widget _buildAutoBlockCheckboxRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoundCheckbox(),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              "Automatically block new Udhaar if the customer misses their payment date. Cashier override will be required.",
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Custom circular checkbox: solid orange fill with a white check
  /// when selected, and a light grey outlined circle when not.
  Widget _buildRoundCheckbox() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _autoBlockUdhaar = !_autoBlockUdhaar),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 22,
        width: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _autoBlockUdhaar ? const Color(0xFFFF5500) : Colors.white,
          border: Border.all(
            color: _autoBlockUdhaar
                ? const Color(0xFFFF5500)
                : Colors.grey.shade400,
            width: 1.4,
          ),
        ),
        child: _autoBlockUdhaar
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }

  /// Open Khata Action Button
  Widget _buildOpenKhataButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: SizedBox(
        height: 50,
        width: 400,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _openKhata,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5500),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Flexible(
                      child: Text(
                        "Open Khata",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Custom Dropdown Helper
  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.black87)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// Custom TextFormField Helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
