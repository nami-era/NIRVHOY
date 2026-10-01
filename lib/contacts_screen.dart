import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> contacts = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    String? contactsString = prefs.getString('emergency_contacts');
    if (contactsString != null) {
      List<dynamic> decodedList = jsonDecode(contactsString);
      setState(() {
        contacts = decodedList.map((item) => Map<String, String>.from(item)).toList();
      });
    } else {
      setState(() {
        contacts = [
          {'name': 'Father', 'phone': '+8801712345678'},
          {'name': 'Mother', 'phone': '+8801812345678'},
          {'name': 'National Helpline', 'phone': '999'},
        ];
      });
      _saveContactsToStorage();
    }
  }

  Future<void> _saveContactsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedList = jsonEncode(contacts);
    await prefs.setString('emergency_contacts', encodedList);
  }

  void _addContact() {
    if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
      setState(() {
        contacts.add({
          'name': nameController.text,
          'phone': phoneController.text,
        });
      });
      _saveContactsToStorage();
      nameController.clear();
      phoneController.clear();
      Navigator.pop(context);
    }
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });
    _saveContactsToStorage();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Contact Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: _addContact,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Emergency Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: contacts.isEmpty
          ? const Center(child: Text('No emergency contacts added yet.'))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(contacts[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(contacts[index]['phone']!),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteContact(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}