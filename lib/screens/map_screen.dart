import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../db/database_helper.dart';
import '../models/destination_model.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  final Destination? selectedDestination;

  const MapScreen({super.key, this.selectedDestination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _center = const LatLng(-7.4244, 109.2302);
  List<Destination> _destinations = [];
  Destination? _focusedDestination;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.selectedDestination != null) {
      _center = LatLng(
        widget.selectedDestination!.latitude,
        widget.selectedDestination!.longitude,
      );
      _focusedDestination = widget.selectedDestination;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.readAllDestinations();
    setState(() {
      _destinations = data;
    });
  }

  void _onMarkerTapped(Destination dest) {
    setState(() {
      _focusedDestination = dest;
    });
    _mapController.move(LatLng(dest.latitude, dest.longitude), 15.0);
  }

  void _closeCard() {
    if (_focusedDestination != null) {
      setState(() {
        _focusedDestination = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah halaman ini bisa di-back atau tidak
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // PERBAIKAN DI SINI:
        // Tombol Back hanya muncul jika ada halaman sebelumnya (canPop == true)
        leading: canPop 
            ? Container(
                margin: const EdgeInsets.only(left: 10, top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null, // Jika dari menu bawah, tombol back hilang
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: () {
                _loadData();
                _closeCard();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.selectedDestination != null ? 15.0 : 13.0,
              onTap: (_, __) => _closeCard(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nikkkdevvv.travelwisatalokal',
              ),
              MarkerLayer(
                markers: _destinations.map((dest) {
                  final isSelected = _focusedDestination?.id == dest.id;

                  return Marker(
                    point: LatLng(dest.latitude, dest.longitude),
                    width: isSelected ? 70 : 50,
                    height: isSelected ? 70 : 50,
                    child: GestureDetector(
                      onTap: () => _onMarkerTapped(dest),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.red : Colors.redAccent,
                          size: isSelected ? 50 : 40,
                          shadows: const [
                            Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          if (_focusedDestination != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 110,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(destination: _focusedDestination!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: _focusedDestination!.id!,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[200],
                            image: _focusedDestination!.imagePath != null
                                ? DecorationImage(
                              image: FileImage(File(_focusedDestination!.imagePath!)),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: _focusedDestination!.imagePath == null
                              ? const Icon(Icons.image, color: Colors.grey)
                              : null,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _focusedDestination!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _focusedDestination!.location,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Buka: ${_focusedDestination!.openTime}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
