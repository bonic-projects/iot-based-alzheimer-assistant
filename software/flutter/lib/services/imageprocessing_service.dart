import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../app/app.logger.dart';

class ImageProcessingService {
  final log = getLogger('ImageProcessing_Service');

  Future<List<String>> getTextFromImage(File image) async {
    log.i("Getting label");
    final labels0 = <String>[];

    final inputImage = InputImage.fromFilePath(image.path);
    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.5);
    final imageLabeler = ImageLabeler(options: options);

    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

    for (ImageLabel label in labels) {
      final String text = label.label;
      final int index = label.index;
      final double confidence = label.confidence;
      log.i("$index $text $confidence");
      // if (confidence > 0.65) {
      labels0.add(text);
      // }
    }

    imageLabeler.close();

    return labels0;
  }

  final List<String> _personLabels = [
    'Smile',
    'Fun',
    'Mouth',
    'Selfie',
    'Eyelash',
    'Beard',
    'Hand',
    'Moustache',
    'Skin',
    'Cool',
    'Ear',
    'Hair',
    'Dude',
  ];

  String processLabels(List<String> labeles) {
    if (labeles.isEmpty) return "Not recognized";
    check(String value) => labeles.contains(value);
    bool res = _personLabels.any(check); // returns true
    if (res) {
      return "Person detected";
    } else {
      if (labeles.contains("Dog")) labeles.remove("Dog");
      if (labeles.contains("Musical instrument")) {
        labeles.remove("Musical instrument");
      }
      if (labeles.isNotEmpty) {
        String text = labeles.first;
        return text;
      } else {
        return "";
      }
    }
  }
}
