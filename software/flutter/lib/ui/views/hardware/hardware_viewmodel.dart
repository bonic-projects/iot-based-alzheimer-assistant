import 'dart:async';
import 'dart:convert'; // For JSON decoding
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart'; // Updated import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../services/imageprocessing_service.dart';
import '../../../services/location_service.dart';
import '../../../services/regula_service.dart';
import '../../../services/tts_service.dart';

class HardwareViewModel extends BaseViewModel {
  final log = getLogger('HardwareViewModel');

  final _snackBarService = locator<SnackbarService>();
  final TTSService _ttsService = locator<TTSService>();
  final ImageProcessingService _imageProcessingService =
  locator<ImageProcessingService>();
  final _locService = locator<LocationService>();
  final _ragulaService = locator<RegulaService>();

  File? _image;
  File? get imageSelected => _image;

  List<String> _labels = <String>[];
  List<String> get labels => _labels;

  late String _ip='192.168.29.105';
  String get ip => _ip;

  static const String _ipKey = 'saved_ip';
  late StreamSubscription<double> _volumeSubscription;
  late Timer _wearCheckTimer;
  bool _isListeningToWear = false;
  bool _wearStatus = true;

  @override
  void dispose() {
    _volumeSubscription.cancel();
    _locService.dispose();
    _wearCheckTimer.cancel();
    super.dispose();
  }

  void onModelReady() async {
    setBusy(true);
    log.i("Model ready");

    _locService.initialise();

    // Load the saved IP address
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _ip = prefs.getString(_ipKey) ?? '';
    log.i("Loaded IP: $_ip");

    setBusy(false);

    // Updated volume subscription using flutter_volume_controller
    _volumeSubscription = FlutterVolumeController.addListener((volume) {
      if (_image != null && !isBusy) {
        log.i("Volume button got!");
        work();
      }
    });
  }

  void setIp(String ipIn) async {
    log.i("Setting IP: $ipIn");
    _ip = ipIn;

    // Save the IP address
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _ip);
    log.i("Saved IP: $_ip");

    notifyListeners();
    _startListeningToWear();
  }

  void _startListeningToWear() {
    if (_isListeningToWear) return;

    _isListeningToWear = true;
    int falseCount = 0;

    _wearCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        Uri uri = Uri(
          scheme: 'http',
          host: _ip,
          path: '/switch',
        );

        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _wearStatus = data['wear'] == true;

          if (!_wearStatus) {
            falseCount += 5; // Increment by 5 seconds per timer tick
            if (falseCount >= 60) {
              _snackBarService.showSnackbar(
                message: "Not wearing glasses for 1 minute.",
                duration: Duration(seconds: 5),
              );
             await _ttsService.speak("Not wearing glasses for 1 minute");
              falseCount = 0;
            }
          } else {
            falseCount = 0; // Reset counter if wear is true
          }
        } else {
          log.w("Failed to fetch /switch endpoint: ${response.statusCode}");
        }
      } catch (e) {
        log.e("Error checking wear status: $e");
        _stopListeningToWear();
      }
    });
  }

  void _stopListeningToWear() {
    if (!_isListeningToWear) return;

    _isListeningToWear = false;
    _wearCheckTimer.cancel();
  }

  void work() async {
    setBusy(true);
    await getImageFromHardware();
    if (_image != null) await getLabel();
  }

  Future getLabel() async {
    log.i("Getting label");
    _labels = <String>[];

    _labels = await _imageProcessingService.getTextFromImage(_image!);

    setBusy(false);

    String text = _imageProcessingService.processLabels(_labels);
    if (text == "Person detected") {
      await _ttsService.speak(text);
      await Future.delayed(const Duration(milliseconds: 2000));
      return processFace();
    }
  }

  void processFace() async {
    _ttsService.speak("Identifying person");
    setBusy(true);
    String? person = await _ragulaService.checkMatch(_image!.path);
    setBusy(false);
    if (person != null) {
      _labels.clear();
      _labels.add(person);
      notifyListeners();
      await _ttsService.speak(person);
      await Future.delayed(const Duration(milliseconds: 1500));
    } else {
      await _ttsService.speak("Not identified!");
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    log.i("Person: $person");
  }

  Uint8List? _img;
  Uint8List? get img => _img;

  Future getImageFromHardware() async {
    log.i("Calling..");

    Uri uri = Uri(
      scheme: 'http',
      host: _ip,
      path: '/snapshot',
    );

    try {
      http.Response response = await http.get(uri);
      log.i("Status Code: ${response.statusCode}");
      log.i("Content Length: ${response.contentLength}");

      _img = response.bodyBytes;

      if (_image != null) {
        _image!.delete();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        _image = await File('${directory.path}/image.png').create();
      }
      return _image!.writeAsBytes(_img!);
    } catch (e) {
      log.i("Error: $e");
    }
  }
}