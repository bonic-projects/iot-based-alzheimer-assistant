import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../models/appuser.dart';
import '../../../services/firestore_service.dart';
import '../../../services/user_service.dart';

class NoticeSheetModel extends BaseViewModel {
  final log = getLogger('NoticeSheetModel');

  final _firestoreService = locator<FirestoreService>();
  final _userService = locator<UserService>();

  List<AppUser> _users = [];

  List<AppUser> get users => _users;

  final TextEditingController messageController = TextEditingController();

  Future<void> searchUsers(String keyword) async {
    if (keyword.isNotEmpty) {
      setBusy(true);
      log.i("getting users");
      try {
        _users = await _firestoreService.searchUsers(keyword);
        log.i(_users.length);
        _users = _users
            .where((element) => element.id != _userService.user!.id)
            .toList();
        setError(null);
      } catch (e) {
        setError(e.toString());
      }

      setBusy(false);
    }
  }

  AppUser? _user;

  AppUser? get user => _user;

  Future<bool> setUser(AppUser user) {
    _user = user;
    messageController.clear();
    notifyListeners();
    return addBystander();
  }

  Future<bool> addBystander() async {
    return _firestoreService.updateBystander(_user!.id);
  }
}
