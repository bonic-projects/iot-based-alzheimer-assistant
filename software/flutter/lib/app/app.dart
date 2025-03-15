import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_firebase_auth/stacked_firebase_auth.dart';
import 'package:stacked_services/stacked_services.dart';

import '../services/camera_service.dart';
import '../services/firestore_service.dart';
import '../services/imageprocessing_service.dart';
import '../services/location_service.dart';
import '../services/regula_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/user_service.dart';
import '../ui/bottom_sheets/notice/notice_sheet.dart';
import '../ui/dialogs/info_alert/info_alert_dialog.dart';
import '../ui/views/face/facerec_view.dart';
import '../ui/views/hardware/hardware_view.dart';
import '../ui/views/home/home_view.dart';
import '../ui/views/inapp/inapp_view.dart';
import '../ui/views/login/login_view.dart';
import '../ui/views/login_register/login_register_view.dart';
import '../ui/views/map/map_view.dart';
import '../ui/views/register/register_view.dart';
import '../ui/views/startup/startup_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginRegisterView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: RegisterView),
    MaterialRoute(page: InAppView),
    MaterialRoute(page: FaceRecView),
    MaterialRoute(page: MapView),
    MaterialRoute(page: HardwareView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: FirebaseAuthenticationService),
    LazySingleton(classType: FirestoreService),
    LazySingleton(classType: UserService),
    LazySingleton(classType: StorageService),
    LazySingleton(classType: TTSService),
    LazySingleton(classType: ImageProcessingService),
    LazySingleton(classType: RegulaService),
    LazySingleton(classType: LocationService),
    LazySingleton(classType: CameraService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
  logger: StackedLogger(),
)
class App {}
