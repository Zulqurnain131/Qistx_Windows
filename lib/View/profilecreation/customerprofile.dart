import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Models/view_customer_model.dart';
import 'package:qistx_app/Providers/CustomerProvider%20.dart';
import 'package:qistx_app/View/products/add_Ledger.dart';
import 'package:qistx_app/View/products/customer_khata.dart';

enum _Breakpoint { mobile, tablet, desktop }

class Customerprofile extends StatefulWidget {
  final ViewCustomerModel customer;
  const Customerprofile({super.key, required this.customer});

  @override
  State<Customerprofile> createState() => _CustomerprofileState();
}

class _CustomerprofileState extends State<Customerprofile> {
  static const kOrange = Color(0xFFFF5500);
  static final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const List<String> _guarantorLabels = [
    "First Guarantor Details",
    "Second Guarantor Details",
    "Third Guarantor Details",
    "Fourth Guarantor Details",
  ];

  // Breakpoints: <600 = mobile, 600-900 = tablet, >=900 = desktop.
  static _Breakpoint _breakpointFor(double width) {
    if (width >= 900) return _Breakpoint.desktop;
    if (width >= 600) return _Breakpoint.tablet;
    return _Breakpoint.mobile;
  }

  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountId = widget.customer.customerAccountId;

      if (accountId != null && accountId.isNotEmpty) {
        context.read<CustomerProvider>().fetchRecentLedgerEntries(accountId);
      }
    });
  }

  String _formatActivityDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ---------------- CNIC full-screen zoom viewer ----------------
  void _openCnicViewer(
    BuildContext context, {
    required String title,
    required String imageUrl,
  }) {
    final transformationController = TransformationController();
    double scale = 1.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void setScale(double newScale) {
            newScale = newScale.clamp(1.0, 5.0);
            setDialogState(() => scale = newScale);
            transformationController.value = Matrix4.identity()
              ..scale(newScale);
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: isMobile
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 16)
                : const EdgeInsets.all(20),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 1200,
                maxHeight: isMobile ? double.infinity : 850,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, color: kOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Close",
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: InteractiveViewer(
                        transformationController: transformationController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(100),
                        onInteractionUpdate: (_) => setDialogState(
                          () => scale = transformationController.value
                              .getMaxScaleOnAxis()
                              .clamp(1.0, 5.0),
                        ),
                        child: Center(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: kOrange,
                                    ),
                                  ),
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Unable to load CNIC",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: isMobile
                        // Mobile: compact single row — icon-only zoom controls
                        // and icon-only reset/close so it never overflows.
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Zoom Out",
                                    onPressed: scale <= 1.0
                                        ? null
                                        : () => setScale(scale - 0.5),
                                    icon: const Icon(Icons.remove, size: 20),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${(scale * 100).round()}%",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Zoom In",
                                    onPressed: scale >= 5.0
                                        ? null
                                        : () => setScale(scale + 0.5),
                                    icon: const Icon(Icons.add, size: 20),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Reset",
                                    onPressed: () => setScale(1.0),
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 20,
                                      color: kOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 34,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kOrange,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "Close",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        // Desktop/Tablet: original full row, unchanged
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: "Zoom Out",
                                onPressed: scale <= 1.0
                                    ? null
                                    : () => setScale(scale - 0.5),
                                icon: const Icon(Icons.remove),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${(scale * 100).round()}%",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: "Zoom In",
                                onPressed: scale >= 5.0
                                    ? null
                                    : () => setScale(scale + 0.5),
                                icon: const Icon(Icons.add),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => setScale(1.0),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text("Reset"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kOrange,
                                  side: const BorderSide(color: kOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Close"),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivities({
    required List<Map<String, dynamic>> activities,
    required bool isLoading,
    bool scrollable = false,
  }) {
    if (isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "No recent activity",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    Widget buildItem(Map<String, dynamic> entry) {
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
      final entryType = entry['entry_type']?.toString() ?? '';
      final description = entry['remarks']?.toString() ?? '';

      final createdAt = entry['created_at'] != null
          ? DateTime.tryParse(entry['created_at'].toString())
          : null;

      final isCredit = entryType.toLowerCase() == 'credit';

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18,
                color: kOrange,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description.isNotEmpty ? description : entryType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (createdAt != null)
                    Text(
                      _formatActivityDate(createdAt),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),

            Text(
              '${isCredit ? '+' : '-'} PKR ${amount.abs().toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (scrollable) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return buildItem(activities[index]);
        },
      );
    }

    return Column(children: activities.map(buildItem).toList());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final breakpoint = _breakpointFor(screenWidth);
    final isDesktop = breakpoint == _Breakpoint.desktop;
    final isTablet = breakpoint == _Breakpoint.tablet;
    final horizontalPadding = isDesktop ? 48.0 : (isTablet ? 32.0 : 20.0);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo — desktop only, matches the customer list screen.
                    if (isDesktop) ...[
                      RepaintBoundary(
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Image.asset(
                            "assets/Icons/Qist_Logo_trans.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Text(
                      "Customer Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isDesktop) ...[
                      // ---- Desktop: header + map side by side, zama card beside guarantors column ----
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildProfileDetails()),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildMapWidget()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildOrangeZamaCard()),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: widget.customer.guarantors
                                  .map((g) => _buildGuarantorCard(g))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isTablet) ...[
                      // ---- Tablet: header + map stacked (full width, more room per row),
                      // guarantors laid out 2-per-row since there's space for it ----
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration,
                        child: Column(
                          children: [
                            _buildProfileDetails(),
                            const SizedBox(height: 20),
                            _buildMapWidget(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildOrangeZamaCard(),
                      const SizedBox(height: 24),
                      Builder(
                        builder: (context) {
                          final cardWidth =
                              (constraints.maxWidth -
                                  horizontalPadding * 2 -
                                  20) /
                              2;
                          return Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: List.generate(
                              widget.customer.guarantors.length,
                              (i) {
                                final label = i < _guarantorLabels.length
                                    ? _guarantorLabels[i]
                                    : "Guarantor ${i + 1} Details";
                                return _buildGuarantorCard(
                                  widget.customer.guarantors[i],
                                  sectionLabel: label,
                                  width: cardWidth,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // ---- Mobile: avatar + name + quick actions, then balance card,
                      // then a dedicated details card, then one card per guarantor ----
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration,
                        child: _buildMobileProfileHeader(),
                      ),
                      const SizedBox(height: 20),
                      _buildOrangeZamaCard(),
                      const SizedBox(height: 20),
                      _buildMobileDetailsCard(),
                      const SizedBox(height: 20),
                      ...List.generate(widget.customer.guarantors.length, (i) {
                        final label = i < _guarantorLabels.length
                            ? _guarantorLabels[i]
                            : "Guarantor ${i + 1} Details";
                        return _buildGuarantorCard(
                          widget.customer.guarantors[i],
                          sectionLabel: label,
                          width: double.infinity,
                        );
                      }),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Mobile-only widgets ----------------

  Widget _buildMobileProfileHeader() {
    final customer = widget.customer;
    final hasImage =
        customer.profileImageUrl != null &&
        customer.profileImageUrl!.isNotEmpty;

    return Column(
      children: [
        ClipOval(
          child: hasImage
              ? Image.network(
                  customer.profileImageUrl!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _profilePlaceholder(),
                )
              : _profilePlaceholder(),
        ),
        const SizedBox(height: 10),
        Text(
          customer.fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _mobileActionButton(Icons.call_outlined, "Call"),
            const SizedBox(width: 10),
            _mobileActionButton(Icons.sms_outlined, "SMS"),
            const SizedBox(width: 10),
            _mobileActionButton(Icons.edit_outlined, "Edit"),
          ],
        ),
      ],
    );
  }

  Widget _mobileActionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: kOrange),
      label: Text(
        label,
        style: const TextStyle(
          color: kOrange,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kOrange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }

  Widget _buildMobileDetailsCard() {
    final customer = widget.customer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profile Details",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow("CNIC Number:", customer.cnicNo),
          const SizedBox(height: 8),
          _buildInfoRow("Phone Number:", customer.whatsappNo),
          const SizedBox(height: 8),
          _buildInfoRow("Address:", customer.address ?? "N/A"),
          const SizedBox(height: 8),
          _buildInfoRow("Email:", customer.email ?? "N/A"),
          const SizedBox(height: 16),
          _buildMapWidget(),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => _showCnicDialog(
                context,
                title: '${customer.fullName} - CNIC',
                frontUrl: customer.cnicFrontUrl,
                backUrl: customer.cnicBackUrl,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                "View CNIC Photos",
                style: TextStyle(color: kOrange, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Shared / desktop+tablet widgets ----------------

  Widget _buildProfileDetails() {
    final customer = widget.customer;
    final hasImage =
        customer.profileImageUrl != null &&
        customer.profileImageUrl!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasImage
              ? Image.network(
                  customer.profileImageUrl!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _profilePlaceholder(),
                )
              : _profilePlaceholder(),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show only when Khata account does NOT exist
                      if (customer.customerAccountId == null ||
                          customer.customerAccountId!.isEmpty) ...[
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerKhata(customerId: customer.id),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kOrange),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            "Open Khata Account",
                            style: TextStyle(color: kOrange, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Always show CNIC button
                      OutlinedButton(
                        onPressed: () => _showCnicDialog(
                          context,
                          title: '${customer.fullName} - CNIC',
                          frontUrl: customer.cnicFrontUrl,
                          backUrl: customer.cnicBackUrl,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kOrange),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "View CNIC Photos",
                          style: TextStyle(color: kOrange, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("CNIC Number:", customer.cnicNo),
                        const SizedBox(height: 10),
                        _buildInfoRow("Phone Number:", customer.whatsappNo),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow("Address:", customer.address ?? "N/A"),
                        const SizedBox(height: 10),
                        _buildInfoRow("Email:", customer.email ?? "N/A"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profilePlaceholder() => Container(
    width: 90,
    height: 90,
    color: Colors.grey.shade200,
    child: const Icon(Icons.person, size: 45, color: Colors.grey),
  );

  void _showCnicDialog(
    BuildContext context, {
    required String title,
    required String? frontUrl,
    required String? backUrl,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: isMobile
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
            : const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 900,
            maxHeight: isMobile ? double.infinity : 700,
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: isMobile
                        // Mobile: stacked, front on top, back below
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCnicImage(
                                title: "Front CNIC",
                                imageUrl: frontUrl,
                                isMobile: true,
                              ),
                              const SizedBox(height: 20),
                              _buildCnicImage(
                                title: "Back CNIC",
                                imageUrl: backUrl,
                                isMobile: true,
                              ),
                            ],
                          )
                        // Desktop/Tablet: side by side (unchanged)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildCnicImage(
                                  title: "Front CNIC",
                                  imageUrl: frontUrl,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildCnicImage(
                                  title: "Back CNIC",
                                  imageUrl: backUrl,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCnicImage({
    required String title,
    required String? imageUrl,
    bool isMobile = false,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (hasImage && !isMobile)
              const Row(
                children: [
                  Icon(Icons.zoom_in, size: 16, color: Colors.black45),
                  SizedBox(width: 4),
                  Text(
                    "Click to view",
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: isMobile ? 200 : 250,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: !hasImage
              ? const Center(child: Text("CNIC image not available"))
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openCnicViewer(
                      context,
                      title: title,
                      imageUrl: imageUrl!,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Text("Unable to load CNIC"),
                                ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Mobile responsive layout
    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    // Desktop + Tablet: existing layout unchanged
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),

        const SizedBox(width: 120),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapWidget() {
    final customer = widget.customer;
    if (customer.latitude == null || customer.longitude == null) {
      return Container(
        width: double.infinity,
        height: 155,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kOrange, width: 1.2),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Text(
            "Customer location not available",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final location = LatLng(customer.latitude!, customer.longitude!);
    return Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrange, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: location, initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.qistx.app",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: location,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: kOrange,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrangeZamaCard() {
    final b = widget.customer.currentBalance ?? 0;
    final balanceText = b == 0
        ? "PKR 0"
        : b < 0
        ? "- PKR ${b.abs().toStringAsFixed(0)}"
        : "+ PKR ${b.toStringAsFixed(0)}";

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final cardHeight = isMobile ? 480.0 : 560.0;

    final headerAndBalance = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "CURRENT ZAMA ACCOUNT",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          balanceText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white30, thickness: 1),
        const SizedBox(height: 16),
      ],
    );

    final actionButtons = Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddLedger(accountid: widget.customer.customerAccountId),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Add Amount",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "View All",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );

    // Fixed height on all breakpoints — "Recent Activity" list scrolls
    // internally instead of growing the card with every ledger entry.
    return Container(
      height: cardHeight,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          headerAndBalance,
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent Activity",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                return _buildRecentActivities(
                  activities: provider.recentLedgerEntries,
                  isLoading: provider.isLedgerLoading,
                  scrollable: true,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          actionButtons,
        ],
      ),
    );
  }

  /// [sectionLabel] + [width] switch the card into its "ordinal, full/fixed
  /// width" mode used by mobile (one per row) and tablet (two per row) —
  /// desktop keeps calling this with neither and gets the original layout.
  Widget _buildGuarantorCard(
    GuarantorModel guarantor, {
    String? sectionLabel,
    double? width,
  }) {
    return Container(
      width: width ?? 600,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionLabel ?? guarantor.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (sectionLabel == null) ...[
            _buildInfoRow("Name:", guarantor.fullName),
            const SizedBox(height: 8),
          ],
          _buildInfoRow("CNIC Number:", guarantor.cnicNo),
          const SizedBox(height: 8),
          _buildInfoRow("Phone Number:", guarantor.whatsappNo),
          const SizedBox(height: 8),
          _buildInfoRow("Address:", guarantor.address ?? "N/A"),
          const SizedBox(height: 8),
          _buildInfoRow("Email:", guarantor.email ?? "N/A"),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: () => _showCnicDialog(
                context,
                title: '${guarantor.fullName} - CNIC',
                frontUrl: guarantor.cnicFrontUrl,
                backUrl: guarantor.cnicBackUrl,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View CNIC Photos",
                style: TextStyle(color: kOrange, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
