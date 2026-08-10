import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddLedger extends StatefulWidget {
  const AddLedger({super.key});

  @override
  State<AddLedger> createState() => _AddLedgerState();
}

class _AddLedgerState extends State<AddLedger> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedPaymentMethod = "Payment Method";

  // Receipt file state. `_receiptFilePath` is populated on mobile/desktop
  // (real file system path); `_receiptFileBytes` is populated on Flutter
  // Web (no direct file system access there). Only one of the two will
  // be non-null depending on platform, but `_receiptFileName` is always
  // set once a file is picked.
  String? _receiptFileName;
  String? _receiptFilePath;
  Uint8List? _receiptFileBytes;

  bool _isLoading = false;
  bool _isPickingReceipt = false;

  final List<String> _paymentMethodOptions = [
    "Payment Method",
    "Cash",
    "Bank Transfer",
    "Cheque",
    "Card",
    "Mobile Wallet",
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// Opens the native file/photo picker. Works on mobile (Android/iOS),
  /// desktop (Windows/macOS/Linux), and web — `file_picker` uses the
  /// right native picker for whichever platform the app is running on.
  Future<void> _pickReceiptPhoto() async {
    if (_isPickingReceipt) return;
    setState(() => _isPickingReceipt = true);

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // ensures bytes are available on web
      );

      if (result == null || result.files.isEmpty) return; // user cancelled

      final PlatformFile file = result.files.single;

      setState(() {
        _receiptFileName = file.name;
        _receiptFilePath = file.path; // null on web
        _receiptFileBytes = file.bytes; // populated on web (and if withData)
      });
    } catch (e) {
      debugPrint("Receipt pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not select receipt photo.\n$e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingReceipt = false);
    }
  }

  Future<void> _addLedgerEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Yahan apna ledger entry insert/upload logic likh sakte hain.
      // Receipt file `_receiptFilePath` (mobile/desktop) ya
      // `_receiptFileBytes` (web) se upload kar sakte hain.
      await Future.delayed(const Duration(seconds: 1)); // Mock network call

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ledger entry added successfully.")),
      );
    } catch (e) {
      debugPrint("Add Ledger Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add entry.\n$e")));
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
                                            MainAxisAlignment.start,
                                        children: [
                                          _buildHeaderSection(isDesktop),
                                          const SizedBox(height: 28),
                                          _buildReceiptUploadBox(),
                                          const SizedBox(height: 90),
                                          _buildAddButton(),
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
                                    _buildAddButton(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Add Ledger\nEntry",
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
          "Enter the amount received and attach proof of payment.",
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Form Fields Section (Right Side on Desktop)
  ///
  /// Desktop: Payment Method -> Amount -> Remarks (Receipt Photo sits
  /// in the left column under the header instead).
  /// Mobile: Payment Method -> Amount -> Remarks -> Receipt Photo,
  /// all stacked in a single column, matching the screenshot.
  Widget _buildFormFieldsSection(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.only(top: isDesktop ? 90 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: isDesktop
            ? [
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 30),
                _buildAmountField(),
                const SizedBox(height: 30),
                _buildRemarksField(),
              ]
            : [
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 18),
                _buildAmountField(),
                const SizedBox(height: 18),
                _buildRemarksField(),
                const SizedBox(height: 18),
                _buildReceiptUploadBox(),
              ],
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return _buildDropdownField(
      value: _selectedPaymentMethod,
      items: _paymentMethodOptions,
      icon: Icons.payment_outlined,
      onChanged: (val) => setState(() => _selectedPaymentMethod = val),
    );
  }

  Widget _buildAmountField() {
    return _buildTextField(
      controller: _amountController,
      hintText: "Amount",
      icon: Icons.receipt_long_outlined,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return "Please enter an amount";
        }
        return null;
      },
    );
  }

  Widget _buildRemarksField() {
    return _buildTextField(
      controller: _remarksController,
      hintText: "Remarks",
      icon: Icons.notes_outlined,
      keyboardType: TextInputType.text,
      validator: (_) => null,
    );
  }

  /// Dashed-border "Receipt Photo" upload box.
  Widget _buildReceiptUploadBox() {
    final bool hasReceipt = _receiptFileName != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickReceiptPhoto,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: hasReceipt ? Colors.green : Colors.grey.shade400,
          radius: 10,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasReceipt && _receiptFileBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _receiptFileBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: Colors.black54,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Receipt Photo",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isPickingReceipt
                          ? "Opening picker..."
                          : (hasReceipt ? _receiptFileName! : "Tap to Upload"),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isPickingReceipt)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasReceipt ? Colors.green : Colors.white,
                    border: Border.all(
                      color: hasReceipt
                          ? Colors.green
                          : const Color(0xFFFF5500),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    hasReceipt ? Icons.check : Icons.add,
                    size: 14,
                    color: hasReceipt ? Colors.white : const Color(0xFFFF5500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add Ledger Entry Action Button
  Widget _buildAddButton() {
    return SizedBox(
      height: 50,
      width: 400,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addLedgerEntry,
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
                      "Add",
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
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                ],
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

/// Paints a dashed, rounded-rectangle border. Used for the "Receipt
/// Photo" upload box so no extra package (e.g. dotted_border) is
/// required.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    this.radius = 10,
    this.dashWidth = 5,
    this.dashGap = 4,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double next = distance + (draw ? dashWidth : dashGap);
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, next.clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance = next;
        draw = !draw;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
