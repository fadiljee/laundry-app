import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class _T {
  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF2563EB);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
}

class LiveMapTrackingPage extends StatefulWidget {
  final String orderCode;

  const LiveMapTrackingPage({
    super.key,
    required this.orderCode,
  });

  @override
  State<LiveMapTrackingPage> createState() =>
      _LiveMapTrackingPageState();
}

class _LiveMapTrackingPageState
    extends State<LiveMapTrackingPage> {
  final MapController _mapController = MapController();

  Timer? _pollingTimer;

  bool _isLoading = true;

  final LatLng _initialPosition =
      const LatLng(-6.914744, 107.609810);

  List<Marker> _markers = [];

  List<LatLng> _routePoints = [];

  LatLng? _courierPosition;
  LatLng? _customerPosition;

  String? _courierPhotoUrl;

  @override
  void initState() {
    super.initState();

    _fetchLocations();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        _fetchLocations(isBackground: true);
      },
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations({
    bool isBackground = false,
  }) async {
    try {
      final url = Uri.parse(
        'https://lyra.biz.id/api/orders/${widget.orderCode}',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];

        final double? courierLat = double.tryParse(
          data['courier_lat']?.toString() ?? '',
        );

        final double? courierLng = double.tryParse(
          data['courier_lng']?.toString() ?? '',
        );

        final double? customerLat = double.tryParse(
          data['customer_lat']?.toString() ?? '',
        );

        final double? customerLng = double.tryParse(
          data['customer_lng']?.toString() ?? '',
        );

        // ===============================
        // FOTO KURIR
        // ===============================

        String? rawUrl =
            data['courier_photo']?.toString() ??
            data['courier']?['photo_url']
                ?.toString();

        if (rawUrl != null &&
            rawUrl.isNotEmpty) {
          _courierPhotoUrl =
              "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
        }

        debugPrint(
            "PHOTO URL => $_courierPhotoUrl");

        // ===============================
        // POSISI KURIR
        // ===============================

        if (courierLat != null &&
            courierLng != null) {
          _courierPosition = LatLng(
            courierLat,
            courierLng,
          );
        }

        // ===============================
        // POSISI CUSTOMER
        // ===============================

        if (customerLat != null &&
            customerLng != null) {
          _customerPosition = LatLng(
            customerLat,
            customerLng,
          );
        }

        _updateMarkers();

        // ===============================
        // AMBIL RUTE
        // ===============================

        if (_courierPosition != null &&
            _customerPosition != null) {
          await _fetchRoute();
        }

        if (!isBackground) {
          setState(() {
            _isLoading = false;
          });

          Future.delayed(
            const Duration(milliseconds: 500),
            _moveCameraToFit,
          );
        }
      }
    } catch (e) {
      debugPrint(
          "Gagal mengambil lokasi: $e");
    }
  }

  // ======================================
  // AMBIL RUTE JALAN
  // ======================================

  Future<void> _fetchRoute() async {
    if (_courierPosition == null ||
        _customerPosition == null) {
      return;
    }

    final String url =
        'https://router.project-osrm.org/route/v1/driving/${_courierPosition!.longitude},${_courierPosition!.latitude};${_customerPosition!.longitude},${_customerPosition!.latitude}?geometries=geojson';

    try {
      final response =
          await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data =
            json.decode(response.body);

        final List<dynamic> coords =
            data['routes'][0]['geometry']
                ['coordinates'];

        List<LatLng> points = [];

        for (var coord in coords) {
          points.add(
            LatLng(coord[1], coord[0]),
          );
        }

        if (mounted) {
          setState(() {
            _routePoints = points;
          });
        }
      }
    } catch (e) {
      debugPrint(
          "Gagal mengambil rute: $e");
    }
  }

  // ======================================
  // AVATAR KURIR
  // ======================================

  Widget _buildCourierAvatar(
    String? url, {
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: ClipOval(
        child: url != null &&
                url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,

                loadingBuilder:
                    (context,
                        child,
                        progress) {
                  if (progress == null) {
                    return child;
                  }

                  return const Center(
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                },

                errorBuilder:
                    (context,
                        error,
                        stackTrace) {
                  debugPrint(
                      "FOTO ERROR => $url");

                  debugPrint(
                      "DETAIL ERROR => $error");

                  return const Icon(
                    Icons.person,
                    color: _T.accent,
                    size: 30,
                  );
                },
              )
            : const Icon(
                Icons.person,
                color: _T.accent,
                size: 30,
              ),
      ),
    );
  }

  // ======================================
  // UPDATE MARKER
  // ======================================

  void _updateMarkers() {
    final List<Marker> newMarkers =
        [];

    // ===============================
    // MARKER CUSTOMER
    // ===============================

    if (_customerPosition != null) {
      newMarkers.add(
        Marker(
          width: 50,
          height: 50,
          point: _customerPosition!,
          child: const Column(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: 35,
              ),
            ],
          ),
        ),
      );
    }

    // ===============================
    // MARKER KURIR
    // ===============================

    if (_courierPosition != null) {
      newMarkers.add(
        Marker(
          width: 65,
          height: 65,
          point: _courierPosition!,
          child: _buildCourierAvatar(
            _courierPhotoUrl,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  // ======================================
  // MOVE CAMERA
  // ======================================

  void _moveCameraToFit() {
    if (_courierPosition != null &&
        _customerPosition != null) {
      final bounds =
          LatLngBounds.fromPoints([
        _courierPosition!,
        _customerPosition!,
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.all(60),
        ),
      );
    } else if (_courierPosition !=
        null) {
      _mapController.move(
        _courierPosition!,
        16,
      );
    } else if (_customerPosition !=
        null) {
      _mapController.move(
        _customerPosition!,
        16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _T.surface,
        iconTheme: const IconThemeData(
          color: _T.textMain,
        ),
        centerTitle: true,
        title: Text(
          "Live Tracking Kurir",
          style: GoogleFonts.poppins(
            color: _T.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      // ======================================
      // BODY
      // ======================================

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: _T.accent,
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController:
                      _mapController,
                  options: MapOptions(
                    initialCenter:
                        _customerPosition ??
                            _initialPosition,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.laundry_app.app',
                    ),

                    // ===============================
                    // ROUTE LINE
                    // ===============================

                    if (_routePoints
                        .isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points:
                                _routePoints,
                            strokeWidth: 5,
                            color: Colors
                                .blueAccent,
                          ),
                        ],
                      ),

                    // ===============================
                    // MARKERS
                    // ===============================

                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),

                // ======================================
                // CARD INFO BAWAH
                // ======================================

                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.all(
                            20),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                                  0.1),
                          blurRadius: 20,
                          offset:
                              const Offset(
                                  0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildCourierAvatar(
                          _courierPhotoUrl,
                          size: 52,
                        ),

                        const SizedBox(
                            width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              Text(
                                "Kurir Menuju Lokasi Anda",
                                style:
                                    GoogleFonts
                                        .poppins(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  fontSize:
                                      14,
                                ),
                              ),

                              const SizedBox(
                                  height:
                                      4),

                              Text(
                                "Posisi diperbarui otomatis secara real-time.",
                                style:
                                    GoogleFonts
                                        .inter(
                                  fontSize:
                                      11,
                                  color: _T
                                      .textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // ======================================
      // FAB
      // ======================================

      floatingActionButton:
          FloatingActionButton(
        backgroundColor: _T.surface,
        onPressed: _moveCameraToFit,
        child: const Icon(
          Icons
              .center_focus_strong_rounded,
          color: _T.accent,
        ),
      ),
    );
  }
}