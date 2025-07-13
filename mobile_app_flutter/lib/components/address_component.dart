import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// Data Model with proper typing and safer casts
class AdministrativeDivision {
  final String name;
  final List<AdministrativeDivision> children;

  AdministrativeDivision({required this.name, this.children = const []});

  factory AdministrativeDivision.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    List<AdministrativeDivision> childrenList = [];

    List<dynamic>? childrenJson;
    if (json.containsKey('districts') && json['districts'] is List) {
      childrenJson = json['districts'] as List<dynamic>;
    } else if (json.containsKey('cities') && json['cities'] is List) {
      childrenJson = json['cities'] as List<dynamic>;
    } else if (json.containsKey('subdivisions') &&
        json['subdivisions'] is List) {
      childrenJson = json['subdivisions'] as List<dynamic>;
    }

    if (childrenJson != null) {
      childrenList = childrenJson
          .map(
            (childJson) => AdministrativeDivision.fromJson(
              childJson as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    return AdministrativeDivision(name: name, children: childrenList);
  }
}

class AddressData {
  final String? fullName;
  final String? organizationName;
  final String? addressLine1;
  final String? addressLine2;
  final String? postalCode;
  final String? administrativeDivision1;
  final String? administrativeDivision2;
  final String? city;
  final String? country;
  final String? landmark;

  AddressData({
    this.fullName,
    this.organizationName,
    this.addressLine1,
    this.addressLine2,
    this.postalCode,
    this.administrativeDivision1,
    this.administrativeDivision2,
    this.city,
    this.country,
    this.landmark,
  });

  @override
  String toString() {
    return 'AddressData(\n'
        '  fullName: $fullName,\n'
        '  organizationName: $organizationName,\n'
        '  addressLine1: $addressLine1,\n'
        '  addressLine2: $addressLine2,\n'
        '  postalCode: $postalCode,\n'
        '  adminDiv1: $administrativeDivision1,\n'
        '  adminDiv2: $administrativeDivision2,\n'
        '  city: $city,\n'
        '  country: $country,\n'
        '  landmark: $landmark\n'
        ')';
  }
}

class AddressComponent extends StatefulWidget {
  final String assetPath;
  final String adminDiv1Label;
  final String adminDiv2Label;
  final String defaultCountry;
  final ValueChanged<AddressData>? onChanged;
  final ValueChanged<AddressData>? onConfirmed;
  final AddressData? initialAddress;
  final bool showFullName;
  final bool showOrganizationName;
  final bool showPostalCode;
  final bool showLandmark;
  final bool showConfirmButton;

  const AddressComponent({
    super.key,
    required this.assetPath,
    this.adminDiv1Label = 'Administrative Division 1',
    this.adminDiv2Label = 'Administrative Division 2',
    this.defaultCountry = '',
    this.showFullName = true,
    this.showOrganizationName = true,
    this.showPostalCode = true,
    this.showLandmark = true,
    this.showConfirmButton = true,
    this.onChanged,
    this.onConfirmed,
    this.initialAddress,
  });

  @override
  State<AddressComponent> createState() => _AddressComponentState();
}

class _AddressComponentState extends State<AddressComponent> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  String? _selectedAdminDiv1Name;
  String? _selectedAdminDiv2Name;

  List<AdministrativeDivision> _allAdminDiv1 = [];
  List<AdministrativeDivision> _currentAdminDiv2 = [];

  bool _isLoading = true;
  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadAddressData();

    _fullNameController.addListener(_notifyChanged);
    _organizationNameController.addListener(_notifyChanged);
    _addressLine1Controller.addListener(_notifyChanged);
    _addressLine2Controller.addListener(_notifyChanged);
    _postalCodeController.addListener(_notifyChanged);
    _landmarkController.addListener(_notifyChanged);

    if (widget.initialAddress != null) {
      _populateInitialAddress(widget.initialAddress!);
    }
  }

  void _populateInitialAddress(AddressData address) {
    _fullNameController.text = address.fullName ?? '';
    _organizationNameController.text = address.organizationName ?? '';
    _addressLine1Controller.text = address.addressLine1 ?? '';
    _addressLine2Controller.text = address.addressLine2 ?? '';
    _postalCodeController.text = address.postalCode ?? '';
    _landmarkController.text = address.landmark ?? '';
    _selectedAdminDiv1Name = address.administrativeDivision1;
    // We will set _currentAdminDiv2 after loading JSON; will update dropdown accordingly.
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _organizationNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  AddressData _getCurrentAddress() {
    return AddressData(
      fullName: _fullNameController.text.isNotEmpty
          ? _fullNameController.text
          : null,
      organizationName: _organizationNameController.text.isNotEmpty
          ? _organizationNameController.text
          : null,
      addressLine1: _addressLine1Controller.text.isNotEmpty
          ? _addressLine1Controller.text
          : null,
      addressLine2: _addressLine2Controller.text.isNotEmpty
          ? _addressLine2Controller.text
          : null,
      postalCode: _postalCodeController.text.isNotEmpty
          ? _postalCodeController.text
          : null,
      administrativeDivision1: _selectedAdminDiv1Name,
      administrativeDivision2: _selectedAdminDiv2Name,
      city: _selectedAdminDiv2Name,
      country: widget.defaultCountry,
      landmark: _landmarkController.text.isNotEmpty
          ? _landmarkController.text
          : null,
    );
  }

  void _notifyChanged() {
    widget.onChanged?.call(_getCurrentAddress());
  }

  Future<void> _loadAddressData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final String response = await rootBundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);

