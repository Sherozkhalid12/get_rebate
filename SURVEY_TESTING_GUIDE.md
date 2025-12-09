# Post-Closing Survey Testing Guide

## Quick Start

### Option 1: Using the Test Dashboard (Recommended)

1. **Navigate to the test dashboard:**
   ```dart
   // Add this temporarily to your app (e.g., in a debug menu or button)
   import 'package:getrebate/app/modules/survey_test/views/survey_test_view.dart';
   
   // Navigate to test view
   Get.to(() => const SurveyTestView());
   ```

2. **Use the visual testing interface** to test all features with one-click buttons

### Option 2: Manual Navigation

Navigate directly to any component:

```dart
// 1. Start a survey
Get.to(
  () => const PostClosingSurveyView(),
  arguments: {
    'agentId': 'test-agent-123',
    'agentName': 'John Smith',
    'userId': 'test-user-456',
    'transactionId': 'test-transaction-789',
    'isBuyer': true,
  },
);

// 2. View agent preview
Get.to(() => const SurveyPreviewView(isBuyer: true));

// 3. View reviews widget
Get.to(() => YourAgentProfilePage());
```

---

## Testing Flow - Step by Step

### 🧪 Test 1: Complete Survey Flow

**Objective:** Test the entire survey from start to finish

#### Steps:

1. **Start Survey**
   - Click "Start Survey (as Buyer)" from test dashboard
   - OR navigate manually using the code above

2. **Header Review**
   - ✅ Verify welcome message appears
   - ✅ Check agent name is displayed correctly
   - ✅ Read the introductory text

3. **Question 1: Rebate Amount**
   - Enter: `8500` (or any amount)
   - ✅ Verify green checkmark appears
   - ✅ Confirm "Rebate amount saved!" message shows
   - **Important:** Try closing the app here - the rebate amount should be saved!

4. **Question 2: Expected Rebate**
   - Select: "Yes"
   - ✅ Verify selection is highlighted in green
   - ✅ Click "Next" button

5. **Question 3: Application Method**
   - Select: "Yes" (credit at closing)
   - ✅ Verify you can proceed
   - **Extra Test:** Select "Other" and verify text field appears

6. **Question 4: Signed Disclosure**
   - Select: "Yes"
   - ✅ Verify selection registered
   - Click "Next"

7. **Question 5: Overall Satisfaction**
   - Select: 5 (Very satisfied)
   - ✅ Verify number button turns green
   - ✅ Check you can change selection

8. **Question 6: Rebate Ease**
   - Select: "Very easy"
   - Click "Next"

9. **Question 7: Recommendation**
   - Select: "Definitely"
   - ✅ Verify this is a key question (affects rating)

10. **Question 8: Comments (Optional)**
    - Type: "Great experience! Highly recommend."
    - ✅ Verify character counter (500 max)
    - **Extra Test:** Try clicking "Next" without typing - should work since optional

11. **Question 9: Agent Rating**
    - Select: 10 (Excellent)
    - ✅ Verify this is the last question
    - ✅ Button should say "Submit Survey"

12. **Submit**
    - Click "Submit Survey"
    - ✅ Verify loading indicator appears
    - ✅ Confirm success message shows
    - ✅ App returns to previous screen

#### Expected Results:
- ✅ Progress bar updates at each step (11%, 22%, 33%... 100%)
- ✅ "Back" button works correctly
- ✅ Can't proceed without answering required questions
- ✅ All selections are preserved when going back
- ✅ Rebate amount saved even if survey incomplete

---

### 🧪 Test 2: Incomplete Survey (Auto-Save Test)

**Objective:** Verify rebate amount saves even if survey is abandoned

#### Steps:

1. Start new survey
2. Enter rebate amount: `12000`
3. ✅ Wait for "Rebate amount saved!" message
4. Click back/close WITHOUT completing survey
5. ✅ Verify rebate amount was saved to backend (check your database/logs)

#### Expected Results:
- ✅ Rebate amount persisted
- ✅ Survey marked as incomplete
- ✅ User can resume later (if you implement resume feature)

---

