// lib/widgets/phone_input_field.dart

import 'package:flutter/material.dart';

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String countryCode;
  final FormFieldValidator<String>? validator;

  const PhoneInput({
    Key? key,
    required this.controller,
    this.label = 'Phone Number',
    this.hint = '7XXXXXXXX',
    this.countryCode = '+255',
    this.validator,
  }) : super(key: key);

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.trim();
    final regex = RegExp(r'^[7]\d{8}$'); // Tanzanian 9-digit local number starting with 7
    if (!regex.hasMatch(phone)) {
      return 'Enter a valid Tanzanian phone number starting with 7';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$countryCode ',
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      validator: validator ?? _defaultValidator,
    );
  }
}
