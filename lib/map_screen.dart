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
  final TextEditingController searchController =
      TextEditingController();

  Timer? _debounce;

  LatLng? currentLocation;
  LatLng? selectedLocation;

  String selectedAddress = 'Choose a pickup location';

  List<SearchResult> suggestions = [];

  bool isLoadingLocation = true;
  bool isSearching = false;

  int _searchId = 0;
  int _selectionId = 0;

  @override
  void initState() {
    super.initState();

    // GPS is ONLY used to centre the map.
    // It is NOT automatically selected as pickup.
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
      final serviceEnabled =
          await geo.Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;

          if (selectAsPickup) {
            selectedAddress =
                'Location service is turned off';
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
          permission ==
              geo.LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;

          if (selectAsPickup) {
            selectedAddress =
                'Location permission denied';
          }
        });

        return;
      }

      final position =
          await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        currentLocation = location;
        isLoadingLocation = false;

        // Only select GPS when the user explicitly
        // presses the current-location button.
        if (selectAsPickup) {
          selectedLocation = location;
          selectedAddress = 'Getting address...';
        }
      });

      mapController.move(location, 16);

      if (selectAsPickup) {
        await reverseGeocode(
          location,
          requestId: ++_selectionId,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;

        if (selectAsPickup) {
          selectedAddress =
              'Unable to get current location';
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

    if (query.isEmpty) {
      setState(() {
        suggestions = [];
        isSearching = false;
        selectedLocation = null;
        selectedAddress = 'Choose a pickup location';
      });

      return;
    }

    // Remove previous pickup selection while searching.
    setState(() {
      suggestions = [];
      selectedLocation = null;
      selectedAddress =
          'Select a search result or tap the map';
      isSearching = true;
    });

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () {
        searchPlaces(query);
      },
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;

    final int requestId = ++_searchId;

    if (mounted) {
      setState(() {
        isSearching = true;
      });
    }

    try {
      final results = await _searchPhoton(query);

      if (!mounted || requestId != _searchId) {
        return;
      }

      setState(() {
        suggestions = results;
        isSearching = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchId) {
        return;
      }

      setState(() {
        suggestions = [];
        isSearching = false;
      });
    }
  }

  // ============================================================
  // PHOTON API
  // ============================================================

  Future<List<SearchResult>> _searchPhoton(
    String query,
  ) async {
    final requestedHouseNumber =
        _extractHouseNumber(query);

    final bool detailedSearch =
        requestedHouseNumber != null ||
        query.contains(',');

    final params = <String, String>{
      'q': query,
      'limit': '12',
      'lang': 'en',
      'countrycode': 'in',
    };

    // For a normal search, nearby results are useful.
    //
    // For detailed searches like:
    // "FCA 275, Mukesh Colony, Ballabgarh"
    //
    // DO NOT bias towards current GPS.
    if (!detailedSearch && currentLocation != null) {
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
      throw Exception('Search failed');
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    final features =
        data['features'] as List<dynamic>? ?? [];

    final allResults = <SearchResult>[];

    for (final feature in features) {
      try {
        final result = SearchResult.fromJson(
          feature as Map<String, dynamic>,
        );

        if (result.isValid) {
          allResults.add(result);
        }
      } catch (_) {
        // Ignore invalid Photon results.
      }
    }

    // ==========================================================
    // IMPORTANT:
    //
    // If user searches "275 Mukesh Colony", don't show
    // "52 Mukesh Colony" as if it were the requested house.
    // ==========================================================

    if (requestedHouseNumber != null) {
      final exactHouseResults =
          allResults.where((result) {
        return result.houseNumber != null &&
            _numbersMatch(
              result.houseNumber!,
              requestedHouseNumber,
            );
      }).toList();

      if (exactHouseResults.isNotEmpty) {
        return exactHouseResults;
      }

      // Remove results that have a DIFFERENT house number.
      //
      // Example:
      // User -> 275 Mukesh Colony
      // Photon -> 52 Mukesh Colony
      //
      // 52 will NOT be shown.
      return allResults.where((result) {
        if (result.houseNumber == null) {
          return true;
        }

        return !_numbersMatch(
          result.houseNumber!,
          requestedHouseNumber,
        );
      }).toList();
    }

    return allResults;
  }

  // ============================================================
  // HOUSE NUMBER EXTRACTION
  // ============================================================

  String? _extractHouseNumber(String query) {
    final match = RegExp(
      r'\b(\d{1,5}(?:[\/\-]\d{1,5})?[A-Za-z]?)\b',
    ).firstMatch(query);

    if (match == null) {
      return null;
    }

    return match.group(1);
  }

  bool _numbersMatch(
    String a,
    String b,
  ) {
    final first =
        a.toLowerCase().replaceAll(' ', '');

    final second =
        b.toLowerCase().replaceAll(' ', '');

    return first == second;
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  void selectSearchResult(
    SearchResult result,
  ) {
    _selectionId++;

    setState(() {
      selectedLocation = result.location;
      selectedAddress = result.fullAddress;
      suggestions = [];

      searchController.text = result.fullAddress;
    });

    FocusScope.of(context).unfocus();

    mapController.move(
      result.location,
      17,
    );
  }

  // ============================================================
  // MAP TAP
  // ============================================================

  Future<void> selectMapLocation(
    LatLng location,
  ) async {
    final int requestId = ++_selectionId;

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

      if (!mounted ||
          requestId != _selectionId) {
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          selectedAddress = 'Selected location';
        });

        return;
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final features =
          data['features'] as List<dynamic>? ?? [];

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
          requestId != _selectionId) {
        return;
      }

      setState(() {
        selectedAddress = 'Selected location';
      });
    }
  }

  // ============================================================
  // CONFIRM
  // ============================================================

  void confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a pickup location first.',
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
    _searchId++;

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
    final mapCenter =
        currentLocation ??
        const LatLng(28.6139, 77.2090);

    final hasSearchText =
        searchController.text.trim().isNotEmpty;

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

              // Selected pickup pin
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
          // SEARCH BAR + RESULTS
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
                          : hasSearchText
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
                // RESULTS
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
                        vertical: 5,
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
                // NO RESULTS
                // ==================================================

                if (!isSearching &&
                    hasSearchText &&
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

                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_searching,
                              color: Colors.orange,
                            ),

                            SizedBox(width: 8),

                            Text(
                              'Exact address not found',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 7),

                        Text(
                          'Try a shorter area/street name, '
                          'or tap the exact location on the map.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
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
          // MAP HINT
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
                    '📍 Search a location or tap the map '
                    'to choose the exact pickup point',
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
          // BOTTOM CARD
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

                  // Show actual coordinates.
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
// LOCATION RESULT
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
// SEARCH RESULT
// ============================================================

class SearchResult {
  final String name;
  final String fullAddress;
  final String? houseNumber;
  final LatLng location;

  SearchResult({
    required this.name,
    required this.fullAddress,
    required this.houseNumber,
    required this.location,
  });

  bool get isValid {
    return location.latitude >= -90 &&
        location.latitude <= 90 &&
        location.longitude >= -180 &&
        location.longitude <= 180;
  }

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

    final houseNumber =
        _clean(properties['housenumber']);

    final street =
        _clean(properties['street']);

    final locality =
        _clean(properties['locality']);

    final city =
        _clean(properties['city']);

    final district =
        _clean(properties['district']);

    final state =
        _clean(properties['state']);

    final postcode =
        _clean(properties['postcode']);

    final country =
        _clean(properties['country']);

    final name =
        _firstNonEmpty([
          properties['name'],
          street,
          locality,
          city,
          district,
        ]) ??
        'Selected location';

    final parts = <String>[];

    // House + street
    if (houseNumber != null) {
      if (street != null) {
        parts.add(
          '$houseNumber $street',
        );
      } else {
        parts.add(houseNumber);
      }
    } else if (street != null) {
      parts.add(street);
    }

    _addUnique(parts, locality);
    _addUnique(parts, city);
    _addUnique(parts, district);
    _addUnique(parts, state);
    _addUnique(parts, postcode);
    _addUnique(parts, country);

    final fullAddress =
        parts.isEmpty
            ? name
            : parts.join(', ');

    return SearchResult(
      name: name,
      fullAddress: fullAddress,
      houseNumber: houseNumber,
      location: LatLng(
        latitude,
        longitude,
      ),
    );
  }

  static String? _clean(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
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

    if (value.isEmpty) return;

    if (!list.contains(value)) {
      list.add(value);
    }
  }
}