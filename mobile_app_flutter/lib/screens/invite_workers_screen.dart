import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '/services/permission_service.dart'; // Our permission service
import '../services/api_provider.dart'; // Our mock API service
import '../../services/api_service_selector.dart'; // Adjust path as needed
import '../../services/user_session_provider.dart';
import 'package:provider/provider.dart'; // Import for Provider

class WorkerInvitationScreen extends StatefulWidget {
  const WorkerInvitationScreen({super.key});

  @override
  State<WorkerInvitationScreen> createState() => _WorkerInvitationScreenState();
}

class _WorkerInvitationScreenState extends State<WorkerInvitationScreen>
    with SingleTickerProviderStateMixin {
 final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<String> _selectedPhoneNumbers = [];
  List<Contact> _contacts = [];
  bool _isLoading = false;
  final ApiProvider apiService = ApiServiceSelector().switchTo(ApiMode.dummy);

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
      });
    }
  }

  void _addPhoneNumber(String phoneNumber) {
    final localizations = AppLocalizations.of(context)!;
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneNumber.isEmpty || phoneNumber.length < 8) {
      _showSnackBar(localizations.invalidPhoneNumber);
      return;
    }

    if (!_selectedPhoneNumbers.contains(phoneNumber)) {
      setState(() {
        _selectedPhoneNumbers.add(phoneNumber);
        _phoneController.clear();
      });
    } else {
      _showSnackBar(localizations.phoneNumberAlreadyAdded);
    }
  }

  Future<void> _sendInvites() async {
    final localizations = AppLocalizations.of(context)!;
    final sessionProvider = Provider.of<UserSessionProvider>(context, listen: false);
    final shopId = sessionProvider.shopId;
    final userId = sessionProvider.userId;

    if (shopId == null || userId == null) {
      _showSnackBar('Missing shop ID or user ID.');
      return;
    }

    if (_selectedPhoneNumbers.isEmpty) {
      _showSnackBar(localizations.noPhoneNumberSelected);
      return;
    }

    setState(() => _isLoading = true);

    for (final phone in _selectedPhoneNumbers) {
      final result = await apiService.inviteWorker(
        shopId: shopId,
        name: phone,
        phone: phone,
      );

      if (result['success'] == true) {
        _showSnackBar(localizations.inviteSentSuccessfully(phone));
      } else {
        _showSnackBar(localizations.inviteFailed(phone));
      }
    }

    setState(() {
      _selectedPhoneNumbers.clear();
      _isLoading = false;
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final filteredContacts = _contacts.where((contact) {
      final query = _searchController.text.toLowerCase();
      return contact.displayName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(localizations.inviteWorker)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Mohamed ...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (_, index) {
                    final contact = filteredContacts[index];
                    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(contact.displayName),
                      subtitle: Text(phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: phone.isNotEmpty
                            ? () => _addPhoneNumber(phone)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g., 0712345678',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addPhoneNumber(_phoneController.text),
                    icon: const Icon(Icons.add),
                    label: Text(''),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedPhoneNumbers.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.selectedContacts, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedPhoneNumbers.map((phone) {
                        return Chip(
                          label: Text(phone),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              _selectedPhoneNumbers.remove(phone);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _sendInvites,
                  icon: const Icon(Icons.send),
                  label: Text(localizations.sendInvite),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        ),
      ),
    );
  }
}
