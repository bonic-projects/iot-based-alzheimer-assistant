import 'package:alzheimer_assist/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../services/regula_service.dart';
import '../../../services/user_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final RegulaService _regulaService = RegulaService();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    if (_userService.hasLoggedInUser) {
      await _userService.fetchUser();
      _navigationService.replaceWithHomeView();
    } else {
      await Future.delayed(const Duration(seconds: 1));
      _navigationService.replaceWithLoginRegisterView();
    }
    _regulaService.initPlatformState();
  }
}