### 🧪 Test 3: Agent Preview

**Objective:** Test what agents see before working with clients

#### Steps:

1. Click "View Survey Preview (Agent View)"
2. **Review All 9 Questions:**
   - ✅ Each question clearly displayed
   - ✅ "Required" badges on questions 1-7 and 9
   - ✅ Question 8 marked as "Optional"
   - ✅ Special notes displayed (e.g., Q1 auto-save note)

3. **Check Rating Explanation:**
   - ✅ Weighted breakdown shown:
     - Questions 5 & 9: 40%
     - Question 7: 25%
     - Questions 2, 4, 6: 25%
     - Question 3: 10%

4. Click "Got it" button

#### Expected Results:
- ✅ All questions displayed clearly
- ✅ Rating methodology transparent
- ✅ Helps agents understand how to provide better service

---

### 🧪 Test 4: Reviews Display Widget

**Objective:** Test how reviews appear on agent profiles

#### Steps:

1. Click "View Full Reviews Widget"

2. **Overall Rating Section:**
   - ✅ Star rating displays correctly (e.g., 4.5 ⭐)
   - ✅ Rating description shown (e.g., "Very Good")
   - ✅ Total review count displayed
   - ✅ Recommendation percentage shown (e.g., "80% Would Recommend")

3. **Rating Distribution:**
   - ✅ Bar chart shows distribution across 5 stars
   - ✅ Numbers add up to total reviews
   - ✅ Visual bars proportional to percentages

4. **Recent Reviews:**
   - ✅ Up to 3 reviews with comments displayed
   - ✅ Each review shows:
     - Star rating
     - Date
     - Comment text
     - "Verified Buyer/Seller" badge
     - "Would recommend" indicator

5. **View All Button:**
   - ✅ Appears if more than 3 reviews
   - ✅ Shows total count

#### Sample Reviews to Check:
```
Review 1: 5.0★ - "Fantastic! Highly recommend!"
Review 2: 4.5★ - "Great experience overall..."
Review 3: 4.5★ - "Professional service..."
Review 4: 4.0★ - (No comment)
Review 5: 3.0★ - "Good but could improve..."
```

Expected average: ~4.2 stars

---

### 🧪 Test 5: Rating Badge (Compact)

**Objective:** Test compact badge for cards/lists

#### Steps:

1. Click "View Rating Badge (Compact)"

2. **Test Three Variations:**
   - ✅ **With count:** `⭐ 4.5 (5)`
   - ✅ **Without count:** `⭐ 4.5`
   - ✅ **No reviews:** `No reviews yet` (gray badge)

3. Check styling:
   - ✅ Green background with opacity
   - ✅ Readable on light and dark backgrounds
   - ✅ Appropriate size for cards

---

### 🧪 Test 6: Sample Data Verification

**Objective:** Verify the demo data and calculations are correct

#### Steps:

1. Click "View Sample Statistics"

2. **Verify Numbers:**
   ```
   Total Reviews: 5
   Average Score: ~85/100
   Star Rating: ~4.2 ⭐
   Total Rebates Paid: $52,000
   Would Recommend: 4/5
   ```

3. **Rating Distribution:**
   ```
   5⭐: 2 reviews
   4⭐: 2 reviews  
   3⭐: 1 review
   2⭐: 0 reviews
   1⭐: 0 reviews
   ```

4. **Verify Calculation:**
   - Survey 1: Score ~95 → 5 stars
   - Survey 2: Score ~88 → 4.5 stars
   - Survey 3: Score ~88 → 4.5 stars
   - Survey 4: Score ~78 → 4 stars
   - Survey 5: Score ~60 → 3 stars
   - **Average: (95+88+88+78+60)/5 = 81.8 → 4.1 stars** ✅

---

## Testing Checklist

### Functionality Tests
- [ ] Survey can be started successfully
- [ ] All 9 questions display correctly
- [ ] Required questions block progression
- [ ] Optional question (Q8) can be skipped
- [ ] Progress indicator updates correctly
- [ ] Back button navigates properly
- [ ] Rebate amount auto-saves on Question 1
- [ ] Survey can be submitted successfully
- [ ] Success message appears after submission

