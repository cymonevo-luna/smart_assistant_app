import '../assistant/models/assistant_reply.dart';
import '../location/location_service.dart';
import 'data/reminder_api_repository.dart';
import 'data/reminder_repository.dart';
import 'location_monitor_service.dart';
import 'models/location_reminder.dart';

/// Called before the OS location permission dialog so the user knows why.
typedef OnLocationPermissionExplanationNeeded = void Function(String message);

/// Registers location reminders from assistant action results and syncs pending
/// reminders from the API on startup.
class ReminderRegistrationService {
  ReminderRegistrationService({
    required ReminderRepository reminderRepository,
    required ReminderApiRepository reminderApiRepository,
    required LocationService locationService,
    required LocationMonitorService locationMonitorService,
    OnLocationPermissionExplanationNeeded? onPermissionExplanationNeeded,
  })  : _reminderRepository = reminderRepository,
        _reminderApiRepository = reminderApiRepository,
        _locationService = locationService,
        _locationMonitorService = locationMonitorService {
    _onPermissionExplanationNeeded = onPermissionExplanationNeeded;
  }

  final ReminderRepository _reminderRepository;
  final ReminderApiRepository _reminderApiRepository;
  final LocationService _locationService;
  final LocationMonitorService _locationMonitorService;
  OnLocationPermissionExplanationNeeded? _onPermissionExplanationNeeded;

  static const _locationReminderSlugs = {'set-reminder', 'location-reminder'};

  static const locationPermissionExplanation =
      'Location access is needed to alert you when you arrive at your reminder.';

  /// Binds a UI handler for the pre-permission explanation snackbar/dialog.
  set onPermissionExplanationNeeded(
    OnLocationPermissionExplanationNeeded? handler,
  ) {
    _onPermissionExplanationNeeded = handler;
  }

  /// Handles a successful assistant action result for location reminders.
  Future<void> handleActionResult(AssistantAction action) async {
    if (!_isLocationReminderAction(action)) {
      return;
    }

    final payload = action.payload;
    if (payload == null) {
      return;
    }

    final reminder = LocationReminder.fromJson(payload);
    await _reminderRepository.save(reminder);
    await _ensureLocationPermission();
    await _locationMonitorService.startMonitoring();
  }

  /// Fetches pending reminders from the API and merges them into local storage.
  Future<void> syncPendingFromApi() async {
    final reminders = await _reminderApiRepository.fetchPending();
    await _reminderRepository.syncFromApi(reminders);
  }

  bool _isLocationReminderAction(AssistantAction action) {
    if (action.status != 'success') {
      return false;
    }

    final slug = action.pluginSlug;
    if (slug == null || !_locationReminderSlugs.contains(slug)) {
      return false;
    }

    return action.payload != null;
  }

  Future<void> _ensureLocationPermission() async {
    if (await _locationService.hasLocationPermission()) {
      return;
    }

    _onPermissionExplanationNeeded?.call(locationPermissionExplanation);
    await _locationService.requestPermission();
  }
}
