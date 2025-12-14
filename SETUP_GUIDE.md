# Roommate Manager

A comprehensive Flutter application for managing shared household expenses, chores, and balances among roommates.

## Features

✅ **User Authentication**
- Firebase Authentication (Sign Up/Sign In)
- Secure user accounts

✅ **Household Management**
- Create multiple households
- Add members to households
- Member management

✅ **Expense Tracking**
- Log expenses with descriptions and amounts
- Choose payer and split method
- Support for equal or custom splits
- Categorize expenses (Food, Utilities, Rent, Entertainment, Other)
- Track expense history

✅ **Balance Sheet**
- View who owes whom
- Real-time balance calculations
- Net balance view for each member

✅ **Settle Up**
- Record payments between members
- Support for multiple payment methods:
  - Cash
  - Venmo
  - PayPal
  - Bank Transfer
- Add notes to settlements
- Track payment history

✅ **Chore Management**
- Create and assign chores
- Daily and weekly frequency options
- Mark chores as complete
- Track assigned members
- Chore history

✅ **Analytics & Charts**
- Pie charts showing expenses by category
- Monthly spending breakdown
- Expenses by member
- Date range filtering
- Percentage breakdown

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── firebase_options.dart               # Firebase configuration
├── models/
│   ├── member.dart                     # Member model
│   ├── expense.dart                    # Expense model with split methods
│   ├── chore.dart                      # Chore model
│   ├── settlement.dart                 # Settlement/Payment model
│   └── household.dart                  # Household model
├── services/
│   ├── auth_service.dart              # Firebase authentication
│   ├── household_service.dart         # Household management
│   ├── expense_service.dart           # Expense tracking & balance calculation
│   └── chore_service.dart             # Chore management
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          # Authentication UI
│   ├── home/
│   │   ├── home_screen.dart           # Main navigation hub
│   │   ├── household_selection_screen.dart
│   │   └── create_household_screen.dart
│   ├── members/
│   │   └── members_screen.dart        # Member management
│   ├── expenses/
│   │   ├── expenses_screen.dart       # Expense list
│   │   └── add_expense_screen.dart    # Add expense form
│   ├── chores/
│   │   ├── chores_screen.dart        # Chore board
│   │   └── add_chore_screen.dart     # Add chore form
│   ├── balance/
│   │   ├── balance_sheet_screen.dart # Balance view
│   │   └── settle_up_screen.dart     # Settlement recording
│   └── charts/
│       └── charts_screen.dart        # Analytics & charts
```

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Backend**: Firebase (Authentication & Firestore)
- **State Management**: Provider
- **Charts**: FL Charts
- **Date/Time**: intl package

## Setup Instructions

### Prerequisites
- Flutter SDK (v3.10.3 or higher)
- Dart SDK
- Firebase Account
- Android Studio or Xcode (for running on device)

### 1. Clone the Repository
```bash
git clone https://github.com/KOOKIEKAT123/ROOMMATE-MANAGER.git
cd roommate_manager
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase

