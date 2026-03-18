import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SponsorMapWidget extends StatefulWidget {
  final LatLng center;
  final Set<Circle> circles;
  final Set<Marker> markers;
  final Function(LatLng) onTap;
  final Function(GoogleMapController) onMapCreated;

  const SponsorMapWidget({
    super.key,
    required this.center,
    required this.circles,
    required this.markers,
    required this.onTap,
    required this.onMapCreated,
  });

  @override
  State<SponsorMapWidget> createState() => _SponsorMapWidgetState();
}

class _SponsorMapWidgetState extends State<SponsorMapWidget> {

  @override
  Widget build(BuildContext context) {

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: 11.5,
      ),

      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,

      myLocationEnabled: false,
      myLocationButtonEnabled: true,

      circles: widget.circles,
      markers: widget.markers,

      onTap: widget.onTap,
      onMapCreated: widget.onMapCreated,
    );
  }
}