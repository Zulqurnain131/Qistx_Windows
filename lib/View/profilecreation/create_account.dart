import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qistx_app/View/classesui/dashedcirclepainter.dart';
import 'package:qistx_app/View/profilecreation/create_shop_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  File? _selectedImageFile; // Mobile / Desktop Native
  Uint8List? _selectedImageBytes; // Web Support
  String? _uploadedImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _saveCurrentScreen();
  }

  Future<void> _saveCurrentScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("last_screen", "complete_account");
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Pick Profile Image
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null) return;

      PlatformFile file = result.files.first;

      if (kIsWeb) {
        setState(() {
          _selectedImageBytes = file.bytes;
          _selectedImageFile = null;
        });
      } else {
        if (file.path == null) return;

        setState(() {
          _selectedImageFile = File(file.path!);
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      debugPrint("Image Pick Error: $e");
    }
  }

  //// Compressed function
  Future<Uint8List?> compressTo300KB(Uint8List bytes) async {
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

  /// Upload Image to Supabase Storage
  Future<String?> _uploadImageToSupabase(String userId) async {
    if (_selectedImageFile == null && _selectedImageBytes == null) return null;

    Uint8List? originalBytes;

    if (kIsWeb) {
      originalBytes = _selectedImageBytes;
    } else {
      originalBytes = await _selectedImageFile!.readAsBytes();
    }

    if (originalBytes == null) return null;

    Uint8List? imageBytes = await compressTo300KB(originalBytes);

    if (imageBytes == null) {
      throw Exception("Image compression failed.");
    }

    if (imageBytes.lengthInBytes > 300 * 1024) {
      throw Exception("Image size must not exceed 300 KB.");
    }

    try {
      const String fileExt = "jpg";
      final fileName = const Uuid().v4();
      final filePath = '$userId/profile_$fileName.$fileExt';

      await _supabase.storage
          .from('account-assets')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: "image/jpeg",
              upsert: true,
            ),
          );
      final String publicUrl = _supabase.storage
          .from('account-assets')
          .getPublicUrl(filePath);
      debugPrint("File Path: $filePath");
      debugPrint("Public URL: $publicUrl");

      return publicUrl;
    } catch (e) {
      debugPrint("Image Upload Error: $e");
      return null;
    }
  }

  /// Save Account Data & Continue
  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      _uploadedImageUrl = await _uploadImageToSupabase(user.id);
      debugPrint("Uploaded URL: $_uploadedImageUrl");
      await _supabase.auth.updateUser(
        UserAttributes(data: {"full_name": _fullNameController.text.trim()}),
      );
      await _supabase
          .from("app_users")
          .update({
            "username": _usernameController.text.trim(),
            "profile_image": _uploadedImageUrl,
            "updated_at": DateTime.now().toIso8601String(),
          })
          .eq("id", user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreateShopProfile()),
      );
    } catch (e) {
      debugPrint("Save Profile Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update profile: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final bool isDesktop = screenWidth > 800;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Bottom Right Wave Asset (Only for Desktop)
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

                // Top Left Brand Logo (Only for Desktop)
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

                // Main Content Form
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20.0 : 48.0,
                        vertical: 40.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 900 : 400,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isDesktop
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildHeaderSection(isDesktop),
                                        ),
                                        const SizedBox(width: 50),
                                        Expanded(
                                          child:
                                              _buildDesktopFormFieldsSection(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildHeaderSection(isDesktop),
                                        const SizedBox(height: 28),
                                        _buildMobileFormFieldsSection(),
                                      ],
                                    ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Setup Your Account",
          style: TextStyle(
            fontSize: isDesktop ? 34 : 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Add your photo, full name, and username to personalize your account.",
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Separate Function for Desktop Form Fields Section
  Widget _buildDesktopFormFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: 85,
                height: 85,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(85, 85),
                      painter: DashedCirclePainter(),
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFEBEBEB),
                        backgroundImage: _selectedImageBytes != null
                            ? MemoryImage(_selectedImageBytes!)
                            : (_selectedImageFile != null
                                  ? FileImage(_selectedImageFile!)
                                        as ImageProvider
                                  : null),
                        child:
                            (_selectedImageFile == null &&
                                _selectedImageBytes == null)
                            ? const Icon(
                                Icons.person,
                                size: 42,
                                color: Color(0xFF9E9E9E),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Profile Photo",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Upload a profile photo to personalize your account.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    width: 145,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      label: const Text(
                        "Upload Photo",
                        style: TextStyle(
                          color: Color(0xFFFF5500),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: const BorderSide(
                          color: Color(0xFFFF5500),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildTextField(
          controller: _fullNameController,
          hintText: "Full Name",
          icon: Icons.person_outline,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Please enter your full name";
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _usernameController,
          hintText: "Username",
          icon: Icons.account_circle_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Please enter a username";
            }
            return null;
          },
        ),
        const SizedBox(height: 28),
        _buildActionButton(),
      ],
    );
  }

  /// Separate Function for Mobile View Form Fields Section (Matches Image Layout)
  Widget _buildMobileFormFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Center Avatar
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: DashedCirclePainter(),
                  ),
                  Center(
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFFEBEBEB),
                      backgroundImage: _selectedImageBytes != null
                          ? MemoryImage(_selectedImageBytes!)
                          : (_selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                      as ImageProvider
                                : null),
                      child:
                          (_selectedImageFile == null &&
                              _selectedImageBytes == null)
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF9E9E9E),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Upload Profile Image Button (Centered & Outlined)
        Center(
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: const BorderSide(color: Color(0xFFFF5500), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Upload Profile Image",
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Full Name Input Field
        _buildTextField(
          controller: _fullNameController,
          hintText: "Full Name",
          icon: Icons.person_outline,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Please enter your full name";
            }
            return null;
          },
        ),

        const SizedBox(height: 14),

        // Username Input Field
        _buildTextField(
          controller: _usernameController,
          hintText: "Username",
          icon: Icons.account_circle_outlined,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Please enter a username";
            }
            return null;
          },
        ),

        const SizedBox(height: 28),

        // Save & Continue Button
        _buildActionButton(),
      ],
    );
  }

  /// Reusable Action Button
  Widget _buildActionButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAndContinue,
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
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Flexible(
                    child: Text(
                      "Save & Continue",
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

  /// Custom TextFormField Helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
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
