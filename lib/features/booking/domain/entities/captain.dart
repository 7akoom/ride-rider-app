/// The captain who took the ride, as the rider sees them.
final class Captain {
  const Captain({
    required this.name,
    this.photoUrl = '',
    this.rating,
    this.make = '',
    this.model = '',
    this.color = '',
    this.plate = '',
  });

  final String name;

  /// A short-lived link to the approved photo; empty without one.
  final String photoUrl;

  /// The average of their ratings; null before anyone rated them.
  final double? rating;

  /// The car, as the captain's documents name it.
  final String make;
  final String model;
  final String color;
  final String plate;

  /// "Toyota Corolla · white": the parts that are known.
  String get car => [
        [make, model].where((part) => part.isNotEmpty).join(' '),
        color,
      ].where((part) => part.isNotEmpty).join(' · ');
}
