import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapLocation extends StatefulWidget {
  const GoogleMapLocation({super.key});

  @override
  State<GoogleMapLocation> createState() => _GoogleMapLocationState();
}

class _GoogleMapLocationState extends State<GoogleMapLocation> {
  late GoogleMapController _googleMapController;
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Location location = Location();
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylinePoints = [];

  @override
  void initState() {
    super.initState();
    getLocation();
    _animateToUserLocation();
    _startLocationUpdates();
  }

  Future<void> getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      _updateMarkerAndPolyline();
    });
  }

  void _animateToUserLocation() async {
    if (_locationData != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _locationData!.latitude!,
              _locationData!.longitude!,
            ),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _startLocationUpdates() {
    location.onLocationChanged.listen((LocationData currentLocation) {
      _locationData = currentLocation;
      setState(() {
        _updateMarkerAndPolyline();
      });
    });
  }

  void _updateMarkerAndPolyline() {
    if (_locationData != null) {
      LatLng currentLatLng = LatLng(_locationData!.latitude!, _locationData!.longitude!);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId("current-location"),
          position: currentLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: "My current location",
            snippet: "Lat: ${_locationData!.latitude}, Lng: ${_locationData!.longitude}",
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Marker tapped!")),
            );
          },
        ),
      );

      _polylinePoints.add(currentLatLng);
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: _polylinePoints,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google Map Location'),
          elevation: 2,
        ),
        body: _locationData != null
            ? GoogleMap(
          mapType: MapType.terrain,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _locationData!.latitude!,
              _locationData!.longitude!,
            ),
            zoom: 16.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _googleMapController = controller;
            _animateToUserLocation();
          },
          zoomControlsEnabled: true,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          polylines: _polylines,
        )
            : Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
