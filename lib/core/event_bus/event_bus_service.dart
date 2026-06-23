import 'package:event_bus/event_bus.dart';

/// Global EventBus instance for cross-module communication.
class EventBusService {
  static final EventBus _eventBus = EventBus();

  /// Gets the global event bus instance
  static EventBus get instance => _eventBus;

  /// Fire an event on the event bus
  static void fire(dynamic event) {
    _eventBus.fire(event);
  }

  /// Listen to a specific event type
  static Stream<T> on<T>() {
    return _eventBus.on<T>();
  }
}

/// Base event class for Mage-chan events
abstract class MageEvent {}

/// Example Event: Notification Received
class NotificationReceivedEvent extends MageEvent {
  final String title;
  final String body;

  NotificationReceivedEvent(this.title, this.body);
}

/// Example Event: Reminder Triggered
class ReminderTriggeredEvent extends MageEvent {
  final String reminderId;
  final String message;

  ReminderTriggeredEvent(this.reminderId, this.message);
}
