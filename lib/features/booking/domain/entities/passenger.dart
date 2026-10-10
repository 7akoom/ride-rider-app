/// Who the captain picks up when the rider books for someone else. The rider still
/// pays; the captain sees the name and number once the trip is accepted.
final class Passenger {
  const Passenger({required this.name, required this.phone});

  final String name;

  /// International form: +9647501234567.
  final String phone;

  /// The backend's limit for the name.
  static const int maxNameLength = 80;
}
