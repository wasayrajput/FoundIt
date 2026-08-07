import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foundit/core/constants/app_colors.dart';
import 'package:foundit/core/state/app_state.dart';
import 'package:foundit/features/home/domain/post_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _locController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late String _selectedStatus;

  String? _selectedCategory;
  Uint8List? _selectedImageBytes;
  double? _latitude;
  double? _longitude;

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

  String _getDefaultCategory() {
    final name = widget.post.itemName.toLowerCase();
    if (name.contains('iphone') || name.contains('phone')) {
      return "Mobiles";
    } else if (name.contains('macbook') || name.contains('headphones')) {
      return "Electronics";
    } else if (name.contains('wallet')) {
      return "Men wallets";
    } else if (name.contains('card')) {
      return "ID card";
    }
    return "Others";
  }

  @override
  void initState() {
    super.initState();
    
    // Resolve original details
    final metadata = AppState.instance.getPostMetadata(widget.post.id);
    final post = AppState.instance.getPost(widget.post);
    _selectedImageBytes = post.imageBytes;
    _latitude = post.latitude;
    _longitude = post.longitude;

    final originalDesc = metadata != null ? metadata['description']! : _getDefaultDescription();
    final originalEmail = metadata != null ? metadata['email']! : _getDefaultEmail();
    final originalPhone = metadata != null ? metadata['phone']! : _getDefaultPhone();
    final originalCity = metadata != null ? metadata['city']! : _getDefaultCity();

    _nameController = TextEditingController(text: post.itemName);
    _descController = TextEditingController(text: originalDesc);
    _locController = TextEditingController(text: post.location);
    _cityController = TextEditingController(text: originalCity);
    _phoneController = TextEditingController(text: originalPhone);
    _emailController = TextEditingController(text: originalEmail);
    _selectedStatus = post.isLost ? 'Lost' : 'Found';

    final originalCategory = metadata != null && metadata['category'] != null && metadata['category']!.isNotEmpty
        ? metadata['category']!
        : _getDefaultCategory();
    _selectedCategory = _categories.contains(originalCategory) ? originalCategory : 'Others';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_latitude == null || _longitude == null) {
        _autoDetectLocation();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isDetectingLocation = false;

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

  String _getDefaultDescription() {
    switch (widget.post.id) {
      case 'u1': return "Lost a set of three silver house keys on a blue carabiner near the Main Library entrance. Important keys, please contact if found.";
      case 'u2': return "Found a brown leather wallet in the University Cafeteria. It was on one of the corner tables. Let me know the name on the ID card inside to claim.";
      case 'u3': return "Lost my black Sony noise-canceling headphones in Lecture Hall B on the back row. Please return if you picked them up.";
      case 'u4': return "Found a student ID card belonging to Jane Doe near the Admin Office. Ready to return.";
      default: return "";
    }
  }

  String _getDefaultEmail() {
    final posterDetails = AppState.instance.getPosterDetails(widget.post.id);
    if (posterDetails != null && (posterDetails['email'] ?? '').isNotEmpty) {
      return posterDetails['email']!;
    }
    return AppState.instance.userEmail;
  }

  String _getDefaultPhone() {
    final posterDetails = AppState.instance.getPosterDetails(widget.post.id);
    if (posterDetails != null && (posterDetails['phone'] ?? '').isNotEmpty) {
      return posterDetails['phone']!;
    }
    return AppState.instance.userPhone;
  }

  String _getDefaultCity() {
    final loc = widget.post.location;
    if (loc.contains(',')) {
      return loc.split(',').last.trim();
    }
    return loc;
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
            width: 120,
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
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.textPrimary),
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

  void _onSaveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedPost = PostModel(
        id: widget.post.id,
        itemName: _nameController.text.trim(),
        isLost: _selectedStatus == 'Lost',
        date: widget.post.date,
        location: _locController.text.trim(),
        imageUrl: widget.post.imageUrl,
        imageBytes: _selectedImageBytes,
        latitude: _latitude,
        longitude: _longitude,
      );

      AppState.instance.updatePost(
        updatedPost,
        description: _descController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        category: _selectedCategory,
      );

      Navigator.pop(context, true); // Return true to indicate post was updated
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // --- Premium Header Area (Thin version) ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryBlueMid, AppColors.primaryBlue],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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

            // --- Form Content ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                children: [
                  Center(
                    child: Text(
                      'Edit Post',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Edit Picture Area
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _selectedImageBytes = bytes;
                        });
                      }
                    },
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
                            : (widget.post.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.post.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: (_selectedImageBytes != null || widget.post.imageUrl != null)
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

                  // Fields
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
                  _buildPremiumTextField(
                    label: 'City where you found / lost the item',
                    controller: _cityController,
                  ),
                  const SizedBox(height: 32),

                  // Contact Info Title
                  Text(
                    'Your Contact Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone and Email (Row layout)
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

                  // Save Changes Button
                  ElevatedButton(
                    onPressed: _onSaveChanges,
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
                      'Save Changes',
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
    );
  }
}
