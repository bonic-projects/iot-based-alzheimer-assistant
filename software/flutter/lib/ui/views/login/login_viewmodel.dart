import 'package:stacked/stacked.dart';
import 'package:stacked_firebase_auth/stacked_firebase_auth.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../app/app.router.dart';
import '../../../services/user_service.dart';
import 'login_view.form.dart';

class LoginViewModel extends FormViewModel {
  final log = getLogger('LoginViewModel');

  final FirebaseAuthenticationService _firebaseAuthenticationService =
      locator<FirebaseAuthenticationService>();
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final _snackBarService = locator<SnackbarService>();

  void onModelReady() {}

  void authenticateUser() async {
    if (isFormValid && emailValue != null && passwordValue != null) {
      setBusy(true);
      log.i("email and pass valid");
      log.i(emailValue!);
      log.i(passwordValue!);
      FirebaseAuthenticationResult result =
          await _firebaseAuthenticationService.loginWithEmail(
        email: emailValue!,
        password: passwordValue!,
      );
      if (result.user != null) {
        _userService.fetchUser();
        _navigationService.pushNamedAndRemoveUntil(Routes.homeView);
      } else {
        log.e("Error: ${result.errorMessage}");

        _snackBarService.showSnackbar(
            message:
                "Error: ${result.errorMessage ?? "Enter valid credentials"}");
      }
    }
    setBusy(false);
  }
}
