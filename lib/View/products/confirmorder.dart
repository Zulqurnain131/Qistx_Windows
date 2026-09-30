import 'package:flutter/material.dart';
import 'package:qistx_app/Controllers/CustomerController.dart';
import 'package:qistx_app/Controllers/OrderController.dart';
import 'package:qistx_app/Models/CartItem.dart';
import 'package:qistx_app/Models/view_customer_model.dart';

class Confirmorder extends StatefulWidget {
  final List<CartItem> cartItems;

  const Confirmorder({super.key, required this.cartItems});

  @override
  State<Confirmorder> createState() => _ConfirmorderState();
}

class _ConfirmorderState extends State<Confirmorder> {
  final CustomerController _customerController = CustomerController();
  List<CartItem> get cartItems => widget.cartItems;
  List<ViewCustomerModel> _customers = [];
  List<ViewCustomerModel> _filteredCustomers = [];
  ViewCustomerModel? _selectedCustomer;
  bool _isLoadingCustomers = false;
  String? _shopId;
  String _selectedOrderType = 'walk_in';
  String _selectedPaymentMethod = 'cash';
  final OrderController _orderController = OrderController();
  bool _isConfirmingOrder = false;

  final List<Map<String, String>> _orderTypes = [
    {'label': 'Walk-In Customer', 'value': 'walk_in'},
    {'label': 'Khata Account', 'value': 'khata'},
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'label': 'Cash', 'value': 'cash'},
    {'label': 'EasyPaisa', 'value': 'easypaisa'},
    {'label': 'JazzCash', 'value': 'jazzcash'},
    {'label': 'NayaPay', 'value': 'nayapay'},
    {'label': 'SadaPay', 'value': 'sadapay'},
    {'label': 'Bank Transfer', 'value': 'bank_transfer'},
    {'label': 'Card', 'value': 'card'},
  ];

  final TextEditingController _discountController = TextEditingController();
  double discount = 0.0;
  double get subtotal {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + (item.product.salePrice * item.quantity),
    );
  }

  double get netTotal {
    final total = subtotal - discount;
    return total < 0 ? 0.0 : total;
  }

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  //// Get Current Shopid
  Future<void> _loadShopId() async {
    try {
      final shopId = await _customerController.getCurrentShopId();

      if (!mounted) return;

      setState(() {
        _shopId = shopId;
      });

      print('CURRENT SHOP ID: $_shopId');
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onOrderTypeChanged(String? newValue) async {
    if (newValue == null) return;

    setState(() {
      _selectedOrderType = newValue;
    });

    if (newValue == 'khata') {
      await _fetchKhataCustomers();
    } else {
      setState(() {
        _selectedCustomer = null;
      });
    }
  }

  Future<void> _fetchKhataCustomers() async {
    if (_shopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shop not found')));

      return;
    }

    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final customers = await _customerController.fetchKhataCustomers(
        shopId: _shopId!,
      );

      if (!mounted) return;

      setState(() {
        _customers = customers;
        _filteredCustomers = List.from(customers);
        _isLoadingCustomers = false;
      });

      _showCustomerSelectionBottomSheet();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCustomers = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmOrder() async {
    if (_shopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shop not found')));

      return;
    }

    // Khata order ke liye customer required
    if (_selectedOrderType == 'khata' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Khata customer')),
      );

      return;
    }

    setState(() {
      _isConfirmingOrder = true;
    });

    try {
      final String? customerId = _selectedOrderType == 'khata'
          ? _selectedCustomer!.id
          : null;

      final String orderType = _selectedOrderType == 'khata'
          ? 'khata'
          : 'walk_in';
      final orderId = await _orderController.createOrder(
        shopId: _shopId!,
        customerId: customerId,
        orderType: orderType,
        paymentMethod: _selectedPaymentMethod,
        subtotal: subtotal,
        discount: discount,
        netTotal: netTotal,
        items: cartItems,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order created successfully: $orderId')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isConfirmingOrder = false;
        });
      }
    }
  }

  // Bottom Sheet for Customer Selection — shared by both desktop and mobile.
  void _showCustomerSelectionBottomSheet() {
    _filteredCustomers = List.from(_customers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Select Customer Account",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search using name and CNIC",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (query) {
                      final q = query.trim().toLowerCase();

                      setModalState(() {
                        _filteredCustomers = _customers.where((customer) {
                          return customer.fullName.toLowerCase().contains(q) ||
                              customer.cnicNo.toLowerCase().contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Customer List
                  Expanded(
                    child: _filteredCustomers.isEmpty
                        ? const Center(child: Text("No customer found"))
                        : ListView.builder(
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              final isSelected =
                                  _selectedCustomer?.id == customer.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCustomer = customer;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF5500)
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child:
                                              customer.profileImageUrl !=
                                                      null &&
                                                  customer
                                                      .profileImageUrl!
                                                      .isNotEmpty
                                              ? Image.network(
                                                  customer.profileImageUrl!,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Icon(
                                                          Icons.person,
                                                          color: Colors.grey,
                                                          size: 28,
                                                        );
                                                      },
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }

                                                        return const Center(
                                                          child: SizedBox(
                                                            width: 18,
                                                            height: 18,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  color: Colors.grey,
                                                  size: 28,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "CNIC: ${customer.cnicNo}",
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              customer.balanceType == 'udhaar'
                                              ? const Color(0xFFFF5500)
                                              : customer.balanceType ==
                                                    'extra_payment'
                                              ? Colors.green
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              customer.balanceText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              customer.balanceType == 'udhaar'
                                                  ? 'Udhaar Amount'
                                                  : customer.balanceType ==
                                                        'extra_payment'
                                                  ? 'Extra Payment'
                                                  : customer.balanceType ==
                                                        'clear'
                                                  ? 'Clear'
                                                  : 'No Khata',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                              ),
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.topLeft,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return isDesktop
        ? _buildDesktopView(context, screenWidth)
        : _buildMobileView(context);
  }

  // ============================================================
  // DESKTOP VIEW — unchanged from the original implementation.
  // ============================================================
  Widget _buildDesktopView(BuildContext context, double screenWidth) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Wave Image (Bottom Right)
            Positioned(
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.85,
                  child: Image.asset(
                    "assets/images/auth_confirmation_pin.png",
                    width: screenWidth * 0.3,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Main Content Layout
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Logo
                  _buildLogo(),
                  const SizedBox(height: 40),

                  // Desktop Content
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SECTION
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Confirm Order",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Review the final details of order. All amounts\nare in PKR.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),

                              const Spacer(),

                              SizedBox(
                                width: 300,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isConfirmingOrder
                                      ? null
                                      : _confirmOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5500),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Confirm",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // RIGHT SECTION
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 60, right: 40),
                            child: _buildOrderDetails(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE VIEW — separate, responsive UI matching the new design.
  // No "Amount (optional)" field. Customer selection opens the same
  // bottom sheet used on desktop/web.
  // ============================================================
  Widget _buildMobileView(BuildContext context) {
    final horizontalPad = MediaQuery.of(context).size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Confirm Order",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Review the final details of order. All amounts are in PKR.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Subtotal / Discount / Net Total
                    _buildSummaryRow(
                      "Subtotal:",
                      "PKR ${subtotal.toStringAsFixed(0)}",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Discount:",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: "0",
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFFF5500),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                discount = double.tryParse(val) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      "Net Total:",
                      "PKR ${netTotal.toStringAsFixed(0)}",
                    ),
                    const SizedBox(height: 28),

                    // Order Type
                    _buildDropdown(
                      icon: Icons.receipt_long_outlined,
                      value: _selectedOrderType,
                      items: _orderTypes,
                      onChanged: _onOrderTypeChanged,
                    ),
                    const SizedBox(height: 14),

                    // Select Customer Khata — tappable field styled like the
                    // dropdowns above; opens the same bottom sheet as web.
                    if (_selectedOrderType == 'khata') ...[
                      _buildMobileCustomerSelector(),
                      const SizedBox(height: 14),
                    ],

                    // Payment Method
                    _buildDropdown(
                      icon: Icons.credit_card_outlined,
                      value: _selectedPaymentMethod,
                      items: _paymentMethods,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPaymentMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Fixed Confirm button at the bottom
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isConfirmingOrder ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isConfirmingOrder
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Confirm",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tappable field styled like the other dropdowns, showing the selected
  // Khata customer (or a prompt) and opening the shared bottom sheet.
  Widget _buildMobileCustomerSelector() {
    final hasCustomer = _selectedCustomer != null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isLoadingCustomers
          ? null
          : () {
              if (_customers.isEmpty) {
                _fetchKhataCustomers();
              } else {
                _showCustomerSelectionBottomSheet();
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasCustomer ? const Color(0xFFFF5500) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: _isLoadingCustomers
                  ? const Text(
                      "Loading customers...",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    )
                  : Text(
                      hasCustomer
                          ? _selectedCustomer!.fullName
                          : "Select Customer Khata",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: hasCustomer ? Colors.black87 : Colors.black54,
                      ),
                    ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtotal
        _buildSummaryRow("Subtotal:", "PKR ${subtotal.toStringAsFixed(0)}"),

        const SizedBox(height: 20),

        // Discount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Discount:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "0",
                  prefixText: "PKR ",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF5500), width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    discount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Net Total
        _buildSummaryRow("Net Total:", "PKR ${netTotal.toStringAsFixed(0)}"),

        const SizedBox(height: 40),

        // Order Type
        _buildDropdown(
          icon: Icons.receipt_long_outlined,
          value: _selectedOrderType,
          items: _orderTypes,
          onChanged: _onOrderTypeChanged,
        ),

        // Selected Customer
        if (_selectedOrderType == 'khata') ...[
          const SizedBox(height: 8),

          GestureDetector(
            onTap: _showCustomerSelectionBottomSheet,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                _selectedCustomer != null
                    ? "Selected Customer: ${_selectedCustomer!.fullName}"
                    : "Tap to select a Khata customer",
                style: TextStyle(
                  color: _selectedCustomer != null
                      ? const Color(0xFFFF5500)
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Payment Method
        _buildDropdown(
          icon: Icons.credit_card_outlined,
          value: _selectedPaymentMethod,
          items: _paymentMethods,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPaymentMethod = val;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 12),

          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,

                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),

                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(
                      item['label']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),

                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
