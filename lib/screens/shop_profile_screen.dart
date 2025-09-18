import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _mottoController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _nameController = TextEditingController(text: settings.name);
    _addressController = TextEditingController(text: settings.address);
    _phoneController = TextEditingController(text: settings.phone ?? '');
    _mottoController = TextEditingController(text: settings.motto);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
      settings.setName(_nameController.text);
      settings.setAddress(_addressController.text);
      settings.setPhone(_phoneController.text);
      settings.setMotto(_mottoController.text);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shop profile saved!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Profile'),
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
          padding: const EdgeInsets.all(8.0),
          children: [
            _buildLogoSection(context, settings),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Toko'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Toko',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mottoController,
                      decoration: const InputDecoration(
                        labelText: 'Motto/Catatan Kaki Struk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, SettingsProvider settings) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Logo Toko',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
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
                        : const Center(
                          child: Icon(Icons.add_a_photo, size: 40),
                        ),
              ),
            ),
            if (settings.logoPath != null)
              TextButton.icon(
                onPressed: () {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).removeLogo();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Hapus Logo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