### Rating Calculation Tests
- [ ] Scores calculate correctly (0-100)
- [ ] Stars convert properly (0-5)
- [ ] Weighted algorithm works as expected
- [ ] Rating descriptions match score ranges

### Display Tests
- [ ] Agent preview shows all questions
- [ ] Reviews widget displays correctly
- [ ] Rating badge renders properly
- [ ] Star icons display correctly
- [ ] Distribution chart shows accurate data
- [ ] Review comments display properly
- [ ] Verified badges appear
- [ ] Dates format correctly

### Edge Cases
- [ ] Survey with all 5s/10s → 5.0 stars
- [ ] Survey with all 1s/1s → Low score
- [ ] Mixed responses → Accurate weighted score
- [ ] No reviews → "No reviews yet" badge
- [ ] Very long comments → Truncation/wrapping
- [ ] Special characters in comments → Displays correctly

### Performance Tests
- [ ] Survey loads quickly
- [ ] Navigation between questions is smooth
- [ ] Reviews widget loads fast with many reviews
- [ ] No lag when selecting answers
- [ ] Auto-save happens quickly (< 1 second)

---

## Common Issues & Solutions

### Issue: Survey won't submit
**Solution:** 
- Check all required questions are answered
- Verify network connection (if using real API)
- Check console for error messages

### Issue: Rebate amount not saving
**Solution:**
- Verify the amount is valid (> 0)
- Check the save confirmation message appears
- Ensure backend API endpoint is working

### Issue: Rating calculations seem wrong
**Solution:**
- Review the scoring algorithm in `survey_rating_service.dart`
- Verify all question responses are captured
- Check weighted percentages add to 100%

### Issue: Reviews not displaying
**Solution:**
- Confirm reviews have `isComplete: true`
- Check that surveys have `calculatedScore` set
- Verify `completedAt` date is set

---

## Adding to Your App Routes

To integrate the test dashboard into your app permanently:

```dart
// lib/app/routes/app_routes.dart
static const surveyTest = '/survey-test';

// lib/app/routes/app_pages.dart
GetPage(
  name: Routes.surveyTest,
  page: () => const SurveyTestView(),
),

// To use:
Get.toNamed(Routes.surveyTest);
```

---

## Production Checklist

Before going live with this feature:

### Backend Integration
- [ ] Create `/api/surveys/rebate-amount` endpoint
- [ ] Create `/api/surveys` POST endpoint
- [ ] Create `/api/agents/{id}/reviews` GET endpoint
- [ ] Implement survey data validation
- [ ] Set up database tables/collections
- [ ] Add indexes for performance

### Email/Notifications
- [ ] Create post-closing email template
- [ ] Include survey link in email
- [ ] Send 1-2 days after closing
- [ ] Send reminder after 1 week if incomplete

### Moderation
- [ ] Implement comment moderation system
- [ ] Flag inappropriate content
- [ ] Allow agents to report fraudulent reviews
- [ ] Set up admin review dashboard

### Analytics
- [ ] Track survey completion rate
- [ ] Monitor average time to complete
- [ ] Track which questions have issues
- [ ] Monitor score distributions

### Legal/Compliance
- [ ] Add terms of service for reviews
- [ ] Include privacy policy for survey data
- [ ] Implement GDPR compliance (if applicable)
- [ ] Add dispute resolution process

---

## Next Steps

1. ✅ Test all features using this guide
2. ✅ Fix any bugs discovered
3. ✅ Connect to backend APIs
4. ✅ Set up email notifications
5. ✅ Implement moderation system
6. ✅ Create admin dashboard
7. ✅ Launch to beta users
8. ✅ Collect feedback
9. ✅ Launch to production

---

## Questions or Issues?

If you encounter any problems or have questions:

1. Check console logs for error messages
2. Verify all imports are correct
3. Ensure GetX dependencies are up to date
4. Review the `POST_CLOSING_SURVEY_FEATURE.md` documentation
5. Check that demo data is loading properly

**Happy Testing! 🚀**

