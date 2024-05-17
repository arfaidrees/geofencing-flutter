import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' show cos, sqrt, asin, pi;
import 'package:location/location.dart';
import 'dart:math' show cos, sin;
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LocationData? currentLocation;
  Location location = Location();
  LatLng initialCameraPosition = LatLng(32.497223, 74.536110);
  LatLng geoFenceCenter = LatLng(32.5014405, 74.4978824);
  LatLng? destinationLocation = LatLng(32.4770, 74.4496);
  bool isInsideGeofence = false;
  Set<Circle> circles = Set();
  Set<Marker> markers = Set();

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        this.currentLocation = currentLocation;
        checkGeofence();
        updateMarker();
      });
    });
  }

  void checkGeofence() {
    if (currentLocation != null) {
      double distance = haversineDistance(
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        geoFenceCenter,
      );

      // Check if the user is currently inside the geofence
      bool insideNow = distance <= 200;

      // Only update state and show Snackbar if the status changes
      if (insideNow != isInsideGeofence) {
        setState(() {
          isInsideGeofence = insideNow;
        });

        // Show Snackbar if the user crosses the geofence boundary
        if (!isInsideGeofence) {
          showSnackbar(isInsideGeofence);
        }
      }
    }
  }

  void updateMarker() {
    if (currentLocation != null) {
      markers.clear(); // Clear previous markers
      markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  dynamic haversineDistance(LatLng player1, LatLng player2) {
    const int radiusEarth = 6371; // in kilometers
    double lat1 = player1.latitude;
    double lon1 = player1.longitude;
    double lat2 = player2.latitude;
    double lon2 = player2.longitude;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    double distance = radiusEarth * c;

    return distance;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void showSnackbar(bool isInside) {
    String message = isInside ? 'You are inside the geofence!' : 'You are outside the geofence!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Geofencing testing')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialCameraPosition,
          zoom: 13,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          Circles(controller);
          updateMarker();
        },
        circles: circles,
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _handleLocationButtonPressed();
        },
        child: Icon(Icons.location_on),
      ),
    );
  }

  void Circles(GoogleMapController controller) {
    Set<Circle> newCircles = Set.from([
      Circle(
        circleId: CircleId('geo_fence_1'),
        center: geoFenceCenter,
        radius: 200,
        strokeWidth: 2,
        strokeColor: Colors.green,
        fillColor: Colors.green.withOpacity(0.15),
      ),
    ]);
    setState(() {
      circles = newCircles;
    });
  }

  void _handleLocationButtonPressed() async {
    LocationData? locData = await location.getLocation();
    if (locData != null) {
      GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(locData.latitude!, locData.longitude!),
        15.0,
      ));
    }
  }
}
