# Post-Closing Survey Feature

## Overview

The Post-Closing Survey feature allows buyers and sellers to review their agents after closing. This system collects feedback, calculates ratings, tracks total rebates paid, and displays reviews on agent profiles.

## Key Features

### 1. **Comprehensive Survey (9 Questions)**
- 8 mandatory questions + 1 optional comment field
- Progressive disclosure: One question at a time
- Visual progress indicator
- Rebate amount captured even if survey is incomplete

### 2. **Intelligent Rating System**
- Weighted scoring algorithm (0-100 scale)
- Converts to 5-star display rating
- Multiple question types: scales, multiple choice, free text

### 3. **Agent Transparency**
- Agents can preview survey questions before working with clients
- Encourages exceptional service
- Clear understanding of rating criteria

### 4. **Public Reviews & Stats**
- Agent profiles display star ratings
- Show review distribution (5-star, 4-star, etc.)
- Display verified client comments
- Track total rebates paid through the platform
- Show recommendation percentage

## Rating Calculation

### Weighted Scoring System

The rating is calculated using a weighted average approach:

| Questions | Weight | Description |
|-----------|--------|-------------|
| Questions 5 & 9 | 40% | Direct satisfaction ratings (1-5 and 1-10 scales) |
| Question 7 | 25% | Client recommendation likelihood |
| Questions 2, 4, 6 | 25% | Process quality (expectations, compliance, ease) |
| Question 3 | 10% | Rebate application method |
| Question 8 | N/A | Optional comments (displayed but don't affect score) |

### Score Conversion

- Internal score: 0-100 points
- Display format: 0-5 stars (with half-star precision)
- Example: 85/100 = 4.25 stars = "Very Good"

### Star Rating Descriptions

| Stars | Description |
|-------|-------------|
| 4.5 - 5.0 | Excellent |
| 4.0 - 4.4 | Very Good |
| 3.5 - 3.9 | Good |
| 3.0 - 3.4 | Average |
| 2.0 - 2.9 | Below Average |
| < 2.0 | Poor |

## Survey Questions

### Question 1: Rebate Amount (Required)
**Type:** Dollar input
**Purpose:** Track total rebates paid through platform
**Special:** Saved immediately, even if survey isn't completed

### Question 2: Received Expected Rebate (Required)
**Type:** Multiple choice (Yes / No / Not sure)
**Weight:** 10%
**Purpose:** Measure transparency and expectation management

### Question 3: Rebate Application Method (Required)
**Type:** Multiple choice with "Other" explanation
- Yes (credit at closing)
- No
- Other (please explain)

**Weight:** 10%
**Purpose:** Track how rebates are delivered

### Question 4: Signed Disclosure Form (Required)
**Type:** Multiple choice (Yes / No / Not sure)
**Weight:** 7.5%
**Purpose:** Ensure compliance with rebate disclosure requirements

### Question 5: Overall Satisfaction (Required)
**Type:** 1-5 scale (1 = Not satisfied, 5 = Very satisfied)
**Weight:** 20%
**Purpose:** Direct measure of satisfaction

### Question 6: Rebate Ease (Required)
**Type:** Multiple choice
- Very easy
- Somewhat easy
- Neutral
- Difficult

**Weight:** 7.5%
**Purpose:** Measure process efficiency

### Question 7: Recommendation (Required)
**Type:** Multiple choice
- Definitely
- Probably
- Not sure
- Probably not
- Definitely not

**Weight:** 25%
**Purpose:** Net Promoter Score equivalent

### Question 8: Additional Comments (Optional)
**Type:** Free text (up to 500 characters)
**Weight:** 0% (doesn't affect rating)
**Purpose:** Provide qualitative feedback
**Note:** May be displayed publicly on agent's profile

### Question 9: Agent Rating (Required)
**Type:** 1-10 scale (1 = Poor, 10 = Excellent)
**Weight:** 20%
**Purpose:** Final overall rating

## Implementation Files

### Models
- **`lib/app/models/post_closing_survey_model.dart`**
  - `PostClosingSurvey`: Survey response data
  - `AgentReviewStats`: Aggregated statistics
  - Enums for all answer types

### Services
- **`lib/app/services/survey_rating_service.dart`**
  - Score calculation algorithm
  - Stats aggregation
  - Display formatting

### Controllers
- **`lib/app/modules/post_closing_survey/controllers/post_closing_survey_controller.dart`**
  - Survey state management
  - Progressive disclosure logic
  - Auto-save rebate amount
  - Submission handling

### Views
- **`lib/app/modules/post_closing_survey/views/post_closing_survey_view.dart`**
  - Main survey interface
  - Step-by-step question flow
  - Progress indicator
  
- **`lib/app/modules/post_closing_survey/views/survey_preview_view.dart`**
  - Agent preview of survey questions
  - Rating methodology explanation

### Widgets
- **`lib/app/widgets/agent_reviews_widget.dart`**
  - `AgentReviewsWidget`: Full review display for profiles
  - `AgentRatingBadge`: Compact rating badge for cards/lists
  - Star rating visualization
  - Review distribution chart
  - Individual review cards

## Usage Examples

### 1. Navigating to Survey

```dart
// After closing, navigate buyer/seller to survey
Get.toNamed('/post-closing-survey', arguments: {
  'agentId': 'agent-123',
  'agentName': 'John Smith',
  'userId': 'user-456',
  'transactionId': 'transaction-789',
  'isBuyer': true,  // or false for seller
});
```

### 2. Agent Previewing Questions

```dart
// Show survey preview to agents
Get.to(() => const SurveyPreviewView(isBuyer: true));
```

### 3. Displaying Reviews on Profile

```dart
// On agent profile page
AgentReviewsWidget(
  stats: agentReviewStats,  // AgentReviewStats object
  reviews: completedSurveys,  // List<PostClosingSurvey>
  onViewAllReviews: () => Get.toNamed('/agent-reviews/${agent.id}'),
)
```

### 4. Showing Rating Badge

```dart
// In agent listing card
AgentRatingBadge(
  starRating: agent.stats.starRating,
  reviewCount: agent.stats.totalReviews,
  showCount: true,
)
```

## Backend Integration

### Required API Endpoints

```dart
// Save rebate amount (called immediately when Q1 is answered)
POST /api/surveys/rebate-amount
{
  "userId": "string",
  "transactionId": "string",
  "rebateAmount": number
}

// Submit complete survey
POST /api/surveys
{
  ...PostClosingSurvey fields...
}

// Get agent reviews
GET /api/agents/{agentId}/reviews
Response: {
  "stats": AgentReviewStats,
  "reviews": PostClosingSurvey[]
}

// Get total rebates paid across platform
GET /api/stats/total-rebates-paid
Response: {
  "totalRebatesPaid": number
}
```

## Future Enhancements

### For Loan Officers
Create a separate survey with questions specific to the loan process:
- Loan approval experience
- Communication quality
- Rate competitiveness
- Closing timeline
- Post-closing support

### Advanced Features
1. **Sentiment Analysis**: Automatically analyze Question 8 comments
2. **Response Time Tracking**: Measure how long agents take to respond
3. **Badge System**: Award badges for milestones (e.g., "100 5-Star Reviews")
4. **Review Responses**: Allow agents to respond to reviews
5. **Verification System**: Email/SMS verification of reviewers
6. **Photo Upload**: Allow clients to upload photos from transactions

## Best Practices

### For Platform
1. Send survey link 1-2 days after closing
2. Send reminder if not completed after 1 week
3. Don't display reviews until agent has at least 3 reviews
4. Moderate comments for inappropriate content
5. Allow agents to report fraudulent reviews

### For Agents
1. Set expectations early about rebate amount
2. Explain rebate disclosure form clearly
3. Make rebate process as smooth as possible
4. Ask satisfied clients to complete the survey
5. Use feedback to improve service

### For Developers
1. Always validate survey data on backend
2. Use transactions when saving survey responses
3. Calculate scores asynchronously
4. Cache agent stats for performance
5. Index reviews by agent ID for fast queries

## Testing Checklist

- [ ] Survey can be started and rebate amount saved
- [ ] Survey can be completed partially and resumed
- [ ] All mandatory questions block progression until answered
- [ ] Optional question (Q8) can be skipped
- [ ] Score calculation matches expected algorithm
- [ ] Agent preview displays all questions correctly
- [ ] Reviews display properly on agent profiles
- [ ] Rating badge shows correct star rating
- [ ] Distribution chart reflects actual review data
- [ ] Total rebates paid calculates correctly

## Questions?

For questions or feature requests related to the Post-Closing Survey system, please contact the development team.

---

**Version:** 1.0  
**Last Updated:** October 25, 2025  
**Author:** GetaRebate Development Team

