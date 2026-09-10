import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  LatLng? currentLocation;
  LatLng? selectedLocation;

  String selectedAddress = 'Choose a pickup location';

  List<SearchResult> suggestions = [];

  bool isLoadingLocation = true;
  bool isSearching = false;

  int _searchRequestId = 0;
  int _selectionRequestId = 0;

  @override
  void initState() {
    super.initState();

    // Get GPS only for showing the map near the user.
    // DO NOT automatically select it as pickup.
    getCurrentLocation(selectAsPickup: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> getCurrentLocation({
    bool selectAsPickup = false,
  }) async {
    try {
      final bool serviceEnabled =
          await geo.Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;

          if (selectAsPickup) {
            selectedAddress = 'Location service is turned off';
          }
        });

        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();

      if (permission == geo.LocationPermission.denied) {
        permission =
            await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;

          if (selectAsPickup) {
            selectedAddress = 'Location permission denied';
          }
        });

        return;
      }

      final geo.Position position =
          await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        currentLocation = location;
        isLoadingLocation = false;

        // Only select GPS when user explicitly presses
        // "current location" button.
        if (selectAsPickup) {
          selectedLocation = location;
          selectedAddress = 'Getting address...';
        }
      });

      mapController.move(location, 16);

      if (selectAsPickup) {
        await reverseGeocode(
          location,
          requestId: ++_selectionRequestId,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;

        if (selectAsPickup) {
          selectedAddress = 'Unable to get current location';
        }
      });
    }
  }

  // ============================================================
  // SEARCH INPUT
  // ============================================================

  void onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    // Customer has started searching.
    // Remove old GPS/previous pickup selection so it doesn't
    // misleadingly remain as the selected pickup.
    if (query.isNotEmpty) {
      setState(() {
        suggestions = [];
        selectedLocation = null;
        selectedAddress = 'Select a search result or tap the map';
        isSearching = true;
      });
    } else {
      setState(() {
        suggestions = [];
        isSearching = false;
        selectedLocation = null;
        selectedAddress = 'Choose a pickup location';
      });

      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        searchPlaces(query);
      },
    );
  }

  // ============================================================
  // PHOTON SEARCH
  // ============================================================

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;

    final int requestId = ++_searchRequestId;

    if (mounted) {
      setState(() {
        isSearching = true;
      });
    }

    try {
      List<SearchResult> results =
          await _searchPhoton(query);

      // If detailed address returns nothing, try a simpler
      // version without house/flat numbers.
      if (results.isEmpty && _looksLikeDetailedAddress(query)) {
        final simplifiedQuery =
            _simplifyAddressQuery(query);

        if (simplifiedQuery.isNotEmpty &&
            simplifiedQuery != query) {
          results = await _searchPhoton(
            simplifiedQuery,
            useLocationBias: false,
          );
        }
      }

      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        suggestions = results;
        isSearching = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        suggestions = [];
        isSearching = false;
      });
    }
  }

  Future<List<SearchResult>> _searchPhoton(
    String query, {
    bool? useLocationBias,
  }) async {
    final bool detailed =
        _looksLikeDetailedAddress(query);

    final bool shouldBias =
        useLocationBias ?? !detailed;

    final params = <String, String>{
      'q': query,
      'limit': '8',
      'lang': 'en',
      'countrycode': 'in',
    };

    // For normal searches, bias results towards the user.
    // For detailed addresses, DON'T bias because the customer
    // may be searching somewhere completely different.
    if (shouldBias && currentLocation != null) {
      params['lat'] =
          currentLocation!.latitude.toString();

      params['lon'] =
          currentLocation!.longitude.toString();

      params['zoom'] = '12';

      params['location_bias_scale'] = '0.3';
    }

    final uri = Uri.https(
      'photon.komoot.io',
      '/api',
      params,
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'DriverOnDemand/1.0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Photon search failed');
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final features =
        data['features'] as List<dynamic>? ?? [];

    final results = <SearchResult>[];

    for (final item in features) {
      try {
        final result = SearchResult.fromJson(
          item as Map<String, dynamic>,
        );

        if (result.isValid) {
          results.add(result);
        }
      } catch (_) {
        // Ignore malformed result.
      }
    }

    return results;
  }

  // ============================================================
  // ADDRESS HELPERS
  // ============================================================

  bool _looksLikeDetailedAddress(String query) {
    final hasNumber =
        RegExp(r'\d').hasMatch(query);

    final hasMultipleParts =
        query.split(',').length >= 2;

    return query.length >= 10 &&
        (hasNumber || hasMultipleParts);
  }

  String _simplifyAddressQuery(String query) {
    String simplified = query;

    // Remove house/flat numbers like:
    // 45/12
    // 45-A
    // 45
    simplified = simplified.replaceAll(
      RegExp(r'\b\d+[\/\-]?\d*[A-Za-z]?\b'),
      ' ',
    );

    // Remove common flat/house labels.
    simplified = simplified.replaceAll(
      RegExp(
        r'\b(flat|floor|house|h\.no|hno|plot|shop|room|apt)\b',
        caseSensitive: false,
      ),
      ' ',
    );

    simplified = simplified
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*,\s*,'), ',')
        .trim();

    return simplified;
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  void selectSearchResult(SearchResult result) {
    _selectionRequestId++;

    setState(() {
      selectedLocation = result.location;
      selectedAddress = result.fullAddress;
      suggestions = [];

      // Show the useful location name in search box.
      searchController.text = result.name;
      searchController.selection =
          TextSelection.fromPosition(
        TextPosition(
          offset: searchController.text.length,
        ),
      );
    });

    FocusScope.of(context).unfocus();

    mapController.move(
      result.location,
      17,
    );
  }

  // ============================================================
  // MAP TAP = EXACT CUSTOMER PICKUP
  // ============================================================

  Future<void> selectMapLocation(
    LatLng location,
  ) async {
    final int requestId = ++_selectionRequestId;

    setState(() {
      selectedLocation = location;
      selectedAddress = 'Finding address...';
      suggestions = [];
    });

    FocusScope.of(context).unfocus();

    await reverseGeocode(
      location,
      requestId: requestId,
    );
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<void> reverseGeocode(
    LatLng location, {
    required int requestId,
  }) async {
    try {
      final uri = Uri.https(
        'photon.komoot.io',
        '/reverse',
        {
          'lat': location.latitude.toString(),
          'lon': location.longitude.toString(),
          'lang': 'en',
          'limit': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DriverOnDemand/1.0',
        },
      );

      if (response.statusCode != 200) {
        if (mounted &&
            requestId == _selectionRequestId) {
          setState(() {
            selectedAddress = 'Selected location';
          });
        }

        return;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final features =
          data['features'] as List<dynamic>? ?? [];

      if (!mounted ||
          requestId != _selectionRequestId) {
        return;
      }

      if (features.isEmpty) {
        setState(() {
          selectedAddress = 'Selected location';
        });

        return;
      }

      final result = SearchResult.fromJson(
        features.first as Map<String, dynamic>,
      );

      setState(() {
        selectedAddress = result.fullAddress;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _selectionRequestId) {
        return;
      }

      setState(() {
        selectedAddress = 'Selected location';
      });
    }
  }

  // ============================================================
  // CONFIRM LOCATION
  // ============================================================

  void confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your pickup location first.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      MapLocationResult(
        location: selectedLocation!,
        address: selectedAddress,
      ),
    );
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void clearSearch() {
    _debounce?.cancel();
    _searchRequestId++;

    searchController.clear();

    setState(() {
      suggestions = [];
      isSearching = false;
      selectedLocation = null;
      selectedAddress = 'Choose a pickup location';
    });
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter =
        currentLocation ??
        const LatLng(28.6139, 77.2090);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Pickup Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================

          FlutterMap(
            mapController: mapController,

            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 19,

              onTap: (tapPosition, point) {
                selectMapLocation(point);
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName:
                    'com.driverondemand.app',

                maxZoom: 19,
              ),

              // ONLY SHOW PIN AFTER CUSTOMER HAS SELECTED
              // A PICKUP LOCATION.
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 55,
                      height: 55,

                      child: const Icon(
                        Icons.location_pin,
                        size: 55,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                  ),
                ],
              ),
            ],
          ),

          // ======================================================
          // SEARCH BAR
          // ======================================================

          Positioned(
            top: 12,
            left: 12,
            right: 12,

            child: Column(
              children: [
                Material(
                  elevation: 6,

                  borderRadius:
                      BorderRadius.circular(15),

                  child: TextField(
                    controller: searchController,

                    onChanged: onSearchChanged,

                    onSubmitted: (value) {
                      _debounce?.cancel();

                      if (value.trim().isNotEmpty) {
                        searchPlaces(value.trim());
                      }
                    },

                    decoration: InputDecoration(
                      hintText:
                          'Search pickup location',

                      prefixIcon:
                          const Icon(Icons.search),

                      suffixIcon: isSearching
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(14),

                              child: SizedBox(
                                width: 18,
                                height: 18,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : searchController
                                  .text
                                  .isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                  ),
                                  onPressed:
                                      clearSearch,
                                )
                              : null,

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),

                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // SEARCH SUGGESTIONS
                // ==================================================

                if (suggestions.isNotEmpty)
                  Container(
                    margin:
                        const EdgeInsets.only(top: 6),

                    constraints:
                        const BoxConstraints(
                      maxHeight: 320,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(15),

                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                        ),
                      ],
                    ),

                    child: ListView.separated(
                      shrinkWrap: true,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 6,
                      ),

                      itemCount:
                          suggestions.length,

                      separatorBuilder:
                          (_, __) =>
                              const Divider(
                        height: 1,
                      ),

                      itemBuilder:
                          (context, index) {
                        final result =
                            suggestions[index];

                        return ListTile(
                          leading:
                              const CircleAvatar(
                            backgroundColor:
                                Color(0xFFF1F3F5),

                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                          ),

                          title: Text(
                            result.name,

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          subtitle: Text(
                            result.fullAddress,

                            maxLines: 2,

                            overflow:
                                TextOverflow.ellipsis,
                          ),

                          onTap: () =>
                              selectSearchResult(
                            result,
                          ),
                        );
                      },
                    ),
                  ),

                // ==================================================
                // NO RESULT MESSAGE
                // ==================================================

                if (!isSearching &&
                    searchController
                        .text
                        .trim()
                        .isNotEmpty &&
                    suggestions.isEmpty)
                  Container(
                    margin:
                        const EdgeInsets.only(top: 6),

                    padding:
                        const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(15),

                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                        ),
                      ],
                    ),

                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Exact address not found. '
                            'Try a shorter address or tap the map '
                            'to place the pickup pin exactly.',
                            style: TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ======================================================
          // CURRENT LOCATION BUTTON
          // ======================================================

          Positioned(
            right: 16,
            bottom: 225,

            child: FloatingActionButton(
              heroTag: 'currentLocation',

              onPressed: () {
                getCurrentLocation(
                  selectAsPickup: true,
                );
              },

              backgroundColor: Colors.white,
              foregroundColor: Colors.black,

              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          // ======================================================
          // TAP MAP HINT
          // ======================================================

          if (selectedLocation == null)
            Positioned(
              left: 30,
              right: 30,
              bottom: 190,

              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.black87,

                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: const Text(
                    '💡 Search your location or tap anywhere '
                    'on the map to choose the exact pickup point',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

          // ======================================================
          // BOTTOM PICKUP CARD
          // ======================================================

          Positioned(
            left: 12,
            right: 12,
            bottom: 12,

            child: Container(
              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(20),

                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    color: Colors.black26,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [
                  const Text(
                    'Pickup location',

                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.location_on,

                        color:
                            selectedLocation != null
                                ? Colors.red
                                : Colors.grey,

                        size: 22,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          selectedAddress,

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),

                          maxLines: 3,

                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (selectedLocation != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        left: 30,
                        top: 5,
                      ),

                      child: Text(
                        'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}  '
                        'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',

                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed:
                          selectedLocation == null
                              ? null
                              : confirmLocation,

                      style:
                          ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),

                      child: const Text(
                        'CONFIRM PICKUP LOCATION',

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP LOCATION RESULT
// ============================================================

class MapLocationResult {
  final LatLng location;
  final String address;

  const MapLocationResult({
    required this.location,
    required this.address,
  });
}

// ============================================================
// SEARCH RESULT MODEL
// ============================================================

class SearchResult {
  final String name;
  final String fullAddress;
  final LatLng location;

  SearchResult({
    required this.name,
    required this.fullAddress,
    required this.location,
  });

  bool get isValid =>
      location.latitude >= -90 &&
      location.latitude <= 90 &&
      location.longitude >= -180 &&
      location.longitude <= 180;

  factory SearchResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final properties =
        json['properties']
                as Map<String, dynamic>? ??
            {};

    final geometry =
        json['geometry']
                as Map<String, dynamic>? ??
            {};

    final coordinates =
        geometry['coordinates']
                as List<dynamic>? ??
            [];

    if (coordinates.length < 2) {
      throw Exception('Invalid coordinates');
    }

    final longitude =
        (coordinates[0] as num).toDouble();

    final latitude =
        (coordinates[1] as num).toDouble();

    // ----------------------------------------------------------
    // NAME
    // ----------------------------------------------------------

    final String name =
        _firstNonEmpty([
              properties['name'],
              properties['street'],
              properties['locality'],
              properties['city'],
              properties['district'],
            ]) ??
            'Selected location';

    // ----------------------------------------------------------
    // ADDRESS
    // ----------------------------------------------------------

    final List<String> parts = [];

    final houseNumber =
        properties['housenumber']?.toString();

    final street =
        properties['street']?.toString();

    final locality =
        properties['locality']?.toString();

    final district =
        properties['district']?.toString();

    final city =
        properties['city']?.toString();

    final state =
        properties['state']?.toString();

    final postcode =
        properties['postcode']?.toString();

    final country =
        properties['country']?.toString();

    // House + street
    if (houseNumber != null &&
        houseNumber.trim().isNotEmpty) {
      if (street != null &&
          street.trim().isNotEmpty) {
        parts.add(
          '$houseNumber $street',
        );
      } else {
        parts.add(houseNumber);
      }
    } else if (street != null &&
        street.trim().isNotEmpty) {
      parts.add(street);
    }

    _addUnique(parts, locality);
    _addUnique(parts, city);
    _addUnique(parts, district);
    _addUnique(parts, state);
    _addUnique(parts, postcode);
    _addUnique(parts, country);

    final String fullAddress =
        parts.isEmpty
            ? name
            : parts.join(', ');

    return SearchResult(
      name: name,
      fullAddress: fullAddress,
      location: LatLng(
        latitude,
        longitude,
      ),
    );
  }

  static String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value in values) {
      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static void _addUnique(
    List<String> list,
    String? value,
  ) {
    if (value == null) return;

    final text = value.trim();

    if (text.isEmpty) return;

    if (!list.contains(text)) {
      list.add(text);
    }
  }
}