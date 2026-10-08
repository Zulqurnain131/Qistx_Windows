import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:qistx_app/Models/customer_model.dart';
import 'package:qistx_app/Models/guarantermodel.dart';
import 'package:qistx_app/View/classesui/dashedcirclepainter.dart';
import 'package:qistx_app/View/products/customer_khata.dart';
import 'package:qistx_app/View/profilecreation/create_customer_guarantors.dart';
import 'package:qistx_app/View/profilecreation/view_customer.dart';
import 'package:qistx_app/View/users_screens/home_screen.dart';

class CreateCustomerProfile extends StatefulWidget {
  const CreateCustomerProfile({super.key});

  @override
  State<CreateCustomerProfile> createState() => _CreateCustomerProfileState();
}

class _CreateCustomerProfileState extends State<CreateCustomerProfile> {
  final ScrollController pageScrollController = ScrollController();
  bool frontCnicError = false;
  bool backCnicError = false;
  // Theme Colors
  final Color primaryOrange = const Color(0xFFFF6600);
  final Color greyBackground = const Color(0xFFE0E0E0);
  Uint8List? _selectedImageBytes; // Web Support
  File? _selectedImageFile;
  //// Map Variables

  final MapController mapController = MapController();
  final CustomerModel customer = CustomerModel();
  Uint8List? frontCnicBytes;
  final _formKey = GlobalKey<FormState>();

  Uint8List? backCnicBytes;
  final nameController = TextEditingController();

  final cnicController = TextEditingController();

  final whatsappController = TextEditingController();

  final emailController = TextEditingController();

  final addressController = TextEditingController();

