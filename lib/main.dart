import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const TaxiApp());
}

// ✅ Central ride store (simulates backend)
class RideStore {
  static final List<Map<String, dynamic>> rides = [];

  static void addRide(String id, double fare) {
    rides.add({"id": id, "fare": fare, "status": "Requested"});
  }

  static void updateRideStatus(String id, String status) {
    for (var ride in rides) {
      if (ride["id"] == id) {
        ride["status"] = status;
        break;
      }
    }
  }

  static List<Map<String, dynamic>> get passengerHistory => rides;

  static List<Map<String, dynamic>> get driverRequests =>
      rides.where((ride) => ride["status"] == "Requested").toList();
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleSelectorScreen(),
    );
  }
}

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Taxi App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PassengerHome()),
                );
              },
              child: const Text("Passenger"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverHome()),
                );
              },
              child: const Text("Driver"),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚖 Passenger
class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool _pickupSet = false;
  bool _destinationSet = false;
  double? _fare;

  void _setPickup() {
    setState(() {
      _pickupSet = true;
      _destinationSet = false;
      _fare = null;
    });
  }

  void _setDestination() {
    if (_pickupSet) {
      setState(() {
        _destinationSet = true;
        _fare = 10 * 30; // fake 10 km * 30 PKR/km
      });
    }
  }

  void _confirmRide() {
    final rideId = const Uuid().v4();
    RideStore.addRide(rideId, _fare ?? 0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideConfirmationScreen(rideId: rideId, fare: _fare ?? 0),
      ),
    ).then((_) => setState(() {})); // refresh after return
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideHistoryScreen(rideHistory: RideStore.passengerHistory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Passenger - Book a Ride"),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _viewHistory),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _setPickup, child: const Text("Set Pickup")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _setDestination, child: const Text("Set Destination")),
            if (_fare != null) ...[
              const SizedBox(height: 20),
              Text("Fare: PKR ${_fare!.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _confirmRide, child: const Text("Confirm Ride")),
            ],
          ],
        ),
      ),
    );
  }
}

// 📌 Ride Confirmation
class RideConfirmationScreen extends StatelessWidget {
  final String rideId;
  final double fare;

  const RideConfirmationScreen({super.key, required this.rideId, required this.fare});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride Confirmed")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Your ride has been requested!", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Ride ID: $rideId"),
            const SizedBox(height: 10),
            Text("Fare: PKR ${fare.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }
}

// 📌 Passenger Ride History
class RideHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> rideHistory;

  const RideHistoryScreen({super.key, required this.rideHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride History")),
      body: rideHistory.isEmpty
          ? const Center(child: Text("No rides yet."))
          : ListView.builder(
              itemCount: rideHistory.length,
              itemBuilder: (context, index) {
                final ride = rideHistory[index];
                return ListTile(
                  leading: const Icon(Icons.local_taxi),
                  title: Text("Ride ID: ${ride['id']}"),
                  subtitle: Text("Fare: PKR ${ride['fare']} | Status: ${ride['status']}"),
                );
              },
            ),
    );
  }
}

// 👨‍✈️ Driver
class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  void _acceptRide(String id) {
    setState(() {
      RideStore.updateRideStatus(id, "Accepted");
    });
  }

  void _rejectRide(String id) {
    setState(() {
      RideStore.updateRideStatus(id, "Rejected");
    });
  }

  @override
  Widget build(BuildContext context) {
    final requests = RideStore.driverRequests;

    return Scaffold(
      appBar: AppBar(title: const Text("Driver - Ride Requests")),
      body: requests.isEmpty
          ? const Center(child: Text("No ride requests"))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_taxi),
                    title: Text("Ride ID: ${req['id']}"),
                    subtitle: Text("Fare: PKR ${req['fare']} | Status: ${req['status']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptRide(req['id']),
                          child: const Text("Accept"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _rejectRide(req['id']),
                          child: const Text("Reject"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
