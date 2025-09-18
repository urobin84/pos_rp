import 'package:flutter/material.dart';
import 'package:pos_rp/models/supplier_model.dart';
import 'package:pos_rp/providers/supplier_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _contactPerson;
  late String _phone;
  late String _email;
  late String _address;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _name = widget.supplier!.name;
      _contactPerson = widget.supplier!.contactPerson;
      _phone = widget.supplier!.phone;
      _email = widget.supplier!.email;
      _address = widget.supplier!.address;
    } else {
      _name = '';
      _contactPerson = '';
      _phone = '';
      _email = '';
      _address = '';
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final supplierProvider = Provider.of<SupplierProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    if (widget.supplier != null) {
      final updatedSupplier = Supplier(
        id: widget.supplier!.id,
        name: _name,
        contactPerson: _contactPerson,
        phone: _phone,
        email: _email,
        address: _address,
      );
      await supplierProvider.updateSupplier(updatedSupplier);
    } else {
      final newSupplier = Supplier(
        id: const Uuid().v4(),
        name: _name,
        contactPerson: _contactPerson,
        phone: _phone,
        email: _email,
        address: _address,
      );
      await supplierProvider.addSupplier(newSupplier);
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Text(
            widget.supplier == null ? 'Tambah Supplier' : 'Edit Supplier',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nama Supplier',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Nama tidak boleh kosong.' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _contactPerson,
                    decoration: const InputDecoration(labelText: 'Narahubung'),
                    onSaved: (value) => _contactPerson = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(labelText: 'Telepon'),
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phone = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _address,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    maxLines: 2,
                    onSaved: (value) => _address = value ?? '',
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveForm, child: const Text('Simpan')),
            ],
          ),
        ),
      ],
    );
  }
}
