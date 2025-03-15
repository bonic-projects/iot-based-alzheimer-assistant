import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:alzheimer_assist/models/reminder.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.bottomsheets.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../app/app.router.dart';
import '../../../models/appuser.dart';
import '../../../services/firestore_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/user_service.dart';
import '../../../services/location_service.dart'; // Import the LocationService
import '../../common/app_strings.dart';

class HomeViewModel extends StreamViewModel<List<Reminder>> {
  final log = getLogger('HomeViewModel');
  final _dialogService = locator<DialogService>();
  final _snackBarService = locator<SnackbarService>();
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final _firestoreService = locator<FirestoreService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final TTSService _ttsService = locator<TTSService>();
  final _locationService = locator<LocationService>(); // Add LocationService

  StreamSubscription? _locationAlertSubscription;
  StreamSubscription? _bystanderAlertSubscription;
  @override
  Stream<List<Reminder>> get stream => _firestoreService.getRemindersStream();

  AppUser? get user => _userService.user;

  late Timer _reminderTimer;

  void onModelRdy() async {
    log.i("started");
    setBusy(true);
    if (user == null) {
      await _userService.fetchUser();
    }
    if (user!.userRole == "bystander") {
      await getPatients();
      _subscribeToBystanderAlerts();
    } else {
      startReminderCheck();
      await _locationService.initialise(); // Initialize LocationService
      _subscribeToLocationAlerts();
    }
    setBusy(false);
  }
  void _subscribeToLocationAlerts() {
    _locationAlertSubscription = _locationService.locationAlerts.listen((alert) {
      // Show snackbar for visual alert
      _snackBarService.showSnackbar(message: alert);
      // Speak the alert for audio notification
      _ttsService.speak(alert);
    });
  }

  void _subscribeToBystanderAlerts() {
    _bystanderAlertSubscription = _locationService.bystanderAlerts.listen((alert) {
      // Show snackbar for visual alert
      _snackBarService.showSnackbar(
        message: alert,
        duration: const Duration(seconds: 5),
      );
    });
  }
  List<AppUser> _patients = <AppUser>[];

  List<AppUser> get patients => _patients;

  Future getPatients() async {
    _patients = await _firestoreService.getUsersWithBystander();
    log.i("Users count: ${_patients.length}");
  }

  void openInAppView() {
    _navigationService.navigateTo(Routes.inAppView);
  }

  void openHardwareView() {
    _navigationService.navigateTo(Routes.hardwareView);
  }

  void openFaceTrainView() {
    _navigationService.navigateTo(Routes.faceRecView);
  }

  void openFaceTestView() {
    // _navigationService.navigateTo(Routes.faceTest);
  }

  void setPickedLocation(LatLng latLng) {
    _firestoreService.updateHomeLocation(latLng.latitude, latLng.longitude);
    _userService.fetchUser();
    _snackBarService.showSnackbar(message: "Home location set");
  }

  void onDelete(Reminder reminder) async {
    log.i("DELETE");
    log.i(reminder.id);
    await _firestoreService.deleteReminder(user!.id, reminder.id);
    _snackBarService.showSnackbar(message: "Reminder deleted");
  }

  Future<void> logout() async {
    DialogResponse? response = await _dialogService.showConfirmationDialog(
      title: 'Logout',
      description: 'Are you sure you want to logout?',
      confirmationTitle: 'Yes',
      cancelTitle: 'No',
    );

    if (response != null && response.confirmed) {
      setBusy(true);
      await _userService.logout();
      _navigationService.replaceWithLoginRegisterView();
      setBusy(false);
    }
  }

  void showBottomSheetUserSearch() async {
    final result = await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
    if (result != null) {
      if (result.confirmed) {
        log.i("Bystander added: ${result.data.fullName}");
        _snackBarService.showSnackbar(
            message: "${result.data.fullName} added as bystander");
      }
    }
  }

  void openMapView(AppUser user) {
    _navigationService.navigateToMapView(user: user);
  }

  // Method to start checking for reminders
  void startReminderCheck() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      checkReminders();
    });
  }

  void stopReminderCheck() {
    _reminderTimer.cancel();
  }

  void checkReminders() {
    if (data != null) {
      final DateTime currentTime = DateTime.now();
      for (Reminder reminder in data!) {
        if (currentTime.hour == reminder.dateTime.hour &&
            currentTime.minute == reminder.dateTime.minute) {
          handleReminderReachedTime(reminder);
        }
      }
    }
  }

  void handleReminderReachedTime(Reminder reminder) async {
    log.i('Reminder reached time: ${reminder.message}');
    await _ttsService.speak("Reminder: ${reminder.message}");
  }
  @override
  void dispose() {
    _reminderTimer.cancel();
    _locationAlertSubscription?.cancel();
    _bystanderAlertSubscription?.cancel();
    super.dispose();
  }
}