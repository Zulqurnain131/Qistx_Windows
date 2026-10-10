import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qistx_app/Models/view_customer_model.dart';
import 'package:qistx_app/Providers/CustomerProvider%20.dart';
import 'package:qistx_app/View/profilecreation/create_customer_profile.dart';
import 'package:qistx_app/View/profilecreation/customerprofile.dart';

class ViewCustomer extends StatefulWidget {
  final String? accountid;
  const ViewCustomer({super.key, this.accountid});

  @override
  State<ViewCustomer> createState() => _ViewCustomerState();
}

class _ViewCustomerState extends State<ViewCustomer> {
  static const Color kPrimary = Color(0xFFFF5500);
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      context.read<Customerprovider>().fetchCustomers();
    });

    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.trim().toLowerCase();
    });
  }

  void _openCustomerProfile(ViewCustomerModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Customerprofile(customer: customer),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteCustomer(ViewCustomerModel customer) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Customer"),
        content: Text(
          'Are you sure you want to delete "${customer.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 163, 29, 20),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Delete function Provider mein add karna hai
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,

      // Floating "+" button only on mobile — desktop keeps the header button.
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              backgroundColor: kPrimary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateCustomerProfile(),
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
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
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48.0 : 20.0,
                    vertical: isDesktop ? 16.0 : 30.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (isDesktop && constraints.maxWidth > 350)
                      //   Align(
                      //     alignment: Alignment.topLeft,
                      //     child: RepaintBoundary(
                      //       child: SizedBox(
                      //         width: 90,
                      //         height: 90,
                      //         child: Image.asset(
                      //           "assets/Icons/Qist_Logo_trans.png",
                      //           fit: BoxFit.contain,
                      //         ),
                      //       ),
                      //     ),
                      //   ),

                      // Title & Action Bar — desktop keeps the button beside the title,
                      // mobile only shows the title (the "+" moved to a FAB).
                      isDesktop
                          ? Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Customers",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  _buildAddCustomerButton(),
                                ],
                              ),
                            )
                          : const Text(
                              "Customers",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                      // const SizedBox(height: 24),
                      SizedBox(height: isDesktop ? 14 : 24),

                      // Search Bar
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Search using name and CNIC...",
                            hintStyle: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black54,
                              size: 22,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isDesktop ? 12 : 16),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _searchQuery,
                          builder: (context, searchQuery, child) {
                            return Consumer<Customerprovider>(
                              builder: (context, provider, child) {
                                final List<ViewCustomerModel>
                                filteredCustomers = provider.customers.where((
                                  c,
                                ) {
                                  return searchQuery.isEmpty ||
                                      c.fullName.toLowerCase().contains(
                                        searchQuery,
                                      ) ||
                                      c.cnicNo.toLowerCase().contains(
                                        searchQuery,
                                      );
                                }).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Showing ${filteredCustomers.length} customers",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    SizedBox(height: isDesktop ? 12 : 16),

                                    Expanded(
                                      child: isDesktop
                                          ? Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: _buildCustomerList(
                                                filteredCustomers,
                                                isDesktop,
                                                provider.isLoading,
                                              ),
                                            )
                                          : _buildCustomerList(
                                              filteredCustomers,
                                              isDesktop,
                                              provider.isLoading,
                                            ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomerList(
    List<ViewCustomerModel> filteredCustomers,
    bool isDesktop,
    bool isLoading,
  ) {
    return Column(
      children: [
        if (isDesktop) _buildTableHeader(),

        Expanded(
          child: isLoading && filteredCustomers.isEmpty
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : filteredCustomers.isEmpty
              ? const Center(
                  child: Text(
                    "No customers found",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCustomers.length,

                  separatorBuilder: (context, index) {
                    if (isDesktop) {
                      return const SizedBox(height: 12);
                    }

                    return Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade300,
                    );
                  },

                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];

                    // Desktop
                    if (isDesktop) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kPrimary.withOpacity(0.5),
                            width: 1.1,
                          ),
                        ),
                        child: _buildDesktopRow(customer),
                      );
                    }

                    // Mobile — NO CARD / NO BORDER
                    // Mobile — orange bordered list item
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withOpacity(0.75),
                          width: 1,
                        ),
                      ),
                      child: _buildMobileCard(customer),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black54,
      fontSize: 13,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Name ↕", style: style)),
          Expanded(flex: 3, child: Text("CNIC ↕", style: style)),
          Expanded(flex: 3, child: Text("Phone No ↕", style: style)),
          Expanded(flex: 3, child: Text("Status ↕", style: style)),
          Expanded(flex: 2, child: Text("Credit Limit ↕", style: style)),
          Expanded(flex: 2, child: Text("Account Status ↕", style: style)),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAddCustomerButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateCustomerProfile()),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Add New Customer",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _avatar(ViewCustomerModel c) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: c.profileImageUrl != null && c.profileImageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                c.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            )
          : const Icon(Icons.person_outline, size: 22, color: Colors.grey),
    );
  }

  Widget _buildDesktopRow(ViewCustomerModel c) {
    return InkWell(
      onTap: () => _openCustomerProfile(c),
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _avatar(c),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              c.cnicNo,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              c.whatsappNo,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(c),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              c.maxCreditLimit != null
                  ? 'PKR ${c.maxCreditLimit!.toStringAsFixed(0)}'
                  : '-',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _accountStatusBadge(c.isBlocked ? 'Blocked' : 'Active'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: "Delete Customer",
            onPressed: () => _confirmDeleteCustomer(c),
          ),
        ],
      ),
    );
  }

  /// Matches the mobile screenshot: avatar, name + CNIC, and the balance
  /// pill on the right. Long-press still opens the delete dialog.
  Widget _buildMobileCard(ViewCustomerModel c) {
    return InkWell(
      onTap: () => _openCustomerProfile(c),
      onLongPress: () => _confirmDeleteCustomer(c),
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          _avatar(c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "CNIC: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: c.cnicNo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _statusBadge(c),
        ],
      ),
    );
  }

  Widget _statusBadge(ViewCustomerModel c) {
    return Container(
      width: 110,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            c.currentBalance == null
                ? 'No Khata'
                : c.currentBalance == 0
                ? 'PKR 0'
                : 'PKR ${c.currentBalance!.abs().toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            c.currentBalance == null
                ? 'Amount'
                : c.currentBalance == 0
                ? 'Amount Clear'
                : c.currentBalance! > 0
                ? 'Extra Payment'
                : 'Udhaar Amount',
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _accountStatusBadge(String status) {
    final bool isBlocked = status.toLowerCase() == 'blocked';
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