#### For Android:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing one
3. Add Android app:
   - Package name: `com.example.roommate_manager`
   - SHA-1 certificate fingerprint (from `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)
4. Download `google-services.json` and place in `android/app/`

#### For iOS:
1. Add iOS app in Firebase Console
   - Bundle ID: `com.example.roommateManager`
2. Download `GoogleService-Info.plist`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Add `GoogleService-Info.plist` to Runner project

#### For Web:
1. Add Web app in Firebase Console
2. Update `firebase_options.dart` with your credentials

### 4. Update Firebase Configuration
Edit `lib/firebase_options.dart` and replace placeholder values:
```dart
return FirebaseOptions(
  apiKey: 'YOUR_API_KEY_FROM_FIREBASE_CONSOLE',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_AUTH_DOMAIN',
  // ... other fields
);
```

### 5. Enable Required Firebase Services
In Firebase Console:
1. **Authentication**: Enable Email/Password sign-in
2. **Firestore**: Create database in test mode (or configure security rules)

### 6. Run the App
```bash
flutter run
```

Or for specific platforms:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## Database Structure (Firestore)

```
households/
├── {householdId}
│   ├── name: string
│   ├── ownerId: string
│   ├── memberIds: array
│   ├── categories: array
│   ├── createdAt: timestamp
│   ├── members/
│   │   └── {memberId}
│   │       ├── name: string
│   │       ├── email: string
│   │       └── createdAt: timestamp
│   ├── expenses/
│   │   └── {expenseId}
│   │       ├── description: string
│   │       ├── amount: number
│   │       ├── payerId: string
│   │       ├── splitMethod: string
│   │       ├── splits: map
│   │       ├── category: array
│   │       ├── date: timestamp
│   │       └── householdId: string
│   ├── settlements/
│   │   └── {settlementId}
│   │       ├── fromMemberId: string
│   │       ├── toMemberId: string
│   │       ├── amount: number
│   │       ├── method: string
│   │       ├── notes: string
│   │       ├── date: timestamp
│   │       └── householdId: string
│   └── chores/
│       └── {choreId}
│           ├── title: string
│           ├── frequency: string
│           ├── assignedTo: string
│           ├── completed: boolean
│           ├── createdAt: timestamp
│           ├── lastCompletedAt: timestamp
│           └── householdId: string
```

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own households
    match /households/{householdId} {
      allow read, write: if request.auth.uid in resource.data.memberIds;
      allow create: if request.auth.uid != null;
      
      // Subcollections
      match /members/{memberId} {
        allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
      }
      match /expenses/{expenseId} {
        allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
      }
      match /settlements/{settlementId} {
        allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
      }
      match /chores/{choreId} {
        allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(householdId)).data.memberIds;
      }
    }
  }
}
```

## Usage Guide

### Getting Started
1. **Sign Up**: Create an account with email and password
2. **Create Household**: Click the "Create Household" button
3. **Add Members**: Go to Members tab and add roommates (name only required initially)

### Managing Expenses
1. Navigate to **Expenses** tab
2. Click **+** button to add new expense
3. Fill in details:
   - Description (e.g., "Grocery shopping")
   - Amount (e.g., "50.00")
   - Payer (who paid)
   - Category
   - Split method (equal or custom)
4. View expense history in the list

### Tracking Balances
1. Go to **Balance** tab
2. View who owes whom
3. Click on any member to record a payment
4. Use **Settle Up** to record payments made

### Managing Chores
1. Navigate to **Chores** tab
2. Click **+** to create new chore
3. Assign to member and set frequency (daily/weekly)
4. Check off completed chores
5. Use popup menu to delete chores

### Viewing Analytics
1. Go to **Charts** tab
2. Select date range for analysis
3. View expenses by category (pie chart)
4. See breakdown by member
5. Check percentage distribution

## Future Enhancements

- Push notifications for overdue chores
- Payment reminders for unsettled balances
- Receipt attachment/image upload
- Monthly summary reports
- Custom categories per household
- Recurring expense templates
- Social features (notes, comments)
- Dark mode support
- Multi-currency support
- Expense splitting algorithms optimization

## Troubleshooting

### Firebase Connection Issues
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in correct location
- Check internet connection
- Ensure Firebase project is active

### Firestore Access Denied
- Check security rules in Firebase Console
- Verify user is authenticated
- Ensure user is added to household's memberIds

### Charts Not Displaying
- Ensure expenses exist in selected date range
- Check that categories are properly assigned to expenses
- Verify FL Charts dependency is installed

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
This project is open source and available under the MIT License.

## Support
For issues and questions:
- GitHub Issues: [Open an issue](https://github.com/KOOKIEKAT123/ROOMMATE-MANAGER/issues)
- Email: [Your email]

## Changelog

### v1.0.0 (Initial Release)
- ✅ User authentication with Firebase
- ✅ Household management
- ✅ Member management
- ✅ Expense tracking and logging
- ✅ Automatic balance calculation
- ✅ Settle up functionality
- ✅ Chore management (daily/weekly)
- ✅ Charts and analytics
- ✅ Multi-category expense tracking
