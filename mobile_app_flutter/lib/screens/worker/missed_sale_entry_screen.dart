import 'package:flutter/material.dart';

class MissedSaleEntryScreen extends StatefulWidget {
  const MissedSaleEntryScreen({Key? key}) : super(key: key);

  @override
  State<MissedSaleEntryScreen> createState() => _MissedSaleEntryScreenState();
}

class _MissedSaleEntryScreenState extends State<MissedSaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  int quantityRequested = 0;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: API call to submit missed sale entry
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing item recorded!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Missing Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter product name' : null,
                onSaved: (val) => productName = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Quantity Requested'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter quantity';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
                onSaved: (val) => quantityRequested = int.parse(val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
