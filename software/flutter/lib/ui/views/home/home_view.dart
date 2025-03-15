import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/src/types/marker.dart'
    as GoogleMapsMarker;
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';

import '../../../models/reminder.dart';
import '../../common/app_colors.dart';
import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      onViewModelReady: (model) => model.onModelRdy(),
      builder: (context, model, child) {
        // print(model.node?.lastSeen);
        return Scaffold(
          appBar: AppBar(
            title: Text(
                'AlzheimerAssist${model.user != null && model.user!.userRole == "bystander" ? "- Bystander" : "- Patient"}'),
            actions: [
              if (model.user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: model.user!.photoUrl != ""
                        ? NetworkImage(model.user!.photoUrl)
                        : null,
                    child: model.user!.photoUrl == ""
                        ? Text(model.user!.fullName[0])
                        : null,
                  ),
                ),
              if (model.user != null)
                IconButton(
                  onPressed: model.logout,
                  icon: const Icon(Icons.logout),
                )
            ],
          ),
          floatingActionButton:
              model.user != null && model.user!.userRole == "patient"
                  ? FloatingActionButton.extended(
                      backgroundColor: kcPrimaryColor.withOpacity(0.5),
                      onPressed: model.showBottomSheetUserSearch,
                      label: const Row(
                        children: [
                          Text('Add bystander  '),
                          Icon(Icons.add_circle),
                        ],
                      ),
                    )
                  : null,
          body: Column(
            children: [
              Expanded(
                child: !model.isBusy && model.user?.userRole == 'patient'
                    ? Column(
                        children: [
                          Expanded(
                            flex: 4,
                            child: GridView.count(
                              crossAxisCount: 2,
                              children: [
                                Option(
                                    name: 'In App',
                                    onTap: model.openInAppView,
                                    file: 'assets/lottie/inapp.json'),
                                Option(
                                    name: 'Hardware',
                                    onTap: model.openHardwareView,
                                    file: 'assets/lottie/hardware.json'),
                                Option(
                                    name: 'Face Train',
                                    onTap: model.openFaceTrainView,
                                    file: 'assets/lottie/face.json'),
                                Option(
                                    name: 'Set home',
                                    onTap: () async {
                                      LatLng? pickedLocation =
                                          await showModalBottomSheet(
                                        context: context,
                                        builder: (context) =>
                                            const LocationPickerBottomSheet(),
                                      );

                                      if (pickedLocation != null) {
                                        model.setPickedLocation(pickedLocation);
                                      }
                                    },
                                    file: 'assets/lottie/map.json')
                              ],
                            ),
                          ),
                          if (model.dataReady && model.data != null)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Reminders",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListView.builder(
                                        itemCount: model.data!.length,
                                        itemBuilder: (context, index) {
                                          final reminder = model.data![index];
                                          return ReminderListItem(
                                            reminder: reminder,
                                            onDelete: () =>
                                                model.onDelete(reminder),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ],
                      )
                    : GridView.count(
                        crossAxisCount: 2,
                        children: model.patients
                            .map((b) => OptionPatient(
                                name: b.fullName,
                                onTap: () {
                                  model.openMapView(b);
                                },
                                link: b.photoUrl))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
      viewModelBuilder: () => HomeViewModel(),
    );
  }
}

class Option extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final String file;

  const Option(
      {super.key, required this.name, required this.onTap, required this.file});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 1.5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: onTap,
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.all(0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Lottie.asset(file),
                      )),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                          color: kcPrimaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6)),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptionPatient extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final String link;

  const OptionPatient(
      {super.key, required this.name, required this.onTap, required this.link});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 1.5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: onTap,
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.all(0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: link == ""
                            ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: CircleAvatar(
                                  child: Center(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      name[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  )),
                                ),
                              )
                            : Image.network(link),
                      )),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                          color: kcPrimaryColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6)),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LocationPickerBottomSheet extends StatefulWidget {
  const LocationPickerBottomSheet({super.key});

  @override
  State<LocationPickerBottomSheet> createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends State<LocationPickerBottomSheet> {
  late GoogleMapController _mapController;
  LatLng? _pickedLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height *
          0.7, // Adjust the height as needed
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onTap: (LatLng location) {
              setState(() {
                _pickedLocation = location;
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(9.9894, 76.3174), // Default map position
              zoom: 15.0,
            ),
            markers: _pickedLocation != null
                ? {
                    GoogleMapsMarker.Marker(
                      markerId: const MarkerId("picked_location"),
                      position: _pickedLocation!,
                      infoWindow: const InfoWindow(
                        title: "Picked Location",
                      ),
                    ),
                  }
                : {},
          ),
          Positioned(
            top: 10,
            left: 50,
            right: 50,
            child: SizedBox(
              width: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _pickedLocation);
                },
                child: const Text('Pick this Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDelete;

  const ReminderListItem(
      {super.key, required this.reminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(reminder.message),
        subtitle:
            Text("Time: ${reminder.dateTime.hour}:${reminder.dateTime.minute}"),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: onDelete,
        ),
        // You can customize the ListTile further if needed
        // For example, add an onTap handler to perform an action when tapped.
        // onTap: () => _handleReminderTap(context, reminder),
      ),
    );
  }
}
