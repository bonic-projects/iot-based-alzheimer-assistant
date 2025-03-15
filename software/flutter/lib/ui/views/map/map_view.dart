import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stacked/stacked.dart';

import '../../../models/appuser.dart';
import '../../../models/reminder.dart';
import 'map_viewmodel.dart';

class MapView extends StackedView<MapViewModel> {
  final AppUser user;

  const MapView({Key? key, required this.user}) : super(key: key);

  @override
  Widget builder(
      BuildContext context,
      MapViewModel viewModel,
      Widget? child,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${user.fullName}\'s location'),
        actions: [
          // Alert bell with notification badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showAlertsDialog(context, viewModel);
                },
              ),
              if (viewModel.alerts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${viewModel.alerts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Reminder"),
        icon: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => ReminderInputBottomSheet(
              onReminderSubmitted: (reminder) {
                viewModel.setReminder(reminder: reminder);
              },
            ),
          );
        },
      ),
      body: Stack(
        children: [
          Center(
            child: viewModel.isBusy
                ? const CircularProgressIndicator()
                : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    viewModel.user!.latitude, viewModel.user!.longitude),
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: <Marker>{
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: LatLng(
                      viewModel.user!.latitude, viewModel.user!.longitude),
                  infoWindow: InfoWindow(
                    title: 'Current Location: ${viewModel.user!.place}',
                  ),
                ),
              },
            ),
          ),
          // Alert overlay for latest alert
          if (viewModel.alerts.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.alerts.last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          viewModel.dismissLatestAlert();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAlertsDialog(BuildContext context, MapViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: viewModel.alerts.isEmpty
              ? const Text('No active alerts')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: viewModel.alerts.length,
            itemBuilder: (context, index) {
              final alert = viewModel.alerts[index];
              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(alert),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    viewModel.dismissAlert(index);
                    if (viewModel.alerts.isEmpty) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  MapViewModel viewModelBuilder(BuildContext context) => MapViewModel();

  @override
  void onViewModelReady(MapViewModel viewModel) {
    viewModel.onModelReady(user);
    super.onViewModelReady(viewModel);
  }
}

// Keep your existing ReminderInputBottomSheet class as is...

class ReminderInputBottomSheet extends StatefulWidget {
  final Function(Reminder) onReminderSubmitted;

  const ReminderInputBottomSheet(
      {super.key, required this.onReminderSubmitted});

  @override
  _ReminderInputBottomSheetState createState() =>
      _ReminderInputBottomSheetState();
}

class _ReminderInputBottomSheetState extends State<ReminderInputBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Add Reminder',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Reminder Message'),
            ),
            const SizedBox(height: 40.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Time'),
                TextButton(
                  onPressed: () => _selectDateTime(context),
                  child: const Text('Pick'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Selected Time: ${_selectedDateTime.hour}: ${_selectedDateTime.minute}',
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
            ),
            const SizedBox(height: 80.0),
            ElevatedButton(
              onPressed: () => _submitForm(),
              child: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    // final DateTime? picked = await showDatePicker(
    //   context: context,
    //   initialDate: _selectedDateTime,
    //   firstDate: DateTime.now(),
    //   lastDate: DateTime.now().add(const Duration(days: 365)),
    // );

    // if (picked != null) {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          2024,
          1,
          1,
          // picked.year,
          // picked.month,
          // picked.day,
          time.hour,
          time.minute,
        );
      });
    }
    // }
  }

  void _submitForm() {
    final String message = _messageController.text.trim();

    if (message.isNotEmpty) {
      final Reminder newReminder = Reminder(
        id: DateTime.now().toString(),
        message: message,
        dateTime: _selectedDateTime,
      );

      widget.onReminderSubmitted(newReminder);
      Navigator.of(context).pop(); // Close the bottom sheet
    } else {
      // Handle validation error, if necessary
      // For example, show a snackbar or an error message
    }
  }
}
