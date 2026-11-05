import 'package:mobile/core/location/location_provider.dart';

/// The sentence for a [LocationFailure], shown in a snackbar or under a field
/// (the quick butterfly sheet and the plant form, T052).
String locationMessage(LocationFailure failure) => switch (failure) {
  LocationFailure.serviceOff => 'Location is off, please turn it on.',
  LocationFailure.denied => 'Location permission was not given.',
  LocationFailure.deniedForever =>
    'Location permission is blocked. Allow it in Android settings.',
  LocationFailure.unavailable => 'No GPS fix yet. Try again outside.',
};
