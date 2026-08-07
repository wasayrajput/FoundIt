import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/services/api_service.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:foundit/features/profile/presentation/widgets/webcam_helper.dart'
    if (dart.library.html) 'package:foundit/features/profile/presentation/widgets/webcam_helper_web.dart';
import 'package:foundit/features/profile/presentation/profile_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;
  bool _isBottomNavVisible = true;
  String _selectedStatus = 'Found'; // 'Found' or 'Lost'
  Uint8List? _selectedImageBytes;

  String? _selectedCategory;
  final List<String> _categories = [
    'Mobiles',
    'Men wallets',
    'Women purse',
    'Suitcase or bag',
    'Electronics',
    'ID card',
    'Documents',
    'Cash',
    'Gold',
    'Gold and non-gold jewelry',
    'Others',
  ];

  IconData _getCategoryIconByName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'mobiles':
        return Icons.phone_iphone_rounded;
      case 'men wallets':
        return Icons.account_balance_wallet_rounded;
      case 'women purse':
        return Icons.shopping_bag_rounded;
      case 'suitcase or bag':
        return Icons.business_center_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'id card':
        return Icons.badge_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'gold':
        return Icons.monetization_on_rounded;
      case 'gold and non-gold jewelry':
        return Icons.diamond_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _locController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _locController = TextEditingController(text: 'Detecting exact location...');
    _cityController = TextEditingController();
    _phoneController = TextEditingController(text: AppState.instance.userPhone);
    _emailController = TextEditingController(text: AppState.instance.userEmail);
    
    // Hide bottom nav on scroll
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  bool _isDetectingLocation = false;
  double? _latitude;
  double? _longitude;

  Future<void> _autoDetectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them in settings.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied. Please allow access to auto-fill location.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FounditApp/1.0 (contact: support@foundit.com)',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        
        String city = '';
        if (address != null) {
          city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? address['county'] ?? address['state'] ?? '';
        }

        String displayName = data['display_name'] ?? '';
        String specificLoc = '';
        if (displayName.isNotEmpty) {
          final parts = displayName.split(',');
          if (parts.length > 1) {
            specificLoc = "${parts[0].trim()}, ${parts[1].trim()}";
          } else {
            specificLoc = displayName.trim();
          }
        }

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (city.isNotEmpty) {
            _cityController.text = city;
          }
          if (specificLoc.isNotEmpty) {
            _locController.text = specificLoc;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location auto-filled: $specificLoc, $city'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1B9B5A),
            ),
          );
        }
      } else {
        throw 'Failed to geocode location coordinates.';
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('timeout')) {
        errorMsg = 'Location lookup timed out. Please try again.';
      }
      if (mounted) {
        _showSimulatedLocationDialog(errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  void _showSimulatedLocationDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              'Location Access Failed',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          '$errorMsg\n\nWould you like to simulate auto-filling a campus location for testing purposes?',
          style: GoogleFonts.inter(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _latitude = 40.785091;
                _longitude = -73.968285;
                _cityController.text = "New York";
                _locController.text = "Central Park Zoo";
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulated location auto-filled!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF1B9B5A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Simulate Location',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool isRow = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final translatedLabel = AppState.instance.translate(label);
    final textField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.inter(fontSize: 15, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
      validator: validator ?? (v) {
        if (v == null || v.trim().isEmpty) {
          return '$translatedLabel ${AppState.instance.translate("cannot be empty")}';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: isRow ? '' : translatedLabel,
        hintStyle: GoogleFonts.inter(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.5)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );

    if (isRow) {
      return Row(
        children: [
          SizedBox(
            width: 120, // Enough width for "Phone Number"
            child: Text(
              translatedLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
          Expanded(child: textField),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translatedLabel,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        textField,
      ],
    );
  }

  Widget _buildStatusOption(String status) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = status),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.08) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.primaryBlue.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primaryBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat,
              child: Row(
                children: [
                  Icon(_getCategoryIconByName(cat), color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    cat,
                    style: GoogleFonts.inter(fontSize: 15, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                  ),
                ],
              ),
            );
          }).toList(),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
            });
          },
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryBlue, size: 28),
          decoration: InputDecoration(
            hintText: 'Choose Category',
            hintStyle: GoogleFonts.inter(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.5)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onPublishPost() async {
    if (_formKey.currentState!.validate()) {
      List<String> uploadedImages = [];

      // Step 1: Upload image to Node.js backend if image selected
      if (_selectedImageBytes != null) {
        final uploadRes = await ApiService.uploadImageBytes(
          bytes: _selectedImageBytes!,
          filename: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (uploadRes['success'] == true && uploadRes['filePath'] != null) {
          uploadedImages.add(uploadRes['filePath']);
        } else {
          // Fallback to base64 if server upload endpoint fails
          final base64Img = 'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
          uploadedImages.add(base64Img);
        }
      }

      // Step 2: Create post in MongoDB backend via REST API
      final apiRes = await ApiService.createPost(
        itemName: _nameController.text.trim(),
        isLost: _selectedStatus == 'Lost',
        category: _selectedCategory ?? 'Other',
        description: _descController.text.trim(),
        date: _getFormattedTodayDate(),
        locationName: _locController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        images: uploadedImages,
      );

      if (apiRes['success'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiRes['message'] ?? 'Failed to submit post. Please try logging in again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final newPostId = apiRes['post'] != null ? apiRes['post']['_id'] ?? apiRes['post']['id'] : 'u_${DateTime.now().millisecondsSinceEpoch}';
      
      final post = PostModel(
        id: newPostId.toString(),
        itemName: _nameController.text.trim(),
        isLost: _selectedStatus == 'Lost',
        date: _getFormattedTodayDate(),
        location: _locController.text.trim(),
        imageUrl: uploadedImages.isNotEmpty ? uploadedImages.first : null,
        imageBytes: _selectedImageBytes,
        latitude: _latitude,
        longitude: _longitude,
        status: PostStatus.pending,
      );

      AppState.instance.addMyPost(post);
      
      AppState.instance.updatePost(
        post,
        description: _descController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        category: _selectedCategory,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post submitted for Admin review! Awaiting Admin approval before appearing on feed.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true); // Return true to trigger feed updates
    }
  }

  String _getFormattedTodayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  Future<Uint8List?> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        final String? webcamPath = await captureWebcamPhoto(context);
        if (webcamPath != null) {
          final base64Str = webcamPath.split(',').last;
          return base64Decode(base64Str);
        }
        return null;
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (photo != null) {
          return await photo.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  void _showPhotoSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Picture',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an option to upload product picture',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryBluePale,
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final bytes = await _pickImage(ImageSource.camera);
                  if (bytes != null) {
                    setState(() {
                      _selectedImageBytes = bytes;
                    });
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryBluePale,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final bytes = await _pickImage(ImageSource.gallery);
                  if (bytes != null) {
                    setState(() {
                      _selectedImageBytes = bytes;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // --- Premium Header Area (Thin version) ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Foundit',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),
              ),
            ),

            // --- Main Form Content ---
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                children: [
                  // Title
                  Center(
                    child: Text(
                      'Create Post',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload Picture Area
                  GestureDetector(
                    onTap: _showPhotoSourceOptions,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          width: 2,
                        ),
                        image: _selectedImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_selectedImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImageBytes != null
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Text(
                                  'Change Picture',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).cardColor,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 48,
                                  color: AppColors.primaryBlue.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Upload Picture',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Product Name & Description
                  _buildPremiumTextField(
                    label: 'Product Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 20),
                  _buildPremiumTextField(
                    label: 'Product Description',
                    controller: _descController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  _buildCategoryDropdown(),
                  const SizedBox(height: 24),

                  // Status Radio
                  Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusOption('Found'),
                      const SizedBox(width: 16),
                      _buildStatusOption('Lost'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Specific Location Field
                  // Specific Location Field (Auto-detected & Read-only)
                  _buildPremiumTextField(
                    label: 'Your Home City (Auto-detected)',
                    controller: _locController,
                    readOnly: true,
                    suffixIcon: _isDetectingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _isDetectingLocation ? null : _autoDetectLocation,
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // City Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'City where you found / lost the item',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cityController,
                        style: GoogleFonts.inter(fontSize: 15, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'City cannot be empty';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'e.g. New York, Karachi, London...',
                          hintStyle: GoogleFonts.inter(
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textSecondary).withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.1), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Contact Information
                  Text(
                    'Your Contact Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone and Email
                  _buildPremiumTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    isRow: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    isRow: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email cannot be empty';
                      }
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _onPublishPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'Publish Post',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- Floating Bottom Navigation Bar (Animated) ---
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 2),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryBlueMid,
                  AppColors.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_rounded, color: Colors.white60, size: 26),
                    onPressed: () => Navigator.pop(context), // Go back home
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_rounded, color: Colors.white60, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(showBottomNav: true),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
