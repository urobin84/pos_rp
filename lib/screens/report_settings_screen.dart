import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ReportSettingsScreen extends StatefulWidget {
  const ReportSettingsScreen({super.key});

  @override
  State<ReportSettingsScreen> createState() => _ReportSettingsScreenState();
}

class _ReportSettingsScreenState extends State<ReportSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _mottoController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _addressController = TextEditingController(text: settings.address);
    _mottoController = TextEditingController(text: settings.motto);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mottoController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.setLogo(File(pickedFile.path));
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.setAddress(_addressController.text);
      settings.setMotto(_mottoController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Template Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Logo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      settings.logoPath != null &&
                              File(settings.logoPath!).existsSync()
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(
                              File(settings.logoPath!),
                              fit: BoxFit.contain,
                            ),
                          )
                          : const Center(child: Icon(Icons.add_a_photo)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Store Address',
                border: OutlineInputBorder(),
                helperText: 'This will appear at the top of the receipt.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mottoController,
              decoration: const InputDecoration(
                labelText: 'Closing Motto',
                border: OutlineInputBorder(),
                helperText: 'e.g., "Terima Kasih!"',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
