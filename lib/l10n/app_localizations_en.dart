// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Assistant App';

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
  String get assistant => 'Assistant';

  @override
  String get assistantProcessing => 'Thinking...';

  @override
  String get assistantSpeaking => 'Speaking...';

  @override
  String get assistantListening => 'Listening…';

  @override
  String get assistantTapToSpeak => 'Tap to speak';

  @override
  String get assistantWidgetSignInRequired =>
      'Sign in to use the assistant widget';

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

  @override
  String get wakeWord => 'Wake word';

  @override
  String get activeListening => 'Active listening';

  @override
  String get activeListeningSubtitle =>
      'Runs a low-power on-device listener for your wake word. Minimal battery impact.';

  @override
  String get wakeWordRequired => 'Wake word cannot be empty';

  @override
  String get wakeWordFixedNotice =>
      'Custom wake words aren\'t supported yet — active listening only responds to \"Jarvis\".';

  @override
  String listeningForWakeWord(String wakeWord) {
    return 'Listening for $wakeWord…';
  }

  @override
  String get assistantSettingsSaveFailed =>
      'Could not save settings. Showing cached values.';

  @override
  String get locationReminderDistance => 'Location reminder distance';

  @override
  String locationReminderDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String get plugins => 'Plugins';

  @override
  String get managePlugins => 'Manage Plugins';

  @override
  String get pluginsInstalledTab => 'Installed';

  @override
  String get pluginsAvailableTab => 'Available';

  @override
  String get pluginStore => 'Plugin Store';

  @override
  String get myPlugins => 'My Plugins';

  @override
  String get install => 'Install';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get enabled => 'Enabled';

  @override
  String get pluginStoreEmpty => 'No plugins available yet.';

  @override
  String get noPluginsInstalled => 'No plugins installed';

  @override
  String get noPluginsInstalledSubtitle =>
      'Browse the plugin store to extend your assistant.';

  @override
  String get browsePluginStore => 'Browse Plugin Store';

  @override
  String get pluginLoadFailed => 'Could not load plugins. Please try again.';

  @override
  String get pluginActionFailed => 'Something went wrong. Please try again.';

  @override
  String pluginInstalled(String name) {
    return '$name installed';
  }

  @override
  String pluginUninstalled(String name) {
    return '$name uninstalled';
  }

  @override
  String get uninstallPlugin => 'Uninstall plugin?';

  @override
  String uninstallPluginConfirm(String name) {
    return 'Remove $name from your assistant?';
  }

  @override
  String get setupNotStarted => 'Setup needed';

  @override
  String get setupInProgress => 'Setup in progress';

  @override
  String get setupCompleted => 'Ready';

  @override
  String get setupFailed => 'Setup failed';

  @override
  String get pluginSetup => 'Plugin Setup';

  @override
  String get pluginOAuthSetupInstructions =>
      'Connect your Google account so this plugin can access your calendar and related services.';

  @override
  String get pluginSetupInstructions =>
      'Connect your Google account so this plugin can access your calendar and related services.';

  @override
  String get pluginFormSetupInstructions =>
      'Paste your API key from your Composio dashboard. Connected apps are discovered automatically.';

  @override
  String get pluginSetupApiKeyRequired => 'API key required';

  @override
  String get pluginSetupOAuthRequired => 'Account connection required';

  @override
  String get composioApiKeyLabel => 'Composio API key';

  @override
  String get composioApiKeyRequired => 'API key is required';

  @override
  String get composioConnectedApps => 'Connected apps';

  @override
  String get composioNoConnectedApps =>
      'No apps connected yet. Connect apps in your Composio dashboard to use them here.';

  @override
  String get composioConnectApps => 'Connect apps in Composio';

  @override
  String get composioDashboardUrl => 'https://app.composio.dev';

  @override
  String get done => 'Done';

  @override
  String get saveApiKey => 'Save API key';

  @override
  String get connectGoogleAccount => 'Connect Google Account';

  @override
  String get pluginSetupWaiting => 'Waiting for authorization…';

  @override
  String get pluginSetupSuccess =>
      'Setup complete! This plugin is ready to use.';

  @override
  String get pluginSetupFailed => 'Setup could not be completed.';

  @override
  String get pluginSetupRetry => 'Try again';

  @override
  String get pluginsSetupIncompleteBanner =>
      'Some plugins need setup before they can be used.';

  @override
  String get assistantCompleteSetup => 'Complete setup';

  @override
  String get assistantManagePlugins => 'Manage plugins';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get reminderNotificationsTitle => 'Reminder notifications';

  @override
  String get reminderNotificationsDescription =>
      'Reminder notifications are enabled when the Reminder plugin is installed. The app syncs reminders from your account and shows local alerts at the scheduled time.';

  @override
  String get reminderNotificationsRequestPermission =>
      'Check notification permission';

  @override
  String get reminderNotificationsPermissionRequested =>
      'Notification permission checked. Reminders will sync when allowed.';
}
