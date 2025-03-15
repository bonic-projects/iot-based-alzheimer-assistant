import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'inapp_viewmodel.dart';

class InAppView extends StatelessWidget {
  const InAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<InAppViewModel>.reactive(
      onViewModelReady: (model) => model.onModelReady(),
      builder: (context, model, child) {
        // print(model.node?.lastSeen);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Smartphone'),
            actions: [
              IconButton(
                onPressed: () {
                  print("icon b");
                  model.speak("This is test speech output");
                },
                icon: const Icon(Icons.volume_up),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () {
                  // model.getImageCamera();
                  model.captureImageAndLabel();
                },
                tooltip: 'camera',
                heroTag: null,
                child: Icon(Icons.add_a_photo),
              ),
              SizedBox(width: 10),
              FloatingActionButton(
                onPressed: () {
                  model.getImageGallery();
                },
                tooltip: 'gallery',
                heroTag: null,
                child: Icon(Icons.image),
              )
            ],
          ),
          body: model.isBusy
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Container(
                    child: model.imageSelected != null
                        ? Column(
                            children: [
                              Expanded(child: Image.file(model.imageSelected!)),
                              if (model.labels.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    model.labels.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              // Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: IconButton(
                              //     icon: Icon(Icons.volume_down_outlined),
                              //     onPressed: model.getLabel,
                              //   ),
                              // ),
                              TextButton(
                                onPressed: () {
                                  model.getLabel();
                                  // print("get label");
                                },
                                child: const Text(
                                  "Get label",
                                ),
                              ),
                            ],
                          )
                        : CameraPreview(model.controller),

                    // const Text("No images selected!")
                  ),
                ),
        );
      },
      viewModelBuilder: () => InAppViewModel(),
    );
  }
}
