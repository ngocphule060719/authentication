# Flutter Authentication App

A Flutter authentication app using BLoC pattern and GetX for dependency injection.

## Features

- User Authentication
  - Login with email and password
  - Registration with name, email, and password
  - Form validation with real-time feedback
  - Secure password handling
  - Error handling and user feedback
  - Loading state management
  - Navigation management

- Architecture Implementation
  - Separation of concerns
  - Domain-driven design
  - Repository pattern
  - Data sources (Local and Remote)
  - Dependency injection using GetX

- Testing
  - Unit tests for business logic
  - Widget tests for UI components
  - Integration tests for authentication flow
  - Mock implementations for testing
  - Test coverage for critical paths

## Project Structure

```
lib/
├── app/
│   ├── navigator/         # Navigation management
│   └── di/               # Dependency injection setup
├── auth/
│   ├── data/             # Data layer
│   │   ├── datasources/  # Remote and local data sources
│   │   └── repositories/ # Repository implementations
│   ├── domain/           # Domain layer
│   │   ├── models/       # Business models
│   │   ├── repositories/ # Repository interfaces
│   │   └── validators/   # Input validation
│   └── presentation/     # Presentation layer
│       ├── cubit/        # State management
│       ├── screens/      # UI screens
│       └── widgets/      # Reusable widgets
└── core/                 # Core functionality
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- An IDE (VS Code, Android Studio, or IntelliJ)
- lcov (for test coverage visualization)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ngocphule060719/authentication.git
cd authentication
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running Tests

To run all tests:
```bash
flutter test
```

To run tests with coverage and view the report:
```bash
# Make the script executable
chmod +x test_report.sh

# Run the script
./test_report.sh
```
This will:
- Run all tests with coverage
- Generate an HTML coverage report
- Open the report in your default browser

To run specific test files:
```bash
flutter test test/auth/presentation/widgets/login_form_test.dart
flutter test test/auth/presentation/widgets/register_form_test.dart
```

## Testing Strategy

### Widget Tests
- Form validation and user input handling
- UI state management and feedback
- Component interaction and behavior
- Navigation flow verification

### Unit Tests
- Business logic validation
- State management testing
- Data handling and transformation
- Error handling and recovery

### Integration Tests
- End-to-end user flows
- Cross-component interaction
- Data persistence verification

## Test Structure

```
test/
├── auth/                  # Authentication related tests
│   ├── data/             # Data layer tests
│   │   ├── datasources/  # Data source implementation tests
│   │   ├── repositories/ # Repository implementation tests
│   │   └── storage/      # Storage handling tests
│   └── presentation/     # Presentation layer tests
│       ├── cubit/        # State management tests
│       ├── screens/      # Screen widget tests
│       └── widgets/      # Reusable widget tests
└── integration_test/     # End-to-end tests
    └── auth_flow_test.dart
```

## Dependencies

- `flutter_bloc`: State management
- `get`: Dependency injection
- `mockito`: Mocking for tests
- `flutter_secure_storage`: Secure storage for tokens
