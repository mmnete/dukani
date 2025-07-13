import 'package:flutter/material.dart';

class SaleEntryScreen extends StatefulWidget {
  const SaleEntryScreen({Key? key}) : super(key: key);

  @override
  State<SaleEntryScreen> createState() => _SaleEntryScreenState();
}

class _SaleEntryScreenState extends State<SaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  int quantity = 0;
  double sellingPrice = 0.0;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: API call to submit sale entry
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale')),
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
                decoration: const InputDecoration(labelText: 'Quantity Sold'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter quantity';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
                onSaved: (val) => quantity = int.parse(val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Selling Price (TZS)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter price';
                  if (double.tryParse(val) == null) return 'Enter valid price';
                  return null;
                },
                onSaved: (val) => sellingPrice = double.parse(val!),
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
