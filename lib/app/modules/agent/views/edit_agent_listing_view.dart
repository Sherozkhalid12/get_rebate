import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/agent/controllers/agent_controller.dart';
import 'package:getrebate/app/models/agent_listing_model.dart';
import 'package:getrebate/app/utils/image_url_helper.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/utils/snackbar_helper.dart';

/// Full-screen Edit Listing view with professional design and status dropdown.
class EditAgentListingView extends StatefulWidget {
  final AgentListingModel listing;

  const EditAgentListingView({super.key, required this.listing});

  @override
  State<EditAgentListingView> createState() => _EditAgentListingViewState();
}

class _EditAgentListingViewState extends State<EditAgentListingView> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _bacPercentController;

  final _currentImages = <String>[].obs;
  final _newImages = <File>[].obs;
  final _isListingAgent = true.obs;
  final _dualAgencyAllowed = false.obs;
  final _selectedStatus = MarketStatus.forSale.obs;
  final _isLoading = false.obs;
  final _imagePicker = ImagePicker();

  AgentController get _controller => Get.find<AgentController>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(text: widget.listing.description);
    _priceController = TextEditingController(
      text: (widget.listing.priceCents / 100).toStringAsFixed(0),
    );
    _addressController = TextEditingController(text: widget.listing.address);
    _cityController = TextEditingController(text: widget.listing.city);
    _stateController = TextEditingController(text: widget.listing.state);
    _zipCodeController = TextEditingController(text: widget.listing.zipCode);
    _bacPercentController = TextEditingController(
      text: widget.listing.bacPercent.toString(),
    );

    _currentImages.addAll(widget.listing.photoUrls);
    _isListingAgent.value = widget.listing.isListingAgent;
    _dualAgencyAllowed.value = widget.listing.dualAgencyAllowed;
    _selectedStatus.value = widget.listing.marketStatus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _bacPercentController.dispose();
    super.dispose();
  }

  String _marketStatusToApiString(MarketStatus s) {
    switch (s) {
      case MarketStatus.forSale:
        return 'forSale';
      case MarketStatus.pending:
        return 'pending';
      case MarketStatus.sold:
        return 'sold';
    }
  }

  Future<void> _saveListing() async {
    if (_titleController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a property title');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a description');
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a price');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a street address');
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a city');
      return;
    }
    if (_stateController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a state');
      return;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      SnackbarHelper.showError('Please enter a ZIP code');
      return;
    }

    _isLoading.value = true;
    try {
      await _controller.updateListingViaAPI(
        widget.listing.id,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _priceController.text.trim(),
        _addressController.text.trim(),
        _cityController.text.trim(),
        _stateController.text.trim(),
        _zipCodeController.text.trim(),
        _bacPercentController.text.trim(),
        _isListingAgent.value,
        _dualAgencyAllowed.value,
        marketStatus: _selectedStatus.value,
        remainingImageUrls: _currentImages.toList(),
        newImageFiles: _newImages.toList(),
      );
      Get.back();
      SnackbarHelper.showSuccess('Listing updated successfully');
    } catch (e) {
      SnackbarHelper.showError('Failed to update listing: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.darkGray, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Listing',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            color: AppTheme.lightGray.withOpacity(0.5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              icon: Icons.info_outline_rounded,
              title: 'Basic Information',
              children: [
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Property Title',
                  hintText: 'e.g., Beautiful 3BR Condo',
                  prefixIcon: Icons.title_rounded,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Describe your property...',
                  maxLines: 4,
                  prefixIcon: Icons.description_rounded,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSection(
              context,
              icon: Icons.swap_horiz_rounded,
              title: 'Listing Status',
              children: [
                Obx(
                  () => _buildStatusDropdown(context),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSection(
              context,
              icon: Icons.attach_money_rounded,
              title: 'Pricing',
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _priceController,
                        labelText: 'Price',
                        hintText: 'e.g., 1250000',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.attach_money_rounded,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _bacPercentController,
                        labelText: 'BAC %',
                        hintText: '2.5',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.percent_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSection(
              context,
              icon: Icons.location_on_rounded,
              title: 'Property Address',
              children: [
                CustomTextField(
                  controller: _addressController,
                  labelText: 'Street Address',
                  hintText: 'e.g., 123 Main Street',
                  prefixIcon: Icons.home_rounded,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _cityController,
                        labelText: 'City',
                        hintText: 'e.g., Los Angeles',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _stateController,
                        labelText: 'State',
                        hintText: 'CA',
                        prefixIcon: Icons.map_rounded,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: CustomTextField(
                        controller: _zipCodeController,
                        labelText: 'ZIP',
                        hintText: '90001',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_drop_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSection(
              context,
              icon: Icons.photo_library_rounded,
              title: 'Property Images',
              children: [
                SizedBox(height: 8.h),
                Obx(() => _buildImageGrid()),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final x = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (x != null) _newImages.add(File(x.path));
                    } catch (e) {
                      SnackbarHelper.showError('Failed to pick image');
                    }
                  },
                  icon: Icon(Icons.add_photo_alternate_outlined, size: 18.sp),
                  label: Text('Add Image', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.6)),
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildSection(
              context,
              icon: Icons.settings_rounded,
              title: 'Listing Settings',
              children: [
                Obx(
                  () => _buildToggle(
                    'I am the Listing Agent',
                    'You are the listing agent for this property',
                    _isListingAgent.value,
                    (v) => _isListingAgent.value = v,
                  ),
                ),
                SizedBox(height: 12.h),
                Obx(
                  () => _buildToggle(
                    'Dual Agency Allowed',
                    'Allow representing both buyer and seller',
                    _dualAgencyAllowed.value,
                    (v) => _dualAgencyAllowed.value = v,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading.value ? null : _saveListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading.value
                      ? SizedBox(
                          height: 22.h,
                          width: 22.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text('Save Changes', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MarketStatus>(
          value: _selectedStatus.value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.darkGray),
          borderRadius: BorderRadius.circular(12.r),
          items: [
            DropdownMenuItem(
              value: MarketStatus.forSale,
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18.sp, color: AppTheme.lightGreen),
                  SizedBox(width: 10.w),
                  Text('For Sale', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: MarketStatus.pending,
              child: Row(
                children: [
                  Icon(Icons.rule_folder_outlined, size: 18.sp, color: Colors.orange),
                  SizedBox(width: 10.w),
                  Text('Pending', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: MarketStatus.sold,
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, size: 18.sp, color: Colors.teal),
                  SizedBox(width: 10.w),
                  Text('Sold', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) _selectedStatus.value = v;
          },
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value ? AppTheme.primaryBlue.withOpacity(0.3) : AppTheme.lightGray,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
                SizedBox(height: 2.h),
                Text(subtitle, style: TextStyle(fontSize: 12.sp, color: AppTheme.mediumGray)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final total = _currentImages.length + _newImages.length;
    if (total == 0) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.lightGray),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 40.sp, color: AppTheme.mediumGray),
              SizedBox(height: 8.h),
              Text('No images yet', style: TextStyle(fontSize: 14.sp, color: AppTheme.mediumGray)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: total,
        itemBuilder: (context, index) {
          if (index < _currentImages.length) {
            final url = ImageUrlHelper.buildImageUrl(_currentImages[index]) ?? _currentImages[index];
            return _buildImageThumb(
              child: Image.network(url, fit: BoxFit.cover),
              onRemove: () => _currentImages.removeAt(index),
            );
          } else {
            final file = _newImages[index - _currentImages.length];
            return _buildImageThumb(
              child: Image.file(file, fit: BoxFit.cover),
              onRemove: () => _newImages.removeAt(index - _currentImages.length),
              isNew: true,
            );
          }
        },
      ),
    );
  }

  Widget _buildImageThumb({
    required Widget child,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Container(
      width: 100.w,
      height: 100.h,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isNew ? AppTheme.lightGreen : AppTheme.lightGray,
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: child,
          ),
          if (isNew)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text('New', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 14.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
