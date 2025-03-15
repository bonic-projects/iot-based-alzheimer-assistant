import 'package:flutter/material.dart';
import 'package:alzheimer_assist/ui/views/widgets/ip.dart';
import 'package:stacked/stacked.dart';

import 'hardware_viewmodel.dart';

class HardwareView extends StatelessWidget {
  const HardwareView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HardwareViewModel>.reactive(
      onViewModelReady: (model) => model.onModelReady(),
      builder: (context, model, child) {
        // print(model.node?.lastSeen);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hardware'),
            actions: [
              // IconButton(
              //     onPressed: () {
              //       // Navigator.of(context)
              //       // .push(MaterialPageRoute(builder: (context) => MyApp()));
              //     },
              //     icon: Icon(Icons.speaker),
              // ),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.developer_board, color: Colors.amber),
              ),
            ],
          ),
          floatingActionButton: model.ip != null
              ? FloatingActionButton(
                  onPressed: () {
                    model.work();
                  },
                  tooltip: 'camera',
                  child: Icon(Icons.camera_alt),
                )
              : null,
          body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  if (model.isBusy)
                    const CircularProgressIndicator()
                  else if (model.imageSelected != null &&
                      model.imageSelected!.path != "")
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Image.memory(model.img!
                            // model.imageSelected!.readAsBytesSync(),
                            ),
                      ),
                    )
                  else
                    IpAddressInputWidget(
                      onSetIp: model.setIp,
                      initialIp: model.ip,
                    ),
                  if (model.labels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        model.labels.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // TextButton(
                  //   onPressed: () async {
                  //     await model.getImageFromHardware();
                  //     model.getLabel();
                  //     print("get label");
                  //   },
                  //   child: Text(
                  //     "Get label",
                  //   ),
                  // ),
                ]),
          ),
        );
      },
      viewModelBuilder: () => HardwareViewModel(),
    );
  }
}