  LatLng selectedLocation = const LatLng(0, 0);
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    // _saveCurrentScreen(); // Calling the function when screen loads
    _getCurrentLocation();
  }

  // Function to save the last screen
  // Future<void> _saveCurrentScreen() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString("last_screen", "create_customer_profile");
  //   } catch (e) {
  //     debugPrint("SharedPreferences Error: $e");
  //   }
  // }

  /// User se Current location fetch krny ka function
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        debugPrint("❌ Location Service Off");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enable location services"),
            backgroundColor: Colors.orange,
          ),
        );

        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          selectedLocation = const LatLng(33.6844, 73.0479);
          customer.latitude = 33.6844;
          customer.longitude = 73.0479;
        });

        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (!mounted) return;

        if (permission == LocationPermission.denied) {
          debugPrint("❌ Permission Denied");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permission denied"),
              backgroundColor: Colors.red,
            ),
          );

          if (!mounted) return;

          setState(() {
            isLoadingLocation = false;
            selectedLocation = const LatLng(33.6844, 73.0479);
            customer.latitude = 33.6844;
            customer.longitude = 73.0479;
          });

          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("❌ Permission Denied Forever");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission permanently denied"),
            backgroundColor: Colors.red,
          ),
        );

        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
          selectedLocation = const LatLng(33.6844, 73.0479);
          customer.latitude = 33.6844;
          customer.longitude = 73.0479;
        });

        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // VERY IMPORTANT
      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        selectedLocation = newLocation;

        customer.latitude = position.latitude;
        customer.longitude = position.longitude;

        isLoadingLocation = false;
      });

      // Move map after widget is confirmed mounted
      mapController.move(newLocation, 16);

      debugPrint(
        "✅ Current Location: "
        "${position.latitude}, ${position.longitude}",
      );
    } catch (e) {
      debugPrint("❌ Error getting location: $e");

      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;

        selectedLocation = const LatLng(33.6844, 73.0479);

        customer.latitude = 33.6844;
        customer.longitude = 73.0479;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error getting location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ////////// Fornt CNIC and Back CNIC  Functions
  Future<void> pickDocument(bool isFront) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;
    PlatformFile file = result.files.first;
    Uint8List? originalBytes;

    if (kIsWeb) {
      originalBytes = file.bytes;
    } else {
      if (file.path == null) return;
      originalBytes = await File(file.path!).readAsBytes();
    }

    if (originalBytes == null) return;

    final compressedBytes = await compressTo300KB(originalBytes);

    if (compressedBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image compression failed")));
      return;
    }

    setState(() {
      if (isFront) {
        frontCnicBytes = compressedBytes;
        customer.frontCnicBytes = compressedBytes;
        frontCnicError = false;
      } else {
        backCnicBytes = compressedBytes;
        customer.backCnicBytes = compressedBytes;
        backCnicError = false;
      }
    });
  }

  //// image compress function
  Future<Uint8List?> compressTo300KB(Uint8List bytes) async {
    // Already under 300KB
    if (bytes.lengthInBytes <= 300 * 1024) {
      return bytes;
    }

    img.Image? image = img.decodeImage(bytes);

    if (image == null) return null;

    if (image.width > 1280) {
      image = img.copyResize(image, width: 1280);
    }

    int quality = 90;
    Uint8List compressedBytes;

    do {
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      quality -= 5;
    } while (compressedBytes.lengthInBytes > 300 * 1024 && quality >= 10);

    return compressedBytes;
  }

  /// Customer profile image function
  Future<void> _pickImage() async {
    try {
      debugPrint(" Opening image picker...");

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        debugPrint(" No image selected");
        return;
      }

      PlatformFile file = result.files.first;
      Uint8List? originalBytes;
      if (kIsWeb) {
        originalBytes = file.bytes;
      } else {
        if (file.path == null) return;
        originalBytes = await File(file.path!).readAsBytes();
      }

      if (originalBytes == null) {
        return;
      }

      final compressedBytes = await compressTo300KB(originalBytes);

      if (compressedBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image compression failed")),
        );
        return;
      }

      debugPrint("Image selected: ${file.name}");
      debugPrint(" Path: ${file.path}");
      debugPrint("Size: ${file.size} bytes");
      debugPrint(" Size: ${(file.size / 1024).toStringAsFixed(2)} KB");
      debugPrint(" Size: ${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB");

      if (kIsWeb) {
        setState(() {
          _selectedImageBytes = compressedBytes;
          customer.profileBytes = compressedBytes;
          _selectedImageFile = null;
        });

        debugPrint(
          "Compressed Size: ${(compressedBytes.lengthInBytes / 1024).toStringAsFixed(2)} KB",
        );
      } else {
        if (file.path == null) {
          debugPrint("❌ File path is null");
          return;
        }

        final imageFile = File(file.path!);
        final imageBytes = imageFile.readAsBytesSync();

        setState(() {
          _selectedImageFile = imageFile;
          customer.profileBytes = compressedBytes;
          _selectedImageBytes = compressedBytes;
        });

        debugPrint(" File exists: ${imageFile.existsSync()}");
        debugPrint(" File length: ${imageFile.lengthSync()} bytes");
        debugPrint(
          "File length: ${(imageFile.lengthSync() / 1024).toStringAsFixed(2)} KB",
        );
        debugPrint(
          " File length: ${(imageFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB",
        );
        debugPrint(" Bytes loaded: ${imageBytes.length} bytes");
      }
    } catch (e, stack) {
      debugPrint("Image Pick Error: $e");
      debugPrint(stack.toString());
    }
  }

  //// Validate Documents //
  bool _validateDocuments() {
    setState(() {
      frontCnicError = frontCnicBytes == null;
      backCnicError = backCnicBytes == null;
    });

    return !(frontCnicError || backCnicError);
  }

  Future<void> _onNextPressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_validateDocuments()) {
      return;
    }

    // Debug location data
    debugPrint(
      "📍 Final Location - Lat: ${customer.latitude}, Lng: ${customer.longitude}",
    );

    try {
      customer.fullName = nameController.text;
      customer.cnicNo = cnicController.text;
      customer.whatsappNo = whatsappController.text;
      customer.email = emailController.text;
      customer.address = addressController.text;

      // Ensure location is set
      if (customer.latitude == 0 && customer.longitude == 0) {
        customer.latitude = selectedLocation.latitude;
        customer.longitude = selectedLocation.longitude;
      }

      final customerId = await customer.saveCustomer();
      print("✅ Created Customer ID: $customerId");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Customer Saved")));
      _showProfileCreatedDialog(customerId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showProfileCreatedDialog(final customerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Profile Created Successfully",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Would you like to open khata account for this customer now?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog only
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // close dialog
                // TODO: yahan apna Open Khata Account screen navigate karein
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerKhata(customerId: customerId),
                  ),
                );
              },
              child: const Text(
                "Open Khata",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isShortScreen = constraints.maxHeight < 620;

            return Stack(
              children: [
                // Bottom Right Decorative Wave (desktop only — hidden on mobile/tablet)
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

                // Top Left Brand Logo (QISTX Header Logo) - desktop only, hidden on mobile/tablet
                if (isDesktop && !isShortScreen && constraints.maxWidth > 350)
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
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                "QISTX",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),

                // Main Content
                Scrollbar(
                  controller: pageScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: pageScrollController,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1100,
                        ), // Limits width on wider screens
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20.0 : 40.0,
                            vertical: isDesktop
                                ? 100.0
                                : 60.0, // Adjusted for absolute logo
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Inline Logo for Very Short Devices (desktop only —
                              // mobile/tablet never shows the QistX icon)
                              if (isDesktop &&
                                  (isShortScreen ||
                                      constraints.maxWidth <= 350)) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 90,
                                    height: 45,
                                    child: Image.asset(
                                      "assets/Icons/Qist_Logo_trans.png",
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Desktop = existing two column layout (unchanged)
                              // Mobile/Tablet = single column, screenshot order
                              isDesktop
                                  ? _buildDesktopLayout()
                                  : _buildMobileLayout(),
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

  // ==================================================================
  // DESKTOP LAYOUT (unchanged behaviour, two columns side by side)
  // ==================================================================
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildDesktopLeftColumn()),
          const SizedBox(width: 40),
          Expanded(child: _buildDesktopRightColumn()),
        ],
      ),
    );
  }

  Widget _buildDesktopLeftColumn() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleBlock(),
              const SizedBox(height: 40),
              _buildSectionHeader("Identity Documents"),
              const SizedBox(height: 16),
              _buildDocumentUploadRow(Icons.badge_outlined, "Front CNIC", true),
              const SizedBox(height: 16),
              _buildDocumentUploadRow(
                Icons.credit_card_outlined,
                "Back CNIC",
                false,
              ),
              const SizedBox(height: 40),
              _buildSectionHeader("Guarantors (optional)"),
              const SizedBox(height: 20),
              _buildGuarantorsList(width: 300),
              const SizedBox(height: 10),
              _buildAddGuarantorButton(width: 300),
              const SizedBox(height: 20),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            width: 300,
            label: "Next",
            icon: Icons.chevron_right,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRightColumn() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Personal Information"),
            const SizedBox(height: 20),
            _buildPhotoPicker(),
            const SizedBox(height: 30),
            _buildTextFields(),
            const SizedBox(height: 10),
            _buildOptionalLabel(),
            const SizedBox(height: 10),
            _buildMapWidget(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================================================================
  // MOBILE / TABLET LAYOUT (matches the provided screenshot order)
  // Title -> Personal Info (photo + fields) -> Map -> Identity Docs ->
  // Guarantors -> Create button. Everything scrolls together.
  // ==================================================================
  Widget _buildMobileLayout() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleBlock(),
          const SizedBox(height: 24),
          _buildSectionHeader("Personal Information"),
          const SizedBox(height: 20),
          _buildPhotoPicker(),
          const SizedBox(height: 24),
          _buildTextFields(),
          const SizedBox(height: 10),
          _buildOptionalLabel(),
          const SizedBox(height: 10),
          // Show loading indicator while getting location
          isLoadingLocation
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Getting your location..."),
                      ],
                    ),
                  ),
                )
              : _buildMapWidget(),
          const SizedBox(height: 32),
          _buildSectionHeader("Identity Documents"),
          const SizedBox(height: 16),
          _buildDocumentUploadRow(Icons.badge_outlined, "Front CNIC", true),
          const SizedBox(height: 16),
          _buildDocumentUploadRow(
            Icons.credit_card_outlined,
            "Back CNIC",
            false,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("Guarantors (optional)"),
          const SizedBox(height: 20),
          _buildGuarantorsList(width: double.infinity),
          const SizedBox(height: 10),
          _buildAddGuarantorButton(width: double.infinity),
          const SizedBox(height: 28),
          _buildActionButton(
            width: double.infinity,
            label: "Create",
            icon: Icons.chevron_right,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================================================================
  // SHARED PIECES (used by both desktop and mobile layouts)
  // ==================================================================

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Create Customer\nProfile",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Complete the information below to set up a\nnew customer account and verify their\nidentity.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildOptionalLabel() {
    return const Text(
      "Optional",
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: SizedBox(
            width: 85,
            height: 85,
            child: Stack(
              children: [
                // Outer Orange Dashed Circle
                CustomPaint(
                  size: const Size(85, 85),
                  painter: DashedCirclePainter(),
                ),
                // Avatar Image / Shop Icon Placeholder
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFECECEC),
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : (_selectedImageFile != null
                              ? FileImage(_selectedImageFile!) as ImageProvider
                              : null),
                    child:
                        (_selectedImageFile == null &&
                            _selectedImageBytes == null)
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF616161),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          height: 45,
          width: 160,
          child: ElevatedButton(
            onPressed: () async {
              await _pickImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Choose Photo",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          "Name",
          Icons.person_outline,
          controller: nameController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "CNIC No.",
          Icons.badge_outlined,
          controller: cnicController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "WhatsApp No.",
          Icons.chat_bubble_outline,
          controller: whatsappController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Email",
          Icons.email_outlined,
          controller: emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "Address",
          Icons.location_on_outlined,
          controller: addressController,
        ),
      ],
    );
  }

  Widget _buildMapWidget() {
    return Container(
      width: double.infinity,
      height: 220, // Increased height for better visibility
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryOrange, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: selectedLocation,
            initialZoom: 16,
            onTap: (tapPosition, point) {
              setState(() {
                selectedLocation = point;
                customer.latitude = point.latitude;
                customer.longitude = point.longitude;
              });
              debugPrint(
                "📍 Map tapped: ${point.latitude}, ${point.longitude}",
              );
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.qistx.app",
            ),
            DragMarkers(
              markers: [
                DragMarker(
                  point: selectedLocation,
                  size: const Size(45, 45),
                  builder: (context, position, isDragging) {
                    return const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                      size: 45,
                    );
                  },
                  onDragEnd: (details, point) {
                    setState(() {
                      selectedLocation = point;
                      customer.latitude = point.latitude;
                      customer.longitude = point.longitude;
                    });
                    debugPrint(
                      "📍 Dragged to: ${selectedLocation.latitude}, ${selectedLocation.longitude}",
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantorsList({required double width}) {
    return SizedBox(
      width: width,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customer.guarantors.length,
        itemBuilder: (context, index) {
          final guarantor = customer.guarantors[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 75,
                    height: 75,
                    color: Colors.grey.shade200,
                    child: guarantor.profileBytes != null
                        ? Image.memory(
                            guarantor.profileBytes!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guarantor.fullName ?? "",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guarantor.cnicNo ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guarantor.whatsappNo ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddGuarantorButton({required double width}) {
    return SizedBox(
      width: width,
      height: 48,
      child: OutlinedButton(
        onPressed: () async {
          if (customer.guarantors.length >= 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Maximum 2 guarantors allowed")),
            );
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateCustomerGuarantors()),
          );

          if (result is GuarantorModel) {
            setState(() {
              customer.guarantors.add(result);
            });
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryOrange, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "Add",
          style: TextStyle(
            color: primaryOrange,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required double width,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: width,
      height: 50,
      child: ElevatedButton(
        onPressed: _onNextPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(icon, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // Helper method for Document Upload Buttons (Front/Back CNIC)
  Widget _buildDocumentUploadRow(
    IconData icon,
    String buttonText,
    bool isFront,
  ) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFront
                  ? (frontCnicError ? Colors.red : Colors.grey.shade300)
                  : (backCnicError ? Colors.red : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: isFront
                ? (frontCnicBytes != null ? MemoryImage(frontCnicBytes!) : null)
                : (backCnicBytes != null ? MemoryImage(backCnicBytes!) : null),
            child: (isFront ? frontCnicBytes == null : backCnicBytes == null)
                ? Icon(icon, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 200,
          height: 45,
          child: OutlinedButton(
            onPressed: () {
              pickDocument(isFront);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryOrange, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for TextFields
  Widget _buildTextField(
    String hint,
    IconData icon, {
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        value = value?.trim() ?? "";

        // Required
        if (value.isEmpty) {
          return "$hint is required";
        }

        // Name
        if (hint == "Name") {
          if (value.length < 3) {
            return "Name must be at least 3 characters";
          }
          if (!RegExp(r"^[a-zA-Z.' ]+$").hasMatch(value)) {
            return "Enter a valid name";
          }
        }

        // CNIC
        if (hint == "CNIC No.") {
          if (!RegExp(r'^\d{5}-\d{7}-\d{1}$').hasMatch(value)) {
            return "Format: 12345-1234567-1";
          }
        }

        // WhatsApp
        if (hint == "WhatsApp No.") {
          if (!RegExp(r'^03\d{9}$').hasMatch(value)) {
            return "Enter valid Pakistani number";
          }
        }

        // Email
        if (hint == "Email") {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return "Enter valid email";
          }
        }

        // Address
        if (hint == "Address") {
          if (value.length < 10) {
            return "Address is too short";
          }
        }

        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryOrange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
