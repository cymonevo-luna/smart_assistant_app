// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'App Template';

  @override
  String get appTagline => 'Tagline goes here';

  @override
  String get home => 'Home';

  @override
  String get tasks => 'Tasks';

  @override
  String get calendar => 'Calendar';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get overview => 'Overview';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View all';

  @override
  String get themeColor => 'Theme Color';

  @override
  String get language => 'Language';

  @override
  String greeting(String name) {
    return 'Good morning, $name';
  }

  @override
  String get haveAGreatDay => 'Have a great day!';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue to your account';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get register => 'Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToGetStarted => 'Sign up to get started';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signIn => 'Sign In';

  @override
  String get settings => 'Settings';

  @override
  String get myProfile => 'My Profile';

  @override
  String get achievements => 'Achievements';

  @override
  String get activityHistory => 'Activity History';

  @override
  String get savedItems => 'Saved Items';

  @override
  String get projects => 'Projects';

  @override
  String get completed => 'Completed';

  @override
  String get account => 'Account';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get security => 'Security';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get logout => 'Log out';

  @override
  String get english => 'English';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
}
