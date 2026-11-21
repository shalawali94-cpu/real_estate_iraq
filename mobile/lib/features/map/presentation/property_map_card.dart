import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'location_picker_screen.dart' show mapTileUrl;

/// Small read-only map with a marker; tapping opens the external maps app.
class PropertyMapCard extends StatelessWidget {
  const PropertyMapCard({super.key, required this.point});
  final LatLng point;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.mapTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              onTap: (_, _) => launchUrl(
                Uri.parse('https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            children: [
              TileLayer(urlTemplate: mapTileUrl, userAgentPackageName: 'com.realestateiraq.app'),
              MarkerLayer(markers: [
                Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, size: 40, color: Colors.red)),
              ]),
            ],
          ),
        ),
      ),
    ]);
  }
}
