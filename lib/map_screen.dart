import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mappls_gl/mappls_gl.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapplsMapController? _mapController;

  final TextEditingController searchController =
      TextEditingController();

  Timer? _debounce;

  LatLng? currentLocation;
  LatLng? selectedLocation;

  String selectedAddress = 'Choose a pickup location';

  List<ELocation> suggestions = [];

  bool isLoadingLocation = true;
  bool isSearching = false;

  int _searchId = 0;
  int _selectionId = 0;

  // This prevents old search requests from
  // changing the UI after a result is selected.
  bool _isSelectingResult = false;

  static const LatLng _defaultLocation =
      LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();

    // GPS only centres the map.
    // It does NOT automatically select pickup.
    getCurrentLocation(
      selectAsPickup: false,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // MAP
  // ============================================================

  void onMapCreated(
    MapplsMapController controller,
  ) {
    _mapController = controller;
  }

  Future<void> moveMapTo(
    LatLng location, {
    double zoom = 16,
  }) async {
    final controller = _mapController;

    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          location,
          zoom,
        ),
        duration: const Duration(
          milliseconds: 500,
        ),
      );
    } catch (_) {
      // Ignore camera errors during initialization.
    }
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

      if (permission ==
          geo.LocationPermission.denied) {
        permission =
            await geo.Geolocator.requestPermission();
      }

      if (permission ==
              geo.LocationPermission.denied ||
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
        locationSettings:
            const geo.LocationSettings(
          accuracy:
              geo.LocationAccuracy.high,
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

        if (selectAsPickup) {
          selectedLocation = location;
          selectedAddress =
              'Getting address...';
        }
      });

      await moveMapTo(
        location,
        zoom: 16,
      );

      if (selectAsPickup) {
        final requestId =
            ++_selectionId;

        await reverseGeocode(
          location,
          requestId: requestId,
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

  void onSearchChanged(
    String value,
  ) {
    if (_isSelectingResult) {
      return;
    }

    _debounce?.cancel();

    final query = value.trim();

    // Empty search
    if (query.isEmpty) {
      _searchId++;

      setState(() {
        suggestions = [];
        isSearching = false;
        selectedLocation = null;
        selectedAddress =
            'Choose a pickup location';
      });

      return;
    }

    setState(() {
      suggestions = [];
      isSearching = true;
      selectedLocation = null;
      selectedAddress =
          'Select a search result or tap the map';
    });

    _debounce = Timer(
      const Duration(
        milliseconds: 450,
      ),
      () {
        searchPlaces(query);
      },
    );
  }

  // ============================================================
  // MAPPLS AUTOSUGGEST
  // ============================================================

  Future<void> searchPlaces(
    String query,
  ) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      return;
    }

    if (_isSelectingResult) {
      return;
    }

    final int requestId =
        ++_searchId;

    if (mounted) {
      setState(() {
        isSearching = true;
      });
    }

    try {
      final response =
          await MapplsAutoSuggest(
        query: trimmedQuery,
        location: currentLocation,
        tokenizeAddress: true,
        responseLang: 'en',
      ).callAutoSuggest();

      // Ignore old requests.
      if (!mounted ||
          requestId != _searchId ||
          _isSelectingResult) {
        return;
      }

      final results =
          response?.suggestedLocations ??
              <ELocation>[];

      setState(() {
        suggestions = results;
        isSearching = false;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _searchId ||
          _isSelectingResult) {
        return;
      }

      setState(() {
        suggestions = [];
        isSearching = false;
      });
    }
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  Future<void> selectSearchResult(
    ELocation result,
  ) async {
    final latitude = result.latitude;
    final longitude = result.longitude;

    if (latitude == null ||
        longitude == null) {
      return;
    }

    // Stop debounce timer.
    _debounce?.cancel();

    // Invalidate all previous searches.
    _searchId++;

    // Tell old requests that a result is being selected.
    _isSelectingResult = true;

    final location = LatLng(
      latitude,
      longitude,
    );

    final address =
        _buildSearchAddress(result);

    _selectionId++;

    if (!mounted) return;

    setState(() {
      selectedLocation = location;
      selectedAddress = address;
      suggestions = [];
      isSearching = false;
    });

    // Update search box.
    // This does NOT start a new user search.
    searchController.value =
        TextEditingValue(
      text: address,
      selection:
          TextSelection.collapsed(
        offset: address.length,
      ),
    );

    FocusScope.of(context).unfocus();

    // Move map to selected location.
    await moveMapTo(
      location,
      zoom: 17,
    );

    // Selection process finished.
    _isSelectingResult = false;
  }

  String _buildSearchAddress(
    ELocation result,
  ) {
    final placeName =
        result.placeName?.trim();

    final placeAddress =
        result.placeAddress?.trim();

    if (placeAddress != null &&
        placeAddress.isNotEmpty) {
      if (placeName != null &&
          placeName.isNotEmpty &&
          placeName != placeAddress) {
        return '$placeName, $placeAddress';
      }

      return placeAddress;
    }

    if (placeName != null &&
        placeName.isNotEmpty) {
      return placeName;
    }

    return 'Selected location';
  }

  // ============================================================
  // MAP TAP
  // ============================================================

  Future<void> selectMapLocation(
    LatLng location,
  ) async {
    _debounce?.cancel();
    _searchId++;

    _isSelectingResult = true;

    final int requestId =
        ++_selectionId;

    if (!mounted) return;

    setState(() {
      selectedLocation = location;
      selectedAddress =
          'Finding address...';
      suggestions = [];
      isSearching = false;
    });

    searchController.clear();

    FocusScope.of(context).unfocus();

    await moveMapTo(
      location,
      zoom: 17,
    );

    await reverseGeocode(
      location,
      requestId: requestId,
    );

    _isSelectingResult = false;
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<void> reverseGeocode(
    LatLng location, {
    required int requestId,
  }) async {
    try {
      final response =
          await MapplsReverseGeocode(
        location: location,
        lang: 'en',
      ).callReverseGeocode();

      if (!mounted ||
          requestId != _selectionId) {
        return;
      }

      final results =
          response?.results ?? [];

      if (results.isEmpty) {
        setState(() {
          selectedAddress =
              'Selected location';
        });

        return;
      }

      final result = results.first;

      final formatted =
          result.formattedAddress?.trim();

      final address =
          formatted != null &&
                  formatted.isNotEmpty
              ? formatted
              : _buildReverseAddress(
                  result,
                );

      setState(() {
        selectedAddress = address;
      });
    } catch (_) {
      if (!mounted ||
          requestId != _selectionId) {
        return;
      }

      setState(() {
        selectedAddress =
            'Selected location';
      });
    }
  }

  String _buildReverseAddress(
    ReverseGeocodePlace result,
  ) {
    final parts = <String>[];

    void add(String? value) {
      final text = value?.trim();

      if (text == null ||
          text.isEmpty) {
        return;
      }

      if (!parts.contains(text)) {
        parts.add(text);
      }
    }

    add(result.poi);
    add(result.houseName);
    add(result.houseNumber);
    add(result.street);
    add(result.locality);
    add(result.subLocality);
    add(result.subDistrict);
    add(result.city);
    add(result.district);
    add(result.state);
    add(result.pincode);

    return parts.isEmpty
        ? 'Selected location'
        : parts.join(', ');
  }

  // ============================================================
  // CONFIRM LOCATION
  // ============================================================

  void confirmLocation() {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
    _isSelectingResult = false;

    searchController.clear();

    setState(() {
      suggestions = [];
      isSearching = false;
      selectedLocation = null;
      selectedAddress =
          'Choose a pickup location';
    });
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
          // MAPPLS MAP
          // ======================================================

          MapplsMap(
            initialCameraPosition:
                const CameraPosition(
              target: _defaultLocation,
              zoom: 14,
            ),

            myLocationEnabled: true,

            myLocationTrackingMode:
                MyLocationTrackingMode.none,

            myLocationRenderMode:
                MyLocationRenderMode.normal,

            onMapCreated:
                onMapCreated,

            onMapClick: (
              dynamic point,
              LatLng coordinates,
            ) {
              selectMapLocation(
                coordinates,
              );
            },

            onMapError: (
              int code,
              String message,
            ) {
              debugPrint(
                'Mappls map error $code: $message',
              );
            },
          ),

          // ======================================================
          // CENTRE PIN
          // ======================================================

          IgnorePointer(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 38,
                ),
                child: Icon(
                  Icons.location_pin,
                  size: 52,
                  color:
                      selectedLocation != null
                          ? Colors.red
                          : Colors.black87,
                ),
              ),
            ),
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

                // SEARCH BAR
                Material(
                  elevation: 6,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  child: TextField(
                    controller:
                        searchController,

                    onChanged:
                        onSearchChanged,

                    onSubmitted: (
                      value,
                    ) {
                      _debounce?.cancel();

                      final query =
                          value.trim();

                      if (query.isNotEmpty) {
                        searchPlaces(
                          query,
                        );
                      }
                    },

                    decoration:
                        InputDecoration(
                      hintText:
                          'Search pickup location',

                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),

                      suffixIcon:
                          isSearching
                              ? const Padding(
                                  padding:
                                      EdgeInsets.all(
                                    14,
                                  ),
                                  child:
                                      SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  ),
                                )
                              : searchController
                                      .text
                                      .trim()
                                      .isNotEmpty
                                  ? IconButton(
                                      icon:
                                          const Icon(
                                        Icons.close,
                                      ),
                                      onPressed:
                                          clearSearch,
                                    )
                                  : null,

                      filled: true,
                      fillColor:
                          Colors.white,

                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // SEARCH RESULTS
                // ==================================================

                if (suggestions.isNotEmpty)
                  Container(
                    margin:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    constraints:
                        const BoxConstraints(
                      maxHeight: 320,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color:
                              Colors.black26,
                        ),
                      ],
                    ),

                    child:
                        ListView.separated(
                      shrinkWrap: true,

                      padding:
                          const EdgeInsets
                              .symmetric(
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
                          (
                        context,
                        index,
                      ) {
                        final result =
                            suggestions[
                                index];

                        final title =
                            result.placeName
                                ?.trim();

                        final subtitle =
                            result.placeAddress
                                ?.trim();

                        return ListTile(
                          leading:
                              const CircleAvatar(
                            backgroundColor:
                                Color(
                              0xFFF1F3F5,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color:
                                  Colors.red,
                            ),
                          ),

                          title: Text(
                            title != null &&
                                    title.isNotEmpty
                                ? title
                                : 'Location',

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          subtitle:
                              subtitle != null &&
                                      subtitle
                                          .isNotEmpty
                                  ? Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                    )
                                  : null,

                          onTap: () {
                            selectSearchResult(
                              result,
                            );
                          },
                        );
                      },
                    ),
                  ),

                // ==================================================
                // NO RESULTS
                // ==================================================

                if (!isSearching &&
                    !_isSelectingResult &&
                    selectedLocation == null &&
                    searchController
                        .text
                        .trim()
                        .isNotEmpty &&
                    suggestions.isEmpty)
                  Container(
                    margin:
                        const EdgeInsets.only(
                      top: 6,
                    ),

                    padding:
                        const EdgeInsets.all(
                      14,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color:
                              Colors.black26,
                        ),
                      ],
                    ),

                    child: const Row(
                      children: [

                        Icon(
                          Icons
                              .location_searching,
                          color:
                              Colors.orange,
                        ),

                        SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child: Text(
                            'No matching location found. '
                            'Try a shorter search or tap the map.',
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
            child:
                FloatingActionButton(
              heroTag:
                  'currentLocation',

              onPressed: () {
                getCurrentLocation(
                  selectAsPickup: true,
                );
              },

              backgroundColor:
                  Colors.white,

              foregroundColor:
                  Colors.black,

              child:
                  isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
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
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.black87,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: const Text(
                    '📍 Search a location or tap the map '
                    'to choose the pickup point',

                    textAlign:
                        TextAlign.center,

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
                  const EdgeInsets.all(
                18,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    color:
                        Colors.black26,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  const Text(
                    'Pickup location',

                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.location_on,

                        color:
                            selectedLocation !=
                                    null
                                ? Colors.red
                                : Colors.grey,

                        size: 22,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

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
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // COORDINATES
                  // ==================================================

                  if (selectedLocation !=
                      null)
                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        left: 30,
                        top: 5,
                      ),

                      child: Text(
                        'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}  '
                        'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',

                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  // ==================================================
                  // CONFIRM BUTTON
                  // ==================================================

                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed:
                          selectedLocation ==
                                  null
                              ? null
                              : confirmLocation,

                      style:
                          ElevatedButton
                              .styleFrom(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
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