      setState(() {
        _allAdminDiv1 = data
            .map((json) => AdministrativeDivision.fromJson(json))
            .toList();

        // If initial selected adminDiv1 was set before loading, update districts list and set adminDiv2 selection
        if (_selectedAdminDiv1Name != null) {
          final selectedDiv1 = _allAdminDiv1.firstWhere(
            (div) => div.name == _selectedAdminDiv1Name,
            orElse: () => AdministrativeDivision(name: '', children: []),
          );
          _currentAdminDiv2 = selectedDiv1.children;

          // If initial adminDiv2 value exists in children, keep it; else reset
          if (_selectedAdminDiv2Name == null ||
              !_currentAdminDiv2.any(
                (division) => division.name == _selectedAdminDiv2Name,
              )) {
            _selectedAdminDiv2Name = _currentAdminDiv2.isNotEmpty
                ? _currentAdminDiv2.first.name
                : null;
          }
        }

        // If no initial adminDiv1 selected, default to first item if available
        if (_selectedAdminDiv1Name == null && _allAdminDiv1.isNotEmpty) {
          _selectedAdminDiv1Name = _allAdminDiv1.first.name;
          _currentAdminDiv2 = _allAdminDiv1.first.children;
          _selectedAdminDiv2Name = _currentAdminDiv2.isNotEmpty
              ? _currentAdminDiv2.first.name
              : null;
        }

        _isLoading = false;
      });

      _notifyChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load address data from ${widget.assetPath}: $e';
      });
      print('Error loading local address data: $e');
    }
  }

  void _onAdminDiv1Changed(String? newAdminDiv1Name) {
    setState(() {
      _selectedAdminDiv1Name = newAdminDiv1Name;
      _selectedAdminDiv2Name = null;
      if (newAdminDiv1Name != null) {
        final selectedDiv1 = _allAdminDiv1.firstWhere(
          (div) => div.name == newAdminDiv1Name,
          orElse: () => AdministrativeDivision(name: '', children: []),
        );
        _currentAdminDiv2 = selectedDiv1.children;
      } else {
        _currentAdminDiv2 = [];
      }
    });
    _notifyChanged();
  }

  void _onAdminDiv2Changed(String? newAdminDiv2Name) {
    setState(() {
      _selectedAdminDiv2Name = newAdminDiv2Name;
    });
    _notifyChanged();
  }

  void _onConfirmPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedAdminDiv1Name == null || _selectedAdminDiv2Name == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select both ${widget.adminDiv1Label} and ${widget.adminDiv2Label}.',
            ),
          ),
        );
        return;
      }

      final confirmedAddress = _getCurrentAddress();
      if (confirmedAddress.fullName == null ||
          confirmedAddress.addressLine1 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required text fields.'),
          ),
        );
        return;
      }

      widget.onConfirmed?.call(confirmedAddress);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Address Confirmed! ${confirmedAddress.addressLine1}, ${confirmedAddress.city}',
          ),
        ),
      );
      print('Confirmed Address: ${confirmedAddress.toString()}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          'Error: $_errorMessage\nPlease ensure the asset path is correct and JSON is valid.',
        ),
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showFullName) ...[
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name / Recipient Name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) => value == null || value.isEmpty
                    ? 'Full Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
            ],

            if (widget.showOrganizationName) ...[
              TextFormField(
                controller: _organizationNameController,
                decoration: const InputDecoration(
                  labelText: 'Organization / Building Name (Optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 1 (Street / Plot / House Number)',
                hintText: 'e.g., 123 Main Street or Plot 45 Block A',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.streetAddress,
              validator: (value) => value == null || value.isEmpty
                  ? 'Address Line 1 is required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Address Line 2 (Apt, Suite, Floor - Optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.streetAddress,
            ),
            const SizedBox(height: 16),

            if (widget.showPostalCode) ...[
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code (Optional)',
                  hintText: 'e.g., 12345 (for 5-digit codes)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: widget.adminDiv1Label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              value: _selectedAdminDiv1Name,
              items: _allAdminDiv1.map((division) {
                return DropdownMenuItem(
                  value: division.name,
                  child: Text(division.name),
                );
              }).toList(),
              onChanged: _onAdminDiv1Changed,
              hint: Text('Select ${widget.adminDiv1Label}'),
              isExpanded: true,
              menuMaxHeight: 300,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${widget.adminDiv1Label} is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: widget.adminDiv2Label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              value: _selectedAdminDiv2Name,
              items: _currentAdminDiv2.map((division) {
                return DropdownMenuItem(
                  value: division.name,
                  child: Text(division.name),
                );
              }).toList(),
              onChanged:
                  (_selectedAdminDiv1Name != null &&
                      _currentAdminDiv2.isNotEmpty)
                  ? _onAdminDiv2Changed
                  : null,
              hint: Text('Select ${widget.adminDiv2Label}'),
              isExpanded: true,
              menuMaxHeight: 300,
              disabledHint: _selectedAdminDiv1Name == null
                  ? Text('Select a ${widget.adminDiv1Label} first')
                  : (_currentAdminDiv2.isEmpty
                        ? Text(
                            'No ${widget.adminDiv2Label}s found for this ${widget.adminDiv1Label}',
                          )
                        : null),
              validator: (value) {
                if (_selectedAdminDiv1Name != null &&
                    (value == null || value.isEmpty)) {
                  return '${widget.adminDiv2Label} is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (widget.showLandmark) ...[
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Landmark / Additional Description (Optional)',
                  hintText: 'e.g., near the main market, opposite the church',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.text,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
            ],

            if (widget.showConfirmButton)
              ElevatedButton(
                onPressed: _onConfirmPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Confirm Address'),
              ),
          ],
        ),
      ),
    );
  }
}
