import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Configurable tile source (production tile provider is a pre-release item).
const mapTileUrl = String.fromEnvironment('MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

/// Full-screen map: tap to place a pin, confirm to return the LatLng.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial, this.zoom});
  final LatLng? initial;
  final double? zoom;
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  static const _iraq = LatLng(33.2, 43.7);
  static const _iraqZoom = 5.6;
  final _map = MapController();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  /// Starts on all of Iraq, then flies in to the chosen governorate/district.
  void _flyIn() {
    final target = _start;
    if (target == null) return;
    final zoomTo = widget.zoom ?? 13;
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);
    curve.addListener(() {
      final v = curve.value;
      _map.move(
        LatLng(_iraq.latitude + (target.latitude - _iraq.latitude) * v,
            _iraq.longitude + (target.longitude - _iraq.longitude) * v),
        _iraqZoom + (zoomTo - _iraqZoom) * v,
      );
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  LatLng? _picked;
  late final LatLng? _start = widget.initial;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.pickLocationTitle)),
      body: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _iraq,
          initialZoom: _iraqZoom,
          onMapReady: _flyIn,
          onTap: (_, p) => setState(() => _picked = p),
        ),
        children: [
          TileLayer(urlTemplate: mapTileUrl, userAgentPackageName: 'com.realestateiraq.app'),
          if (_picked != null)
            MarkerLayer(markers: [
              Marker(
                point: _picked!,
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on, size: 44, color: Colors.red),
              ),
            ]),
          const RichAttributionWidget(attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            key: const Key('confirmLocationButton'),
            onPressed: _picked == null ? null : () => context.pop(_picked),
            child: Text(_picked == null ? t.pickLocationHint : t.pickLocationConfirm),
          ),
        ),
      ),
    );
  }
}
