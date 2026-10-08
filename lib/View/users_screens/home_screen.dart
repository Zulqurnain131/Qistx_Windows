import 'package:flutter/material.dart';
import 'package:qistx_app/Controllers/CustomerController.dart';
import 'package:qistx_app/View/auth_screens/auth_screen.dart';
import 'package:qistx_app/View/products/add_new_product.dart';
import 'package:qistx_app/View/products/cart.dart';
import 'package:qistx_app/View/products/inventrycatelog.dart';
import 'package:qistx_app/View/products/orderinventory.dart';
import 'package:qistx_app/View/profilecreation/create_customer_profile.dart';
import 'package:qistx_app/View/profilecreation/view_customer.dart';
import 'package:qistx_app/View/users_screens/helpandsupport.dart';
import 'package:qistx_app/View/users_screens/setting.dart';
import 'package:qistx_app/View/users_screens/staticsandreports.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Providers/home_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CustomerController _customerController = CustomerController();
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false; // Controls desktop sidebar toggle
  /// Variables
  bool _showTotalSales = true;
  bool _showUdhaar = true;
  bool _showCollection = true;
  //// Varibales End
  @override
  void initState() {
    super.initState();

    _saveCurrentScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _saveCurrentScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_screen", "home");
  }

  ///// Dashboard Data
  Future<void> _loadDashboardData() async {
    final shopId = await _customerController.getCurrentShopId();

    if (shopId == null) {
      debugPrint('Shop not found.');
      return;
    }

    if (!mounted) return;

    final provider = context.read<HomeProvider>();

    await Future.wait([
      provider.getDashboardMetrics(shopId: shopId),

      provider.getLiquidityTrend(
        shopId: shopId,
        duration: provider.selectedLiquidityDuration,
      ),

      provider.getTopProductsBySales(
        shopId: shopId,
        duration: provider.selectedBarDuration,
      ),
    ]);
  }

  Future<void> _changeLiquidityDuration(String duration) async {
    final provider = context.read<HomeProvider>();

    if (provider.selectedLiquidityDuration == duration) {
      return;
    }

    final shopId = await _customerController.getCurrentShopId();

    if (shopId == null) {
      return;
    }

    await provider.getLiquidityTrend(shopId: shopId, duration: duration);
  }

  Widget _buildLiquidityChart(HomeProvider provider) {
    debugPrint('Today Liquidity Data: ${provider.liquidityTrend}');
    if (provider.isLiquidityLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (provider.liquidityError != null) {
      return Center(
        child: Text(
          'Unable to load chart data',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    if (provider.liquidityTrend.isEmpty) {
      return Center(
        child: Text(
          'No sales data available',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        data: provider.liquidityTrend,
        duration: provider.selectedLiquidityDuration,
        showTotalSales: _showTotalSales,
        showUdhaar: _showUdhaar,
        showCollection: _showCollection,
      ),
    );
  }

  /////////////////////Line Chart Function end  ///////

  Future<void> _changeBarChartDuration(String duration) async {
    final provider = context.read<HomeProvider>();

    if (provider.selectedBarDuration == duration) {
      return;
    }

    final shopId = await _customerController.getCurrentShopId();

    if (shopId == null) {
      return;
    }

    await provider.getTopProductsBySales(shopId: shopId, duration: duration);
  }

  ///// Bar Chart Function calling End

  double _getMetricValue(Map<String, dynamic>? data, String key) {
    if (data == null) return 0;

    final value = data[key];

    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatPercentage(double value) {
    if (value > 0) {
      return '↑ ${value.toStringAsFixed(2)}% vs Yesterday';
    }

    if (value < 0) {
      return '↓ ${value.abs().toStringAsFixed(2)}% vs Yesterday';
    }

    return '0% vs Yesterday';
  }

  String _formatAmount(double value) {
    return '${value.toStringAsFixed(0)} PKR';
  }

  double _safeRatio(double part, double whole) {
    if (whole <= 0) return 0;
    return (part / whole).clamp(0.0, 1.0);
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Lazy loading function: Sirf wahi screen build hogi jo screen par active hai
  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return _buildHomeDashboard();
      case 1:
        return const Orderinventory();
      case 2:
        return const ViewCustomer();
      case 3:
        return const Inventrycatelog();
      case 4:
        return Staticsandreports();
      case 5:
        return Setting();
      case 6:
        return Helpandsupport();
      default:
        return _buildHomeDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop / Wide Screen View (Width >= 900)
        if (constraints.maxWidth >= 900) {
          return _buildDesktopLayout();
        }

        // Unchanged Original Mobile View
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(child: _getSelectedScreen(_selectedIndex)),
          bottomNavigationBar: _buildCustomBottomNavigationBar(),
        );
      },
    );
  }

  // ==========================================
  // DESKTOP LAYOUT & COMPONENTS
  // ==========================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Row(
        children: [
          // Collapsible Sidebar
          _buildDesktopSidebar(),

          // Main Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                // Rounded corners ke baahar image nahi niklegi
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Waves Image (Ab sirf is White Card ke andar bottom-right par rahegi)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/auth_confirmation_pin.png',
                        width: 350,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Opacity(
                            opacity: 0.15,
                            child: CustomPaint(
                              size: const Size(300, 180),
                              painter: _WavePainter(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Selected Screen Content
                    Positioned.fill(
                      child: _selectedIndex == 0
                          ? _buildDesktopDashboard()
                          : _getSelectedScreen(_selectedIndex),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Floating Sidebar
  Widget _buildDesktopSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isSidebarCollapsed ? 80 : 220,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD8CC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ Real available width se decide karo — animation ke beech
          // kabhi bhi is se zyada content force nahi hoga
          final bool showLabels = constraints.maxWidth > 120;

          return Column(
            children: [
              // Logo & Collapse Toggle Header
              Row(
                mainAxisAlignment: showLabels
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showLabels) ...[
                    Flexible(
                      child: Image.asset(
                        'assets/Icons/Qist_Logo_trans.png',
                        height: 100,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.show_chart,
                            color: Color(0xFFFF5722),
                            size: 28,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      icon: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A2A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 2,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _isSidebarCollapsed = true),
                    ),
                  ] else ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/Icons/Qist_Icons_trans.png',
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () =>
                          setState(() => _isSidebarCollapsed = false),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),

              // Sidebar Navigation Items
              Expanded(
                child: ListView(
                  children: [
                    _buildSidebarNavItem(
                      0,
                      Icons.home_rounded,
                      "Dashboard",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      1,
                      Icons.receipt_long,
                      "Orders",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      2,
                      Icons.people,
                      "Customers",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      3,
                      Icons.inventory_2,
                      "Inventory",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      4,
                      Icons.analytics_outlined,
                      "Stats",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      5,
                      Icons.settings,
                      "Settings",
                      showLabels,
                    ),
                    _buildSidebarNavItem(
                      6,
                      Icons.help_outline,
                      "Help & Support",
                      showLabels,
                    ),
                  ],
                ),
              ),

              // Logout Button
              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Colors.white, size: 20),
                      if (showLabels) ...[
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            "Logout",
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarNavItem(
    int index,
    IconData icon,
    String label,
    bool showLabel,
  ) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() {
              _selectedIndex = index;
            });

            if (index == 0) {
              await _loadDashboardData();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFEDE3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: showLabel
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? const Color(0xFFFF5722)
                      : Colors.grey.shade600,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFFF5722)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Desktop Main Dashboard Screen
  Widget _buildDesktopDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header
          const Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Top 3 Stat Cards Row
          // Top 3 Stat Cards Row
          Consumer<HomeProvider>(
            builder: (context, provider, child) {
              final Map<String, dynamic> salesData = Map<String, dynamic>.from(
                provider.dashboardMetrics['sales'] ?? {},
              );

              final Map<String, dynamic> udharData = Map<String, dynamic>.from(
                provider.dashboardMetrics['udhar'] ?? {},
              );

              final Map<String, dynamic> collectionData =
                  Map<String, dynamic>.from(
                    provider.dashboardMetrics['collection'] ?? {},
                  );

              final double totalSales = _getMetricValue(
                salesData,
                'total_today',
              );

              final double cashSales = _getMetricValue(salesData, 'cash_today');

              final double udharSales = _getMetricValue(
                salesData,
                'udhar_today',
              );

              final double salesTrend = _getMetricValue(
                salesData,
                'trend_percentage',
              );

              final double todayUdhar = _getMetricValue(
                udharData,
                'today_new_udhar',
              );

              final double totalMarketUdhar = _getMetricValue(
                udharData,
                'total_market_udhar',
              );

              final double totalMaxCreditLimit = _getMetricValue(
                udharData,
                'total_max_credit_limit',
              );

              final double udharTrend = _getMetricValue(
                udharData,
                'trend_percentage',
              );

              final double todayCollection = _getMetricValue(
                collectionData,
                'today_collection',
              );

              final double remainingUdhar = _getMetricValue(
                collectionData,
                'remaining_udhar_to_collect',
              );

              final double collectionTrend = _getMetricValue(
                collectionData,
                'trend_percentage',
              );

              return Row(
                children: [
                  Expanded(
                    child: _buildDesktopTopCard(
                      title: "Today's Sales",
                      amount: provider.isDashboardLoading
                          ? 'Loading...'
                          : _formatAmount(totalSales),
                      subtext: provider.isDashboardLoading
                          ? 'Please wait'
                          : _formatPercentage(salesTrend),
                      leftLabel: provider.isDashboardLoading
                          ? 'Cash'
                          : 'Cash: ${_formatAmount(cashSales)}',
                      rightLabel: provider.isDashboardLoading
                          ? 'Udhaar'
                          : 'Udhaar: ${_formatAmount(udharSales)}',
                      isFilled: true,
                      progress: _safeRatio(cashSales, totalSales),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: _buildDesktopTopCard(
                      title: "Today's Udhaar",
                      amount: provider.isDashboardLoading
                          ? 'Loading...'
                          : _formatAmount(todayUdhar),
                      subtext: provider.isDashboardLoading
                          ? 'Please wait'
                          : _formatPercentage(udharTrend),
                      leftLabel: provider.isDashboardLoading
                          ? 'Used'
                          : 'Used: ${_formatAmount(totalMarketUdhar)}',
                      rightLabel: provider.isDashboardLoading
                          ? 'Limit'
                          : 'Limit: ${_formatAmount(totalMaxCreditLimit)}',
                      isFilled: false,
                      progress: _safeRatio(
                        totalMarketUdhar,
                        totalMaxCreditLimit,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: _buildDesktopTopCard(
                      title: "Today's Collection",
                      amount: provider.isDashboardLoading
                          ? 'Loading...'
                          : _formatAmount(todayCollection),
                      subtext: provider.isDashboardLoading
                          ? 'Please wait'
                          : _formatPercentage(collectionTrend),
                      leftLabel: provider.isDashboardLoading
                          ? 'Collection'
                          : 'Collection: ${_formatAmount(todayCollection)}',
                      rightLabel: provider.isDashboardLoading
                          ? 'Udhaar'
                          : 'Udhaar: ${_formatAmount(remainingUdhar)}',
                      isFilled: true,
                      progress: _safeRatio(
                        todayCollection,
                        todayCollection + remainingUdhar,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Quick Action Center & Action Required Side-by-Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Action Center
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Action Center",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 190,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDesktopQuickAction(
                            Icons.add_box_outlined,
                            "Add\nProduct",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddNewProduct(),
                                ),
                              );
                            },
                          ),
                          _buildDesktopQuickAction(
                            Icons.receipt_long_outlined,
                            "View\nCart",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddNewProduct(),
                                ),
                              );
                            },
                          ),
                          _buildDesktopQuickAction(
                            Icons.person_add_alt_outlined,
                            "Add\nCustomer",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateCustomerProfile(),
                                ),
                              );
                            },
                          ),
                          _buildDesktopQuickAction(
                            Icons.payments_outlined,
                            "Receive\nPayment",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddNewProduct(),
                                ),
                              );
                            },
                          ),
                          _buildDesktopQuickAction(
                            Icons.insert_drive_file_outlined,
                            "View\nReports",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddNewProduct(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Action Required Table
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Action Required",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD8CC),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Name",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Variant/Item",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Value",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Actions",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildActionTableRow(
                            "Inventory Shortfall",
                            "Black-Shirt-234",
                            "Qty: 20",
                            "ReStock",
                          ),
                          _buildActionTableRow(
                            "Critical Out of Stock",
                            "Black-Shirt-234",
                            "Qty: 0",
                            "ReStock",
                          ),
                          _buildActionTableRow(
                            "Expiry Warning",
                            "Black-Shirt-234",
                            "Qty: 15",
                            "Liquidate",
                          ),
                          _buildActionTableRow(
                            "Defaulter Account",
                            "John Doe",
                            "Amt: 15",
                            "Liquidate",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liquidity Trend Chart
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Liquidity Trend",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Consumer<HomeProvider>(
                          builder: (context, provider, child) {
                            return Row(
                              children: [
                                _buildFilterChip(
                                  "Yearly",
                                  provider.selectedLiquidityDuration ==
                                      'yearly',
                                  onTap: () =>
                                      _changeLiquidityDuration('yearly'),
                                ),
                                _buildFilterChip(
                                  "Month",
                                  provider.selectedLiquidityDuration ==
                                      'monthly',
                                  onTap: () =>
                                      _changeLiquidityDuration('monthly'),
                                ),
                                _buildFilterChip(
                                  "Weekly",
                                  provider.selectedLiquidityDuration ==
                                      'weekly',
                                  onTap: () =>
                                      _changeLiquidityDuration('weekly'),
                                ),
                                _buildFilterChip(
                                  "Today",
                                  provider.selectedLiquidityDuration == 'today',
                                  onTap: () =>
                                      _changeLiquidityDuration('today'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD8CC),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Consumer<HomeProvider>(
                            builder: (context, provider, child) {
                              return SizedBox(
                                height: 180,
                                child: _buildLiquidityChart(provider),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ChartLegend(
                                color: Colors.blue,
                                label: "Total Sales",
                                isActive: _showTotalSales,
                                onTap: () {
                                  setState(() {
                                    _showTotalSales = !_showTotalSales;
                                  });
                                },
                              ),

                              const SizedBox(width: 24),

                              _ChartLegend(
                                color: Colors.orange,
                                label: "Udhaar",
                                isActive: _showUdhaar,
                                onTap: () {
                                  setState(() {
                                    _showUdhaar = !_showUdhaar;
                                  });
                                },
                              ),

                              const SizedBox(width: 24),

                              _ChartLegend(
                                color: Colors.teal,
                                label: "Collection",
                                isActive: _showCollection,
                                onTap: () {
                                  setState(() {
                                    _showCollection = !_showCollection;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Category Bar Chart
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Consumer<HomeProvider>(
                      builder: (context, provider, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildFilterChip(
                              "Yearly",
                              provider.selectedBarDuration == 'yearly',
                              onTap: () => _changeBarChartDuration('yearly'),
                            ),
                            _buildFilterChip(
                              "Month",
                              provider.selectedBarDuration == 'monthly',
                              onTap: () => _changeBarChartDuration('monthly'),
                            ),
                            _buildFilterChip(
                              "Weekly",
                              provider.selectedBarDuration == 'weekly',
                              onTap: () => _changeBarChartDuration('weekly'),
                            ),
                            _buildFilterChip(
                              "Today",
                              provider.selectedBarDuration == 'today',
                              onTap: () => _changeBarChartDuration('today'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD8CC),
                          width: 1.5,
                        ),
                      ),
                      child: Consumer<HomeProvider>(
                        builder: (context, provider, child) {
                          return SizedBox(
                            height: 212,
                            child: _buildBarChart(provider),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(HomeProvider provider) {
    if (provider.isTopProductsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (provider.topProductsError != null) {
      return const Center(
        child: Text(
          'Unable to load chart data',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    if (provider.topProducts.isEmpty) {
      return const Center(
        child: Text(
          'No sales data available',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(data: provider.topProducts),
    );
  }

  // Desktop Top Cards Widget
  Widget _buildDesktopTopCard({
    required String title,
    required String amount,
    required String subtext,
    required String leftLabel,
    required String rightLabel,
    required bool isFilled,
    required double progress, // 0.0 se 1.0
  }) {
    final bgColor = isFilled ? const Color(0xFFFF5722) : Colors.white;
    final textColor = isFilled ? Colors.white : const Color(0xFFFF5722);

    final double safeProgress = progress.isNaN ? 0 : progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Progress line (ab percentage ke hisaab se bharti hai)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                // Track
                Container(
                  height: 5,
                  width: double.infinity,
                  color: isFilled
                      ? Colors.white.withOpacity(0.35)
                      : const Color(0xFFFFD8CC),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: safeProgress,
                  child: Container(
                    height: 5,
                    color: isFilled ? Colors.white : const Color(0xFFFF5722),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  leftLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rightLabel,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopQuickAction(
    IconData icon,
    String title, [
    VoidCallback? onTap,
  ]) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Mouse hover par hand icon ke liye
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 85,
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTableRow(
    String name,
    String variant,
    String value,
    String actionText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              variant,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {},
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF5722),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UNCHANGED MOBILE COMPONENTS
  // ==========================================

  // Bottom Navigation Bar Function
  Widget _buildCustomBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          setState(() {
            _selectedIndex = index;
          });

          // Dashboard par wapas aane par fresh data load karo
          if (index == 0) {
            await _loadDashboardData();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // Mobile Home Screen UI Function
  Widget _buildHomeDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEFEFEF),
                child: Icon(Icons.person, color: Colors.grey),
              ),
              const Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5722),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Today's Sales & Udhaar Cards
          Consumer<HomeProvider>(
            builder: (context, provider, child) {
              final Map<String, dynamic> salesData = Map<String, dynamic>.from(
                provider.dashboardMetrics['sales'] ?? {},
              );

              final Map<String, dynamic> udharData = Map<String, dynamic>.from(
                provider.dashboardMetrics['udhar'] ?? {},
              );

              final double totalSales = _getMetricValue(
                salesData,
                'total_today',
              );

              final double todayUdhar = _getMetricValue(
                udharData,
                'today_new_udhar',
              );

              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Sales",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.isDashboardLoading
                                ? "Loading..."
                                : totalSales.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "PKR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFFF5722),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Udhaar",
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.isDashboardLoading
                                ? "Loading..."
                                : todayUdhar.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "PKR",
                            style: TextStyle(
                              color: Color(0xFFFF5722),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Action Center
          const Text(
            "Quick Action Center",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionItem(Icons.add_box_outlined, "Add\nProduct"),
                _buildQuickActionItem(
                  Icons.receipt_long_outlined,
                  "Create\nInvoice",
                ),
                _buildQuickActionItem(
                  Icons.person_add_alt_outlined,
                  "Add\nCustomer",
                ),
                _buildQuickActionItem(
                  Icons.payments_outlined,
                  "Receive\nPayment",
                ),
                _buildQuickActionItem(
                  Icons.insert_drive_file_outlined,
                  "View\nReports",
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Liquidity Trend Chart Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Liquidity Trend",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Consumer<HomeProvider>(
                builder: (context, provider, child) {
                  return Row(
                    children: [
                      _buildFilterChip(
                        "Yearly",
                        provider.selectedLiquidityDuration == 'yearly',
                        onTap: () => _changeLiquidityDuration('yearly'),
                      ),
                      _buildFilterChip(
                        "Month",
                        provider.selectedLiquidityDuration == 'monthly',
                        onTap: () => _changeLiquidityDuration('monthly'),
                      ),
                      _buildFilterChip(
                        "Weekly",
                        provider.selectedLiquidityDuration == 'weekly',
                        onTap: () => _changeLiquidityDuration('weekly'),
                      ),
                      _buildFilterChip(
                        "Today",
                        provider.selectedLiquidityDuration == 'today',
                        onTap: () => _changeLiquidityDuration('today'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Consumer<HomeProvider>(
                  builder: (context, provider, child) {
                    final double chartWidth = math.max(
                      MediaQuery.of(context).size.width - 32,
                      provider.liquidityTrend.length * 50.0,
                    );

                    return SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          height: 120,
                          child: _buildLiquidityChart(provider),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ChartLegend(
                      color: Colors.blue,
                      label: "Total Sales",
                      isActive: _showTotalSales,
                      onTap: () {
                        setState(() {
                          _showTotalSales = !_showTotalSales;
                        });
                      },
                    ),

                    _ChartLegend(
                      color: Colors.orange,
                      label: "Udhaar",
                      isActive: _showUdhaar,
                      onTap: () {
                        setState(() {
                          _showUdhaar = !_showUdhaar;
                        });
                      },
                    ),

                    _ChartLegend(
                      color: Colors.teal,
                      label: "Collection",
                      isActive: _showCollection,
                      onTap: () {
                        setState(() {
                          _showCollection = !_showCollection;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Required Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Action Required",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("View All", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildActionCard(
            Icons.shopping_cart_outlined,
            "Low Stock Warning: Black Shirt",
            "Remaining Stock: 20",
          ),
          _buildActionCard(
            Icons.warning_amber_rounded,
            "Out of Stock: Black Shirt",
            "Remaining Stock: 20",
          ),
          _buildActionCard(
            Icons.history_outlined,
            "Expiry Stock Warning: Black Shirt",
            "Remaining Stock: 20",
          ),
          _buildActionCard(
            Icons.card_membership_outlined,
            "Defaulter Alert: John Doe",
            "Overdue Amount: 2000",
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String title) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5722) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Settings View
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.black87 : Colors.grey.shade400,
              fontWeight: FontWeight.w500,
              decoration: isActive
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM CHART PAINTERS FOR EXACT DASHBOARD VISUALS
// ==========================================

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String duration;
  final bool showTotalSales;
  final bool showUdhaar;
  final bool showCollection;

  _LineChartPainter({
    required this.data,
    required this.duration,
    required this.showTotalSales,
    required this.showUdhaar,
    required this.showCollection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double leftPadding = 45;
    const double bottomPadding = 45; // Labels ke liye extra space
    const double topPadding = 10;

    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding - topPadding;

    // =========================
    // Grid
    // =========================

    // =========================
    // Values
    // =========================

    double getValue(Map<String, dynamic> item, String key) {
      final value = item[key];

      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    final List<double> totalSales = data
        .map((item) => getValue(item, 'total_sales'))
        .toList();

    final List<double> udhaar = data
        .map((item) => getValue(item, 'udhaar_sales'))
        .toList();

    final List<double> collection = data
        .map((item) => getValue(item, 'collection'))
        .toList();

    double maxValue = 0;

    for (final value in totalSales) {
      if (value > maxValue) maxValue = value;
    }

    for (final value in udhaar) {
      if (value > maxValue) maxValue = value;
    }

    for (final value in collection) {
      if (value > maxValue) maxValue = value;
    }

    // Prevent division by zero
    // =========================
    // Y-Axis scale + Grid + Labels
    // =========================

    const int gridLines = 4; // 5 labels: 0 se max tak

    if (maxValue <= 0) {
      maxValue = 1;
    }
    // Raw max ko nice number bana do: 50000 -> step 15000, max 60000
    final double step = _niceStep(maxValue / gridLines);
    maxValue = step * gridLines; // points isi scale par normalize honge

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = topPadding + chartHeight - (i * chartHeight / gridLines);

      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      final TextPainter yLabel = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(step * i),
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      yLabel.paint(
        canvas,
        Offset(leftPadding - yLabel.width - 6, y - (yLabel.height / 2)),
      );
    }

    // Raw max ko nice number bana do: 50000 -> step 15000, max 60000

    // =========================
    // Convert data to points
    // =========================

    List<Offset> createPoints(List<double> values) {
      final List<Offset> points = [];

      for (int i = 0; i < values.length; i++) {
        final double x = data.length == 1
            ? leftPadding + chartWidth / 2
            : leftPadding + (i * chartWidth / (data.length - 1));

        final double normalized = values[i] / maxValue;

        final double y = topPadding + chartHeight - (normalized * chartHeight);

        points.add(Offset(x, y));
      }

      return points;
    }

    final salesPoints = createPoints(totalSales);
    final udhaarPoints = createPoints(udhaar);
    final collectionPoints = createPoints(collection);

    // =========================
    // Draw lines
    // =========================

    if (showTotalSales) {
      _drawLine(canvas, salesPoints, const Color(0xFF1E88E5));
    }

    if (showUdhaar) {
      _drawLine(canvas, udhaarPoints, const Color(0xFFFF7043));
    }

    if (showCollection) {
      _drawLine(canvas, collectionPoints, const Color(0xFF26A69A));
    }

    // =========================
    // Draw X-Axis Labels
    // =========================

    // =========================
    // Draw X-Axis Labels
    // =========================

    int labelStep;

    if (duration == 'yearly') {
      // Jan, Feb, Mar ... Dec
      labelStep = 1;
    } else if (duration == 'monthly') {
      // Show every 5th day approximately
      labelStep = 5;
    } else if (duration == 'weekly') {
      // Mon, Tue, Wed ... Sun
      labelStep = 1;
    } else {
      // Today
      // Show fewer labels depending on data
      labelStep = data.length > 12 ? 3 : 1;
    }

    for (int i = 0; i < data.length; i++) {
      // Skip unnecessary labels
      if (i % labelStep != 0 && i != data.length - 1) {
        continue;
      }

      final String label = data[i]['label']?.toString() ?? '';

      final double x = data.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (i * chartWidth / (data.length - 1));

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();

      labelPainter.paint(
        canvas,
        Offset(x - (labelPainter.width / 2), size.height - 30),
      );
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  double _niceStep(double rawStep) {
    if (rawStep <= 0) return 1;

    final double exponent = (math.log(rawStep) / math.ln10).floorToDouble();
    final double magnitude = math.pow(10, exponent).toDouble();
    final double normalized = rawStep / magnitude;

    const List<double> niceValues = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];

    for (final double nice in niceValues) {
      if (normalized <= nice) return nice * magnitude;
    }

    return 10 * magnitude;
  }

  String _formatAxisValue(double value) {
    if (value == 0) return '0';

    if (value >= 1000000) {
      final double m = value / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      final double k = value / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }

    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.duration != duration ||
        oldDelegate.showTotalSales != showTotalSales ||
        oldDelegate.showUdhaar != showUdhaar ||
        oldDelegate.showCollection != showCollection;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 45; // Y-axis labels ke liye thori zyada jagah
    const double bottomPadding = 30;
    const double topPadding = 10;
    const int gridLines = 3; // 4 labels: 0 se max tak

    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding - topPadding;

    // =========================
    // Get Values
    // =========================

    double getRevenue(Map<String, dynamic> item) {
      final value = item['total_revenue'];
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final List<double> revenues = data.map((item) => getRevenue(item)).toList();

    double maxValue = 0;
    for (final value in revenues) {
      if (value > maxValue) maxValue = value;
    }

    if (maxValue <= 0) maxValue = 1;

    // Nice scale: 15000 -> step 5000, max 15000
    final double step = _niceStep(maxValue / gridLines);
    maxValue = step * gridLines;

    // =========================
    // Grid + Y-Axis Labels
    // =========================

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = topPadding + chartHeight - (i * chartHeight / gridLines);

      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      final TextPainter yLabel = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(step * i),
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      yLabel.paint(
        canvas,
        Offset(leftPadding - yLabel.width - 6, y - (yLabel.height / 2)),
      );
    }

    // =========================
    // Bar Width
    // =========================

    final int itemCount = data.length;
    double barWidth = 32;

    if (itemCount > 0) {
      final double availableWidth = chartWidth - 20;
      barWidth = (availableWidth / (itemCount * 1.7)).clamp(20.0, 50.0);
    }

    final double totalBarsWidth = itemCount * barWidth;
    final double spacing = itemCount > 0
        ? (chartWidth - totalBarsWidth) / (itemCount + 1)
        : 0;

    final barPaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill;

    // =========================
    // Draw Bars
    // =========================

    for (int i = 0; i < itemCount; i++) {
      final double revenue = revenues[i];
      final double normalized = revenue / maxValue;
      final double barHeight = chartHeight * normalized;

      final double x = leftPadding + spacing + i * (barWidth + spacing);
      final double y = topPadding + chartHeight - barHeight;

      final RRect rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      canvas.drawRRect(rect, barPaint);

      // Bar ke upar exact value (optional, chahein to hata dein)
      final TextPainter valuePainter = TextPainter(
        text: TextSpan(
          text: _formatAxisValue(revenue),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      valuePainter.paint(
        canvas,
        Offset(
          x + (barWidth / 2) - (valuePainter.width / 2),
          y - valuePainter.height - 4,
        ),
      );

      // =========================
      // Product Name
      // =========================

      String productName = data[i]['product_name']?.toString() ?? '';

      if (productName.length > 9) {
        productName = '${productName.substring(0, 8)}...';
      }

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: productName,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout(maxWidth: barWidth + 20);

      labelPainter.paint(
        canvas,
        Offset(x + (barWidth / 2) - (labelPainter.width / 2), size.height - 18),
      );
    }
  }

  double _niceStep(double rawStep) {
    if (rawStep <= 0) return 1;

    final double exponent = (math.log(rawStep) / math.ln10).floorToDouble();
    final double magnitude = math.pow(10, exponent).toDouble();
    final double normalized = rawStep / magnitude;

    const List<double> niceValues = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];

    for (final double nice in niceValues) {
      if (normalized <= nice) return nice * magnitude;
    }

    return 10 * magnitude;
  }

  String _formatAxisValue(double value) {
    if (value == 0) return '0';

    if (value >= 1000000) {
      final double m = value / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M';
    }

    if (value >= 1000) {
      final double k = value / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }

    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// Background Wave Fallback Painter
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD8CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final path = Path();
    path.moveTo(0, size.height);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.9,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
