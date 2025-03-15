import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../models/appuser.dart';
import '../../../models/reminder.dart';
import '../../../services/firestore_service.dart';
import '../../../services/location_service.dart';

class MapViewModel extends BaseViewModel {
  final log = getLogger('MapViewModel');
  final _firestoreService = locator<FirestoreService>();
  final _snackBarService = locator<SnackbarService>();
  final _locationService = locator<LocationService>();

  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  StreamSubscription<String>? _locationAlertSubscription;

  // Getter for current location with null safety
  double get latitude => _currentLocation?.latitude ?? 0.0;
  double get longitude => _currentLocation?.longitude ?? 0.0;

  AppUser? _user;
  AppUser? get user => _user;

  // Alert handling
  List<String> _alerts = [];
  List<String> get alerts => _alerts;

  void onModelReady(AppUser user) async {
    await getUserLocation(user);
    _setupLocationAlerts();
  }

  Future<void> getUserLocation(AppUser user) async {
    setBusy(true);
    try {
      _user = await _firestoreService.getUser(userId: user.id);
      if (_user != null) {
        _currentLocation = LatLng(_user!.latitude, _user!.longitude);

        // Only update camera if controller is initialized
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 15.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      log.e('Error getting user location: $e');
      _snackBarService.showSnackbar(message: 'Error loading location');
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  void _setupLocationAlerts() {
    _locationAlertSubscription = _locationService.bystanderAlerts.listen((alert) {
      _alerts.add(alert);
      notifyListeners();
    });
  }

  void setReminder({required Reminder reminder}) {
    log.i('New Reminder: ${reminder.message}');
    String? id = _firestoreService.generateReminderDocumentId(_user!.id);
    if (id != null) {
      reminder.id = id;
      _firestoreService.addReminder(_user!.id, reminder);
      _snackBarService.showSnackbar(message: "Reminder added");
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // If we already have a location, update the camera
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
    notifyListeners();
  }

  void dismissAlert(int index) {
    if (index >= 0 && index < _alerts.length) {
      _alerts.removeAt(index);
      notifyListeners();
    }
  }

  void dismissLatestAlert() {
    if (_alerts.isNotEmpty) {
      _alerts.removeLast();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationAlertSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}