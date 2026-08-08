/// Monitors device location against pending reminders.
///
/// Concrete implementation will be provided by the location-monitor sub-ticket.
abstract class LocationMonitorService {
  Future<void> startMonitoring();
}

/// No-op monitor used until background proximity monitoring is implemented.
class StubLocationMonitorService implements LocationMonitorService {
  @override
  Future<void> startMonitoring() async {}
}
