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
  static const LatLng _kLake = LatLng(40.423, 68.0848);
  static const LatLng _kL = LatLng(40.111, 68.0435);
  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  List<Marker>myMarker=[];
   LatLng? tapped;


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
      appBar: AppBar(
        title: const Text('Location tracker'),
        backgroundColor: const Color(0xff087f4a),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(children: [
              GoogleMap( buildingsEnabled: true,
                myLocationButtonEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: ((GoogleMapController controller) =>
                    _completer.complete(controller)),
                initialCameraPosition:
                    CameraPosition(target: currentPosition!, zoom: 2),
                markers:
                {
                  Marker(
                      markerId: const MarkerId('Current location'),
                      icon: BitmapDescriptor.defaultMarker,
                      position: currentPosition!,
                ),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12, bottom: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          child: Icon(
                            Icons.not_started_outlined,
                            size: 50,
                          ),
                        )
                      ],
                    ),
                  ),
                  // Container(
                  //   width: MediaQuery.of(context).size.width,
                  //   height: 100,
                  //   decoration: const BoxDecoration(
                  //     color: Color(0xff087f4a),
                  //   ),
                  //   child: ListView.builder(
                  //     scrollDirection: Axis.horizontal,
                  //     itemCount: 5,
                  //     itemBuilder: (context, index) {
                  //       return    Container(
                  //         width: 10,
                  //         height: 5,
                  //         decoration: BoxDecoration(borderRadius: BorderRadiusDirectional.circular(15)),
                  //       );
                  //     },
                  //   ),
                  // )
                ],
              )
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
  _handleTap(LatLng tappedPoint){
    setState(() {
      myMarker=[];
      myMarker.add(Marker(
          markerId: MarkerId(tappedPoint.toString()),
          icon: BitmapDescriptor.defaultMarker,
          position: tappedPoint));
    });
  }
}
