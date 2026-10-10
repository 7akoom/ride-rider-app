import '../../../../core/phone/phone_number.dart';
import '../entities/passenger.dart';

enum PassengerProblem { nameMissing, nameTooLong, phoneInvalid }

/// The passenger from what the rider typed, or what is wrong with it.
sealed class PassengerCheck {
  const PassengerCheck();
}

final class PassengerOk extends PassengerCheck {
  const PassengerOk(this.passenger);

  final Passenger passenger;
}

final class PassengerWrong extends PassengerCheck {
  const PassengerWrong(this.problems);

  final Set<PassengerProblem> problems;
}

/// Name and number go together: both are needed, the name within the backend's
/// limit, the number a mobile number of the copy's country.
PassengerCheck checkPassenger(String name, String phone) {
  final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  final number = PhoneNumber.tryParse(phone);
  final problems = {
    if (trimmed.isEmpty) PassengerProblem.nameMissing,
    if (trimmed.runes.length > Passenger.maxNameLength) PassengerProblem.nameTooLong,
    if (number == null) PassengerProblem.phoneInvalid,
  };

  return problems.isEmpty
      ? PassengerOk(Passenger(name: trimmed, phone: number!.e164))
      : PassengerWrong(problems);
}
