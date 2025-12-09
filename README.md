# GetaRebate - Real Estate Rebate Mobile App

A comprehensive Flutter mobile application that connects buyers and sellers with real estate agents and loan officers who offer rebates, helping users save money on their real estate transactions.

## Features

### 🏠 Buyer Flow
- **Search & Discovery**: Find agents and loan officers by ZIP code
- **Agent Profiles**: View detailed agent information, reviews, and ratings
- **Lead Forms**: Comprehensive buyer lead form with MLS search option
- **Rebate Calculator**: Calculate potential rebates based on property price
- **Favorites**: Save preferred agents and loan officers

### 🏡 Seller Flow
- **Agent Search**: Find agents specializing in seller representation
- **Seller Lead Forms**: Detailed seller information collection
- **Rebate Estimates**: Dynamic rebate calculations based on property value
- **Property Management**: Track property details and selling timeline

### 👨‍💼 Agent Flow
- **Dashboard**: Overview of performance metrics and activity
- **ZIP Code Management**: Claim up to 6 ZIP codes for exclusive visibility
- **Billing & Subscriptions**: Monthly subscription management
- **Lead Management**: Receive and manage buyer/seller leads
- **Profile Management**: Update profile, bio, and featured listings

### 🏦 Loan Officer Flow
- **Similar to Agent Flow**: ZIP code management and lead generation
- **Rebate Policy Confirmation**: Verify rebate allowance policies
- **Performance Tracking**: Monitor search appearances and contacts

## Technical Architecture

### State Management
- **GetX**: Reactive state management and dependency injection
- **MVC Pattern**: Clean separation of concerns
- **Controllers**: Handle business logic and state updates

### UI/UX Design
- **Color Scheme**: White, Blue (#2563EB), Light Green (#10B981)
- **Modern Design**: Clean, professional interface with smooth animations
- **Responsive**: Optimized for mobile devices
- **Accessibility**: Screen reader friendly and intuitive navigation

### Key Features
- **Location Services**: GPS-based ZIP code search
- **Social Authentication**: Google, Apple, Facebook login
- **Image Handling**: Profile image upload and management
- **Form Validation**: Comprehensive input validation
- **Animations**: Smooth transitions using flutter_animate

## Project Structure

```
lib/
├── app/
│   ├── app.dart                 # Main app configuration
│   ├── bindings/               # Dependency injection bindings
│   ├── controllers/            # Global controllers (Auth, Location, Theme)
│   ├── models/                 # Data models (User, Agent, LoanOfficer, ZipCode)
│   ├── routes/                 # App routing configuration
│   ├── theme/                  # App theme and styling
│   └── modules/                # Feature modules
│       ├── splash/            # Splash screen
│       ├── onboarding/        # User onboarding
│       ├── auth/              # Authentication
│       ├── buyer/             # Buyer flow
│       ├── seller/            # Seller flow
│       ├── agent/             # Agent dashboard
│       ├── loan_officer/      # Loan officer dashboard
│       └── profile/           # User profile
└── widgets/                   # Reusable UI components
```

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd getrebate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Dependencies

- **get**: State management and routing
- **google_fonts**: Typography
- **flutter_animate**: Animations
- **geolocator**: Location services
- **image_picker**: Image selection
- **cached_network_image**: Image caching
- **get_storage**: Local storage
- **dio**: HTTP client

## App Flow

1. **Splash Screen**: Brand introduction and auto-redirect
2. **Onboarding**: 3-slide introduction to app features
3. **Authentication**: Login/signup with role selection
4. **Role-based Dashboard**: 
   - Buyers: Agent and loan officer search
   - Sellers: Agent search and property management
   - Agents: ZIP code management and lead tracking
   - Loan Officers: Similar to agents with rebate focus

## Key Screens

### Authentication
- Multi-provider login (Email, Google, Apple, Facebook)
- Role selection (Buyer, Seller, Agent, Loan Officer)
- Form validation and error handling

### Search & Discovery
- ZIP code-based search
- Location services integration
- Filtered results with claimed ZIP priority
- Agent/Loan Officer profile cards

### Lead Forms
- **Buyer Form**: Contact info, property details, readiness, financing
- **Seller Form**: Property info, selling details, pricing, motivation
- **MLS Integration**: Automatic property search setup option

### Rebate Calculator
- Property price input
- Commission rate calculation
- Real-time rebate estimation
- Contact agent integration

## Future Enhancements

- **Messaging System**: In-app communication between users and agents
- **Push Notifications**: Real-time updates and alerts
- **Admin Panel**: Web-based administration interface
- **Payment Integration**: Stripe/PayPal for subscriptions
- **Advanced Analytics**: Detailed performance metrics
- **Document Management**: File upload and sharing
- **Video Calls**: Integrated video consultation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.# get_a_rebate
# get_rebate
