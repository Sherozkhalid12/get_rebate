import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/buyer_lead_form_v2/controllers/buyer_lead_form_v2_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class BuyerLeadFormV2View extends GetView<BuyerLeadFormV2Controller> {
  const BuyerLeadFormV2View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
        title: Text(
          'Buyer Lead Form ',
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
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Connect with a Local Agent & GetaRebate',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
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

            // Section 2: Buying or Building
            _buildSectionHeader(context, 'Buying or Building', Icons.home_work),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Are you looking to: *',
                controller.lookingTo,
                controller.lookingToOptions,
                controller.setLookingTo,
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: controller.locationController,
              labelText: 'Where are you planning to buy or build? *',
              hintText: 'Enter ZIP code or city, state',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Are you currently living in the area or relocating?',
                controller.currentlyLiving,
                controller.livingOptions,
                controller.setCurrentlyLiving,
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Property Details
            _buildSectionHeader(context, 'Property Details', Icons.home),
            const SizedBox(height: 16),

            Obx(
              () => _buildMultiSelectChips(
                context,
                'Property Type *',
                controller.propertyTypes,
                controller.propertyTypeOptions,
                controller.togglePropertyType,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'Price Range *',
                controller.priceRange,
                controller.priceRanges,
                controller.setPriceRange,
                Icons.attach_money,
              ),
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
              controller: controller.mustHaveFeaturesController,
              labelText: 'Must-Have Features',
              hintText: 'e.g. large yard, 3-car garage, near schools',
              maxLines: 3,
              prefixIcon: Icons.star_outline,
            ),

            const SizedBox(height: 24),

            // Section 4: Readiness & Financing
            _buildSectionHeader(
              context,
              'Readiness & Financing',
              Icons.schedule,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildDropdown(
                context,
                'What\'s your time frame to buy/build? *',
                controller.timeFrame,
                controller.timeFrames,
                controller.setTimeFrame,
                Icons.calendar_today,
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
                'Have you been pre-approved for a mortgage? *',
                controller.preApproved,
                controller.preApprovedOptions,
                controller.setPreApproved,
              ),
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Would you like to see loan officers whose lenders allow rebates at closing?',
                controller.searchForLoanOfficers,
                controller.loanOfficerOptions,
                controller.setSearchForLoanOfficers,
              ),
            ),

            const SizedBox(height: 24),

            // Section 5: Rebate Awareness & Referral
            _buildSectionHeader(
              context,
              'Rebate Awareness & Referral',
              Icons.local_offer,
            ),
            const SizedBox(height: 16),

            Obx(
              () => _buildRadioGroup(
                context,
                'Did you know you can receive a real estate commission rebate when buying through one of our agents? *',
                controller.rebateAwareness,
                controller.rebateAwarenessOptions,
                controller.setRebateAwareness,
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
            const SizedBox(height: 16),

            Obx(
              () => CheckboxListTile(
                title: const Text(
                  'Would you like to be set up on an automatic MLS search for properties that match your criteria?',
                ),
                subtitle: const Text(
                  'The agent you select will set up automated property alerts',
                ),
                value: controller.autoMLSSearch,
                onChanged: (_) => controller.toggleAutoMLSSearch(),
                activeColor: AppTheme.primaryBlue,
                contentPadding: EdgeInsets.zero,
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
              hintText: 'For details, timelines, etc.',
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
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
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
                activeColor: AppTheme.primaryBlue,
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
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
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
        text: 'Connect with a Local Agent & Get a Rebate',
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
              'Your information is never shared except with the local agents you choose.',
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
