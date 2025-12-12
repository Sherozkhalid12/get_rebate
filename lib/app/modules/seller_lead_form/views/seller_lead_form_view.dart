import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/seller_lead_form/controllers/seller_lead_form_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class SellerLeadFormView extends GetView<SellerLeadFormController> {
  const SellerLeadFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
        title: Text(
          'Seller Lead Form',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 24),

            // Form
            _buildForm(context),

            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(context),

            const SizedBox(height: 20),

            // Privacy Note
            _buildPrivacyNote(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell, color: AppTheme.lightGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connect with a Local Agent & Learn\nHow Much You Can Save',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fill out this form to connect with local real estate agents who offer commission rebates.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Contact Info
            _buildSectionHeader(context, 'Contact Information', Icons.person),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.fullNameController,
              labelText: 'Full Name *',
              hintText: 'First and last name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.emailController,
              labelText: 'Email Address *',
              keyboardType: TextInputType.emailAddress,
              hintText: 'your.email@example.com',
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.phoneController,
              labelText: 'Phone Number *',
              keyboardType: TextInputType.phone,
              hintText: '(555) 123-4567',
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Preferred Contact Method *',
                controller.preferredContactMethod,
                controller.contactMethods,
                controller.setPreferredContactMethod,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'Best Time to Reach You',
                controller.bestTimeToReach,
                controller.bestTimes,
                controller.setBestTimeToReach,
                Icons.access_time,
              ),
            ),

            const SizedBox(height: 24),

            // Section 2: Property Information
            _buildSectionHeader(context, 'Property Information', Icons.home),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.propertyAddressController,
              labelText: 'Property Address *',
              hintText: 'Street address',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.cityController,
              labelText: 'City *',
              hintText: 'City',
              prefixIcon: Icons.location_city,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'Property Type *',
                controller.propertyType,
                controller.propertyTypeOptions,
                controller.setPropertyType,
                Icons.home_work,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'Estimated Property Value *',
                controller.estimatedValue,
                controller.estimatedValues,
                controller.setEstimatedValue,
                Icons.attach_money,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.yearBuiltController,
                    labelText: 'Year Built',
                    hintText: '1990',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: controller.squareFootageController,
                    labelText: 'Square Footage',
                    hintText: '2000',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.square_foot,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      context,
                      'Bedrooms',
                      controller.bedrooms,
                      controller.bedroomOptions,
                      controller.setBedrooms,
                      Icons.bed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      context,
                      'Bathrooms',
                      controller.bathrooms,
                      controller.bathroomOptions,
                      controller.setBathrooms,
                      Icons.bathtub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.recentUpdatesController,
              labelText: 'Any recent updates or renovations?',
              hintText: 'Describe any recent improvements',
              maxLines: 3,
              prefixIcon: Icons.build,
            ),

            const SizedBox(height: 24),

            // Section 3: Selling Details
            _buildSectionHeader(context, 'Selling Details', Icons.sell),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'When are you planning to sell? *',
                controller.timeToSell,
                controller.timeToSellOptions,
                controller.setTimeToSell,
                Icons.schedule,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Are you currently working with an agent? *',
                controller.workingWithAgent,
                controller.yesNoOptions,
                controller.setWorkingWithAgent,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Is the property currently listed? *',
                controller.currentlyListed,
                controller.yesNoOptions,
                controller.setCurrentlyListed,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Are you also planning to buy or build a new home? *',
                controller.alsoPlanningToBuy,
                controller.alsoPlanningOptions,
                controller.setAlsoPlanningToBuy,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Do you currently live in the property?',
                controller.currentlyLiving,
                controller.livingOptions,
                controller.setCurrentlyLiving,
              ),
            ),

            const SizedBox(height: 24),

            // Section 4: Pricing & Motivation
            _buildSectionHeader(
              context,
              'Pricing & Motivation',
              Icons.trending_up,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.idealPriceController,
              labelText: 'What is your ideal selling price?',
              hintText: 'Enter amount',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'How motivated are you to sell? *',
                controller.motivation,
                controller.motivationOptions,
                controller.setMotivation,
                Icons.psychology,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildMultiSelectChips(
                context,
                'What is most important to you?',
                controller.mostImportant,
                controller.mostImportantOptions,
                controller.toggleMostImportant,
              ),
            ),

            const SizedBox(height: 24),

            // Section 5: Rebate & Awareness
            _buildSectionHeader(
              context,
              'Rebate & Awareness',
              Icons.local_offer,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Did you know you can receive a real estate commission rebate when you sell through one of our agents? *',
                controller.rebateAwareness,
                controller.rebateAwarenessOptions,
                controller.setRebateAwareness,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Would you like to see how much your rebate could be?',
                controller.showRebateCalculator,
                controller.showRebateOptions,
                controller.setShowRebateCalculator,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'How did you hear about us?',
                controller.howDidYouHear,
                controller.howDidYouHearOptions,
                controller.setHowDidYouHear,
                Icons.info_outline,
              ),
            ),

            const SizedBox(height: 24),

            // Section 6: Comments or Questions
            _buildSectionHeader(
              context,
              'Comments or Questions',
              Icons.comment,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.commentsController,
              labelText: 'Anything else you\'d like your agent to know?',
              hintText: 'Space for special notes or requests',
              maxLines: 4,
              prefixIcon: Icons.edit_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.lightGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioGroup(
    BuildContext context,
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...options
            .map(
              (option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: selectedValue,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                activeColor: AppTheme.lightGreen,
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedValue.isEmpty ? null : selectedValue,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.mediumGray, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(
    BuildContext context,
    String title,
    List<String> selectedValues,
    List<String> options,
    Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return InkWell(
              onTap: () => onToggle(option),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.lightGreen : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightGreen
                        : AppTheme.mediumGray,
                  ),
                ),
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppTheme.white : AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Obx(
      () => CustomButton(
        text: 'Connect with a Local Agent &\nLearn How Much You Can Save',
        onPressed: controller.isLoading ? null : controller.submitForm,
        icon: Icons.send,
        width: double.infinity,
        isLoading: controller.isLoading,
      ),
    );
  }

  Widget _buildPrivacyNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: AppTheme.mediumGray, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your information is only shared with local agents you choose. No spam, ever.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mediumGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
