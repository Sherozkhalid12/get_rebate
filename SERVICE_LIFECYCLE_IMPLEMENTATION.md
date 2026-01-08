# Service Lifecycle Implementation Guide

## Overview

This document describes the implementation of the structured service lifecycle system that activates when an agent or loan officer responds to a user's proposal. The system ensures clear state transitions, mutual accountability, and a premium user experience.

## Architecture

### Models

1. **ProposalModel** (`lib/app/models/proposal_model.dart`)
   - Represents a proposal from user to agent/loan officer
   - Status states: `pending`, `accepted`, `rejected`, `inProgress`, `completed`, `reported`
   - Tracks all lifecycle events and timestamps

### Services

1. **ProposalService** (`lib/app/services/proposal_service.dart`)
   - Create proposals
   - Accept/reject proposals
   - Complete services
   - Get proposals by user or professional

2. **ReportService** (`lib/app/services/report_service.dart`)
   - Submit reports about service issues
   - Links reports to proposals

3. **ReviewService** (`lib/app/services/review_service.dart`)
   - Submit reviews and ratings
   - Supports both agents and loan officers

## Service Lifecycle Flow

```
1. User creates proposal → Status: PENDING
2. Agent/LO responds:
   - ACCEPTED → Status: ACCEPTED → Auto-transition to IN_PROGRESS
   - REJECTED → Status: REJECTED (terminal state)
3. Service in progress → Status: IN_PROGRESS
   - "Complete Service" button visible to both parties
4. Service completion → Status: COMPLETED
   - User can submit review/rating
   - Agent/LO can submit service report
5. Issue reporting → Status: REPORTED (alternative to completed)
   - Either party can report issues
```

## Implementation Status

### ✅ Completed

- [x] Proposal model with all status states
- [x] ProposalService for API integration
- [x] ReportService for issue reporting
- [x] ReviewService for reviews and ratings
- [x] API constants updated

### 🔄 In Progress

- [ ] ProposalController for state management
- [ ] UI components (Complete Service button, Review dialog, Report dialog)
- [ ] Integration with chat/messages view
- [ ] Notification handling

## Next Steps

1. **Create ProposalController** - Manage proposal state and lifecycle
2. **Create UI Components**:
   - Complete Service button (shown when status is `inProgress`)
   - Review dialog (shown when status is `completed`)
   - Report dialog (shown when status is `inProgress`)
3. **Integrate with Messages View** - Show proposal status and actions in chat
4. **Add Notification Support** - Handle proposal acceptance/rejection notifications

## API Endpoints

### Proposals
- `POST /api/v1/proposals/create` - Create proposal
- `POST /api/v1/proposals/{id}/accept` - Accept proposal
- `POST /api/v1/proposals/{id}/reject` - Reject proposal
- `POST /api/v1/proposals/{id}/complete` - Complete service
- `GET /api/v1/proposals/user/{userId}` - Get user proposals
- `GET /api/v1/proposals/professional/{professionalId}` - Get professional proposals

### Reports
- `POST /api/v1/reports` - Submit report

### Reviews
- `POST /api/v1/buyer/addReview` - Submit agent review
- `POST /api/v1/loan-officers/{id}/reviews` - Submit loan officer review

## Usage Examples

### Creating a Proposal

```dart
final proposalService = ProposalService();
final proposal = await proposalService.createProposal(
  userId: currentUser.id,
  userName: currentUser.name,
  professionalId: agent.id,
  professionalName: agent.name,
  professionalType: 'agent',
  message: 'I would like to work with you on this property.',
);
```

### Accepting a Proposal

```dart
final updatedProposal = await proposalService.acceptProposal(
  proposalId: proposal.id,
  professionalId: agent.id,
);
// Status automatically transitions to IN_PROGRESS
```

### Completing Service

```dart
final completedProposal = await proposalService.completeService(
  proposalId: proposal.id,
  userId: currentUser.id,
);
// Status transitions to COMPLETED
```

### Submitting Review

```dart
final reviewService = ReviewService();
await reviewService.submitReview(
  currentUserId: currentUser.id,
  agentId: agent.id,
  rating: 5,
  review: 'Excellent service! Highly recommended.',
  proposalId: proposal.id,
);
```

### Submitting Report

```dart
final reportService = ReportService();
await reportService.submitReport(
  reporterId: currentUser.id,
  reportedUserId: agent.id,
  reason: 'Service failure',
  description: 'The agent repeatedly delivered the order late.',
  proposalId: proposal.id,
);
```

## UI Components Needed

1. **ProposalStatusBadge** - Shows current proposal status
2. **CompleteServiceButton** - Visible when status is `inProgress`
3. **ReviewDialog** - For submitting reviews after completion
4. **ReportDialog** - For reporting issues
5. **ProposalActions** - Container for all proposal-related actions

## Integration Points

1. **Chat/Messages View** - Show proposal status and actions
2. **Agent/Loan Officer Profile** - Show "Create Proposal" button
3. **Notifications** - Handle proposal acceptance/rejection
4. **Proposal List View** - Show all user's proposals

## Design Principles

- Clear visual states for each lifecycle stage
- Smooth transitions and subtle animations
- Progressive disclosure (actions appear when relevant)
- Equal visibility and control for both parties
- Trust, fairness, and professionalism



