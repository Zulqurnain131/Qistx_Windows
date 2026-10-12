import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Controllers/CustomerController.dart';
import 'package:qistx_app/Customwidgets/StatisticsOrderTableCard.dart';
import 'package:qistx_app/Customwidgets/StatisticsPaymentMethodCard.dart';
import 'package:qistx_app/Customwidgets/StatisticsReportCard.dart';
import 'package:qistx_app/Customwidgets/Statistics_Screen_Widgets.dart';
import 'package:qistx_app/Providers/StatisticsProvider.dart';
import 'package:qistx_app/Providers/home_provider.dart';

class Staticsandreports extends StatefulWidget {
  const Staticsandreports({super.key});

  @override
  State<Staticsandreports> createState() => _StaticsandreportsState();
}

class _StaticsandreportsState extends State<Staticsandreports> {
  final Customercontroller _customerController = Customercontroller();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shopId = await _customerController.getCurrentShopId();

      if (!mounted || shopId == null) return;

      final provider = context.read<Statisticsprovider>();

      await Future.wait([
        provider.loadPaymentMethodStatistics(shopId, 'yearly'),
        provider.loadTopDebtors(shopId),
        provider.loadStatsMetrics(shopId),
        provider.loadOverdueAccounts(shopId),
        provider.loadDeadStock(shopId),
        provider.loadTopSellingProducts(shopId, 'yearly'),
        provider.loadProductProfitMargins(shopId, 'yearly'),
      ]);
    });
  }

  String selectedPaymentDuration = 'yearly';
  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.tealAccent.shade700;

      case 'card':
        return Colors.blue;

      case 'easypaisa':
        return Colors.green;

      case 'bank':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: const Text(
      //     "Statics & Reports",
      //     style: TextStyle(color: Colors.black),
      //   ),
      //   backgroundColor: Colors.white,
      //   surfaceTintColor: Colors.transparent,
      //   scrolledUnderElevation: 0,
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      // ),
      body: Stack(
        children: [
          // 1. Fixed Background Image at Bottom Right (Yeh hamesha fixed rahegi)

          Positioned(
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.sizeOf(context).width;

                  if (screenWidth < 900) {
                    return const SizedBox.shrink();
                  }

                  return Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      'assets/images/auth_confirmation_pin.png',
                      width: 400,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Scrollable Screen Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 30),
                  child: const Text(
                    "Statistics & Reports",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600
                      ? 16
                      : MediaQuery.sizeOf(context).width < 900
                      ? 22
                      : 30,
                ),
                // Top 4 Metric Cards Row
                // Top 4 Metric Cards Responsive Section
                Consumer<Statisticsprovider>(
                  builder: (context, provider, child) {
                    // Loading
                    if (provider.isStatsMetricsLoading) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Error
                    if (provider.statsMetricsError != null) {
                      return SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            provider.statsMetricsError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final metrics = provider.statsMetrics;

                    // API data
                    final aov =
                        metrics?['average_order_value']
                            as Map<String, dynamic>?;

                    final khata =
                        metrics?['active_khata'] as Map<String, dynamic>?;

                    final margin =
                        metrics?['avg_gross_margin'] as Map<String, dynamic>?;

                    final overdue =
                        metrics?['overdue'] as Map<String, dynamic>?;

                    // Values
                    final aovValue = (aov?['value'] as num?)?.toDouble() ?? 0;
                    final aovChange =
                        (aov?['change_pct'] as num?)?.toDouble() ?? 0;

                    final khataTotal = (khata?['total'] as num?)?.toInt() ?? 0;
                    final khataNew =
                        (khata?['new_this_month'] as num?)?.toInt() ?? 0;

                    final marginValue =
                        (margin?['value'] as num?)?.toDouble() ?? 0;
                    final marginChange =
                        (margin?['change_pct'] as num?)?.toDouble() ?? 0;

                    final overdueAmount =
                        (overdue?['net_total'] as num?)?.toDouble() ?? 0;

                    // Build card widgets list
                    final cardList = [
                      // 1. Average Order Value
                      StatisticsScreenWidgets.buildStatCard(
                        title: "Average Order Value",
                        value: "${aovValue.toStringAsFixed(0)} PKR",
                        subtitle:
                            "${aovChange >= 0 ? '↑' : '↓'} ${aovChange.abs().toStringAsFixed(1)}% vs Yesterday",
                        isPrimary: true,
                        subtitleColor: aovChange >= 0
                            ? Colors.white
                            : Colors.red.shade100,
                      ),
                      // 2. Active Khata Accounts
                      StatisticsScreenWidgets.buildStatCard(
                        title: "Active Khata Accounts",
                        value: khataTotal.toString(),
                        subtitle: "$khataNew New this month",
                        isPrimary: false,
                        subtitleColor: Colors.green,
                      ),
                      // 3. Avg Gross Margin
                      StatisticsScreenWidgets.buildStatCard(
                        title: "Avg Gross Margin",
                        value: "${marginValue.toStringAsFixed(1)}%",
                        subtitle:
                            "${marginChange >= 0 ? '+' : ''}${marginChange.toStringAsFixed(1)}% vs Previous",
                        isPrimary: false,
                        subtitleColor: marginChange >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      // 4. Total Overdue Amount
                      StatisticsScreenWidgets.buildStatCard(
                        title: "Total Overdue Amount",
                        value: "${overdueAmount.toStringAsFixed(0)} PKR",
                        subtitle: "Requires Attention",
                        isPrimary: false,
                        subtitleColor: Colors.red,
                      ),
                    ];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;

                        // Desktop / Large screens (900px and above): Single Row with 4 cards
                        if (screenWidth >= 900) {
                          return Row(
                            children: cardList
                                .map(
                                  (card) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: card,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }

                        // Mobile (< 600px) & Tablet (600px - 899px): Clean 2x2 Grid Layout
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: cardList[0]),
                                const SizedBox(width: 8),
                                Expanded(child: cardList[1]),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: cardList[2]),
                                const SizedBox(width: 8),
                                Expanded(child: cardList[3]),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600
                      ? 16
                      : MediaQuery.sizeOf(context).width < 900
                      ? 22
                      : 30,
                ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;

                    // Desktop / Large screens (900px and above): Keep side-by-side Row layout
                    if (screenWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 2,
                            child: StatisticsLiquidityChart(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Consumer<Statisticsprovider>(
                              builder: (context, provider, child) {
                                if (provider.isPaymentMethodLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (provider.paymentMethodError != null) {
                                  return Center(
                                    child: Text(
                                      provider.paymentMethodError!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final paymentData =
                                    provider.paymentMethodStatistics;

                                final totalCount = paymentData.fold<int>(
                                  0,
                                  (sum, item) =>
                                      sum +
                                      ((item['count'] as num?)?.toInt() ?? 0),
                                );

                                return Statisticspaymentmethodcard(
                                  title: "Payment Method",
                                  totalCount: totalCount.toString(),
                                  centerSubText: "Orders",
                                  selectedDuration:
                                      provider.selectedPaymentDuration,
                                  onDurationChanged: (duration) async {
                                    final shopId = await _customerController
                                        .getCurrentShopId();

                                    if (!mounted || shopId == null) return;

                                    await provider.loadPaymentMethodStatistics(
                                      shopId,
                                      duration,
                                    );
                                  },
                                  items: paymentData.map<PaymentLegendItem>((
                                    item,
                                  ) {
                                    final method =
                                        item['method']?.toString() ?? '';
                                    final percentage =
                                        (item['percentage'] as num?)
                                            ?.toStringAsFixed(1) ??
                                        '0';

                                    return PaymentLegendItem(
                                      color: _getPaymentColor(method),
                                      label: "$method ($percentage%)",
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    // Mobile (< 600px) & Tablet (600px - 899px): Stack vertically to avoid horizontal overflow
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StatisticsLiquidityChart(),
                        const SizedBox(height: 16),
                        Consumer<Statisticsprovider>(
                          builder: (context, provider, child) {
                            if (provider.isPaymentMethodLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (provider.paymentMethodError != null) {
                              return Center(
                                child: Text(
                                  provider.paymentMethodError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            final paymentData =
                                provider.paymentMethodStatistics;

                            final totalCount = paymentData.fold<int>(
                              0,
                              (sum, item) =>
                                  sum + ((item['count'] as num?)?.toInt() ?? 0),
                            );

                            return Statisticspaymentmethodcard(
                              title: "Payment Method",
                              totalCount: totalCount.toString(),
                              centerSubText: "Orders",
                              selectedDuration:
                                  provider.selectedPaymentDuration,
                              onDurationChanged: (duration) async {
                                final shopId = await _customerController
                                    .getCurrentShopId();

                                if (!mounted || shopId == null) return;

                                await provider.loadPaymentMethodStatistics(
                                  shopId,
                                  duration,
                                );
                              },
                              items: paymentData.map<PaymentLegendItem>((item) {
                                final method = item['method']?.toString() ?? '';
                                final percentage =
                                    (item['percentage'] as num?)
                                        ?.toStringAsFixed(1) ??
                                    '0';

                                return PaymentLegendItem(
                                  color: _getPaymentColor(method),
                                  label: "$method ($percentage%)",
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600
                      ? 16
                      : MediaQuery.sizeOf(context).width < 900
                      ? 22
                      : 30,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;

                    // Define helper widgets for cards
                    final topDebtorsCard = Consumer<Statisticsprovider>(
                      builder: (context, provider, child) {
                        if (provider.isTopDebtorsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (provider.topDebtorsError != null) {
                          return Center(
                            child: Text(
                              provider.topDebtorsError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        final debtors = provider.topDebtors;

                        return Statisticsreportcard(
                          title: "Top 5 Debtors",
                          header1: "Name",
                          header2: "Amount",
                          header3: null,
                          items: debtors.map<ReportRowItem>((item) {
                            final name =
                                item['full_name']?.toString() ?? 'Unknown';
                            final cnic = item['cnic_no']?.toString() ?? '';
                            final debtAmount =
                                (item['debt_amount'] as num?)?.toDouble() ?? 0;

                            return ReportRowItem(
                              col1Title: name,
                              col1Subtitle: cnic.isNotEmpty
                                  ? "CNIC: $cnic"
                                  : null,
                              col2Text: "${debtAmount.toStringAsFixed(0)} PKR",
                              col2Color: const Color(0xFFFF5722),
                            );
                          }).toList(),
                        );
                      },
                    );

                    // Overdue Accounts
                    final overdueAccountsCard = Consumer<Statisticsprovider>(
                      builder: (context, provider, child) {
                        if (provider.isOverdueAccountsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (provider.overdueAccountsError != null) {
                          return Text(
                            provider.overdueAccountsError!,
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final accounts = provider.overdueAccounts;

                        return Statisticsreportcard(
                          title: "Overdue Accounts",
                          header1: "Name",
                          header2: "Days",
                          header3: "Amount",
                          items: accounts.map<ReportRowItem>((item) {
                            final name = item['name']?.toString() ?? 'Unknown';
                            final days = (item['days'] as num?)?.toInt() ?? 0;
                            final amount =
                                (item['amount'] as num?)?.toDouble() ?? 0;

                            return ReportRowItem(
                              col1Title: name,
                              col2Text: days.toString(),
                              col3Text: "${amount.toStringAsFixed(0)} PKR",
                            );
                          }).toList(),
                        );
                      },
                    );

                    // Dead Stock
                    final deadStockCard = Consumer<Statisticsprovider>(
                      builder: (context, provider, child) {
                        if (provider.isDeadStockLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (provider.deadStockError != null) {
                          return Text(
                            provider.deadStockError!,
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final products = provider.deadStock;

                        return Statisticsreportcard(
                          title: "Dead Stock (> 90 Days)",
                          header1: "Item Name",
                          header2: "Qty",
                          items: products.map<ReportRowItem>((item) {
                            final name =
                                item['item_name']?.toString() ?? 'Unknown';
                            final qty = (item['qty'] as num?)?.toInt() ?? 0;

                            return ReportRowItem(
                              col1Title: name,
                              col2Text: qty.toString(),
                            );
                          }).toList(),
                        );
                      },
                    );

                    // Top 5 Selling Products
                    final topProductsCard = Consumer<Statisticsprovider>(
                      builder: (context, provider, child) {
                        if (provider.isTopSellingProductsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (provider.topSellingProductsError != null) {
                          return Text(
                            provider.topSellingProductsError!,
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final products = provider.topSellingProducts;

                        return Statisticsreportcard(
                          title: "Top Products",
                          filters: const ["Yearly", "Month", "Weekly", "Today"],
                          selectedFilter:
                              switch (provider.selectedTopProductsDuration) {
                                'monthly' => 'Month',
                                'weekly' => 'Weekly',
                                'today' => 'Today',
                                _ => 'Yearly',
                              },
                          onFilterChanged: (filter) async {
                            final duration = switch (filter.toLowerCase()) {
                              'month' => 'monthly',
                              'weekly' => 'weekly',
                              'today' => 'today',
                              _ => 'yearly',
                            };

                            if (duration ==
                                provider.selectedTopProductsDuration)
                              return;

                            final shopId = await _customerController
                                .getCurrentShopId();

                            if (!mounted || shopId == null) return;

                            await provider.loadTopSellingProducts(
                              shopId,
                              duration,
                            );
                          },
                          header1: "Product",
                          header2: "Volume Sold",
                          header3: "Revenue (PKR)",
                          items: products.map<ReportRowItem>((item) {
                            final name =
                                item['product_name']?.toString() ?? 'Unknown';
                            final qty =
                                (item['volume_sold'] as num?)?.toInt() ?? 0;
                            final revenue =
                                (item['revenue'] as num?)?.toDouble() ?? 0;

                            return ReportRowItem(
                              col1Title: name,
                              col2Text: qty.toString(),
                              col3Text: revenue.toStringAsFixed(0),
                            );
                          }).toList(),
                        );
                      },
                    );

                    // Gross Margin Breakdown
                    final grossMarginCard = Consumer<Statisticsprovider>(
                      builder: (context, provider, child) {
                        if (provider.isProductProfitMarginsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (provider.productProfitMarginsError != null) {
                          return Text(
                            provider.productProfitMarginsError!,
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final products = provider.productProfitMargins;

                        return Statisticsreportcard(
                          title: "Gross Margin Breakdown",
                          filters: const ["Yearly", "Month", "Weekly", "Today"],
                          selectedFilter:
                              switch (provider.selectedProfitMarginDuration) {
                                'monthly' => 'Month',
                                'weekly' => 'Weekly',
                                'today' => 'Today',
                                _ => 'Yearly',
                              },
                          onFilterChanged: (filter) async {
                            final duration = switch (filter.toLowerCase()) {
                              'month' => 'monthly',
                              'weekly' => 'weekly',
                              'today' => 'today',
                              _ => 'yearly',
                            };

                            if (duration ==
                                provider.selectedProfitMarginDuration)
                              return;

                            final shopId = await _customerController
                                .getCurrentShopId();

                            if (!mounted || shopId == null) return;

                            await provider.loadProductProfitMargins(
                              shopId,
                              duration,
                            );
                          },
                          header1: "Product",
                          header2: "Avg Sale Price",
                          header3: "Profit Margin",
                          items: products.map<ReportRowItem>((item) {
                            final name =
                                item['product_name']?.toString() ?? 'Unknown';
                            final price =
                                (item['avg_sale_price'] as num?)?.toDouble() ??
                                0;
                            final margin =
                                (item['profit_margin'] as num?)?.toDouble() ??
                                0;

                            return ReportRowItem(
                              col1Title: name,
                              col2Text: "${price.toStringAsFixed(0)} PKR",
                              col3Text: "${margin.toStringAsFixed(1)}%",
                              col3Color: margin >= 0
                                  ? Colors.green
                                  : Colors.red,
                            );
                          }).toList(),
                        );
                      },
                    );

                    // Desktop View (900px and above): Multi-column Rows
                    if (screenWidth >= 900) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: topDebtorsCard),
                              const SizedBox(width: 12),
                              Expanded(child: overdueAccountsCard),
                              const SizedBox(width: 12),
                              Expanded(child: deadStockCard),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: topProductsCard),
                              const SizedBox(width: 12),
                              Expanded(child: grossMarginCard),
                            ],
                          ),
                        ],
                      );
                    }

                    // Mobile & Tablet View (< 900px): Stack vertically to avoid horizontal overflow
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        topDebtorsCard,
                        const SizedBox(height: 20),
                        overdueAccountsCard,
                        const SizedBox(height: 20),
                        deadStockCard,
                        const SizedBox(height: 20),
                        topProductsCard,
                        const SizedBox(height: 20),
                        grossMarginCard,
                      ],
                    );
                  },
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600
                      ? 16
                      : MediaQuery.sizeOf(context).width < 900
                      ? 22
                      : 30,
                ),
                StatisticsOrderTableCard(
                  title: "All Orders",
                  searchController: TextEditingController(),
                  onSearchPressed: () {
                    // Search logic
                  },
                  selectedDate: "19 / 2 / 2026",
                  onDateTap: () {},
                  selectedPaymentFilter: "Payment via",
                  onPaymentFilterTap: () {},
                  currentPage: 1,
                  totalPages: 7,
                  onPageChanged: (page) {},
                  items: [
                    OrderItem(
                      orderId: "#260928-C87CC252",
                      date: "Sep 23, 2026",
                      customerName: "Walk-in Customer",
                      itemsCount: "8 items",
                      totalAmount: "2,000",
                      paymentVia: "Cash",
                    ),
                    OrderItem(
                      orderId: "#260928-C87CC252",
                      date: "Sep 23, 2026",
                      customerName: "Walk-in Customer",
                      itemsCount: "8 items",
                      totalAmount: "2,000",
                      paymentVia: "Cash",
                    ),
                    // Mazeed items yahan add kar sakte hain...
                  ],
                ),

                // Yahan aap mazeed sections add kar sakte hain
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 1. Updated StatisticsLiquidityChart Header
class StatisticsLiquidityChart extends StatefulWidget {
  const StatisticsLiquidityChart({super.key});

  @override
  State<StatisticsLiquidityChart> createState() =>
      _StatisticsLiquidityChartState();
}

class _StatisticsLiquidityChartState extends State<StatisticsLiquidityChart> {
  final Customercontroller _customerController = Customercontroller();

  bool _showTotalSales = true;
  bool _showUdhaar = true;
  bool _showCollection = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLiquidityData();
    });
  }

  Future<void> _loadLiquidityData() async {
    final shopId = await _customerController.getCurrentShopId();

    if (shopId == null || !mounted) return;

    final provider = context.read<HomeProvider>();

    await provider.getLiquidityTrend(
      shopId: shopId,
      duration: provider.selectedLiquidityDuration,
    );
  }

  Future<void> _changeLiquidityDuration(String duration) async {
    final provider = context.read<HomeProvider>();

    if (provider.selectedLiquidityDuration == duration) {
      return;
    }

    final shopId = await _customerController.getCurrentShopId();

    if (shopId == null) return;

    await provider.getLiquidityTrend(shopId: shopId, duration: duration);
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(HomeProvider provider) {
    if (provider.isLiquidityLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (provider.liquidityError != null) {
      return const Center(
        child: Text(
          'Unable to load chart data',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    if (provider.liquidityTrend.isEmpty) {
      return const Center(
        child: Text(
          'No sales data available',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    // Har data point ke liye minimum horizontal space
    const double pointSpacing = 60;
    const double minimumChartWidth = 500;

    final double chartWidth = (provider.liquidityTrend.length * pointSpacing)
        .clamp(minimumChartWidth, double.infinity)
        .toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: chartWidth,
        height: 180,
        child: CustomPaint(
          painter: StatisticsLineChartPainter(
            data: provider.liquidityTrend,
            duration: provider.selectedLiquidityDuration,
            showTotalSales: _showTotalSales,
            showUdhaar: _showUdhaar,
            showCollection: _showCollection,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Title and Horizontally Scrollable Filter Chips
        Row(
          children: [
            const Text(
              "Liquidity Trend",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Consumer<HomeProvider>(
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
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD8CC), width: 1.5),
          ),
          child: Column(
            children: [
              Consumer<HomeProvider>(
                builder: (context, provider, child) {
                  return SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _buildChart(provider),
                  );
                },
              ),

              const SizedBox(height: 16),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 8,
                children: [
                  _StatisticsChartLegend(
                    color: Colors.blue,
                    label: "Total Sales",
                    isActive: _showTotalSales,
                    onTap: () {
                      setState(() {
                        _showTotalSales = !_showTotalSales;
                      });
                    },
                  ),
                  _StatisticsChartLegend(
                    color: Colors.orange,
                    label: "Udhaar",
                    isActive: _showUdhaar,
                    onTap: () {
                      setState(() {
                        _showUdhaar = !_showUdhaar;
                      });
                    },
                  ),
                  _StatisticsChartLegend(
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
    );
  }
}

class _StatisticsChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StatisticsChartLegend({
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
