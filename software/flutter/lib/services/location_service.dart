import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app/app.locator.dart';
import '../app/app.logger.dart';
import 'firestore_service.dart';
import 'user_service.dart';
import 'package:rxdart/rxdart.dart';

class LocationService {
  final log = getLogger('LocationService');
  final _firestoreService = locator<FirestoreService>();
  final _userService = locator<UserService>();

  // Stream controllers for alerts
  final _bystanderAlertController = BehaviorSubject<String>();
  final _locationAlertController = BehaviorSubject<String>();
  Stream<String> get bystanderAlerts => _bystanderAlertController.stream;
  Stream<String> get locationAlerts => _locationAlertController.stream;

  late Position _currentPosition;
  late String _currentPlace;
  Timer? _locationUpdateTimer;
  Timer? _reminderTimer;
  bool _isMessageShown = false;
  bool _is5KmAlertShown = false;
  bool _isAwayFromHomeAlertShown = false;

  // Initialize the service
  Future<void> initialise() async {
    if (_locationUpdateTimer != null && _locationUpdateTimer!.isActive) {
      log.w("Location update timer is already running. Skipping reinitialization.");
      return;
    }

    log.i("Initializing LocationService...");
    await getLocation();

    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (Timer timer) async {
      await getLocation();
    });
  }

  Future<void> getLocation() async {
    try {
      log.i("Getting location...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _bystanderAlertController.add("Location services are not enabled");
        _locationAlertController.add("Location services are not enabled");
        return;
      }

      if (!await checkAndRequestPermissions()) {
        _bystanderAlertController.add("Location permissions not granted");
        _locationAlertController.add("Location permissions not granted");
        return;
      }

      // Check if home location is set
      if (_userService.user?.homeLat == null || _userService.user?.homeLong == null) {
        log.w("Home location is not set");
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      _currentPlace = "${place.name ?? 'Unknown'}, ${place.locality ?? 'Unknown'}";

      await _firestoreService.updateLocation(
          _currentPosition.latitude, _currentPosition.longitude, _currentPlace);

      // Check distance from home
      double distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          _userService.user!.homeLat,
          _userService.user!.homeLong);

      log.i("Distance from home: $distance meters");

      // Trigger state change logic
      onStateChange(distance <= 30);
      checkIf5KmAway(distance);
      checkIfAwayFromHome(distance);

    } catch (e) {
      log.e("Error occurred while getting location: $e");
      _bystanderAlertController.add("Error getting location: $e");
      _locationAlertController.add("Error getting location: $e");
    }
  }

  void checkIfAwayFromHome(double distance) {
    if (distance > 1000 && !_isAwayFromHomeAlertShown) {
      log.i("Patient is away from home. Showing alert.");
      _isAwayFromHomeAlertShown = true;
      _showAwayFromHomeAlert();
    } else if (distance <= 1000 && _isAwayFromHomeAlertShown) {
      log.i("Patient returned home. Resetting alert state.");
      _isAwayFromHomeAlertShown = false;
      _showReturnedHomeAlert();
    }
  }

  void _showAwayFromHomeAlert() {
    _locationAlertController.add("Alert: You are away from your home location!");
    // _bystanderAlertController.add("Alert: Patient has left home location");
  }

  void _showReturnedHomeAlert() {
    _locationAlertController.add("Welcome back home!");
  }


  void checkIf5KmAway(double distance) {
    if (distance >= 5000 && !_is5KmAlertShown) {
      log.i("Patient is 5 km away. Showing alert.");
      _is5KmAlertShown = true;
      _show5KmAlert();
    } else if (distance < 5000 && _is5KmAlertShown) {
      log.i("Patient is within 5 km. Resetting alert state.");
      _is5KmAlertShown = false;
    }
  }

  void _show5KmAlert() {
    _bystanderAlertController.add("Alert: Patient is 5 km away from the set location!");

    Timer(const Duration(seconds: 10), () {
      _is5KmAlertShown = false;
    });
  }

  Future<bool> checkAndRequestPermissions() async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      log.e("Location permission is permanently denied.");
      return false;
    }

    return status.isGranted;
  }

  void onStateChange(bool isInSafeZone) {
    if (!isInSafeZone && !_isMessageShown) {
      _reminderTimer = Timer(const Duration(minutes: 1), () {
        if (!isInSafeZone) {
          _showMessage();
        }
        _reminderTimer = null;
      });
    } else if (isInSafeZone && _reminderTimer != null) {
      _reminderTimer?.cancel();
      _reminderTimer = null;
    }
  }

  void _showMessage() {
    _isMessageShown = true;
    // _locationAlertController.add("Reminder: Wear your glasses!");

    Timer(const Duration(seconds: 10), () {
      _isMessageShown = false;
    });
  }

  void dispose() {
    _locationUpdateTimer?.cancel();
    _reminderTimer?.cancel();
    _locationAlertController.close();
    _bystanderAlertController.close();
  }
}