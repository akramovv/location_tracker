import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location_tracker/config/const.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _completer =
  Completer<GoogleMapController>();
  final Location _locationController = Location();
  static const LatLng _kLake =  LatLng(40.423, 68.0848);
  static const LatLng _kL =  LatLng(40.111, 68.0435);
  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  BitmapDescriptor markerIcon=BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    getLocation().then((_) => {
      getPolytinePoints()
          .then((coordinates) => {generatePolylinePoints(coordinates)})
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Stack(
          children: [GoogleMap(
            zoomControlsEnabled: false,
            onMapCreated: ((GoogleMapController controller) =>
                _completer.complete(controller)),
            initialCameraPosition: CameraPosition(target: currentPosition!, zoom: 2),
            markers: {
              Marker(
                  markerId: const MarkerId('Current location'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: currentPosition!,
                  onDragEnd: (value){}),
              const Marker(
                  markerId: MarkerId('Source location'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _kLake),
              const Marker(
                  markerId: MarkerId(' location'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _kL),
            },
            polylines: Set<Polyline>.of(polylines.values),

          ),
          ]),
    );
  }

  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _completer.future;
    CameraPosition position = CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionStatus;
    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }
    permissionStatus = await _locationController.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _locationController.requestPermission();
      if (permissionStatus == PermissionStatus.granted) {
        return;
      }
    }
    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          cameraToPosition(currentPosition!);
          print('Current:$currentPosition');
        });
      }
    });
  }

  Future<List<LatLng>> getPolytinePoints() async {
    List<LatLng> polylineCordinates = [];
    PolylinePoints points = PolylinePoints();
    PolylineResult result = await points.getRouteBetweenCoordinates(
        Google_Maps_Key,
        PointLatLng(_kLake.latitude, _kLake.longitude),
        PointLatLng(_kL.latitude, _kL.longitude),
        travelMode: TravelMode.walking);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCordinates;
  }

  void generatePolylinePoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId('polylineId');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.blue,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}
