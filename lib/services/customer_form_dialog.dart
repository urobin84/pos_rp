import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_rp/models/customer_model.dart';
import 'package:pos_rp/providers/customer_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;

  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;
  late String _address;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _name = widget.customer!.name;
      _email = widget.customer!.email;
      _phone = widget.customer!.phone;
      _address = widget.customer!.address;
      _dateOfBirth = widget.customer!.dateOfBirth;
    } else {
      _name = '';
      _email = '';
      _phone = '';
      _address = '';
      _dateOfBirth = null;
    }
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _formKey.currentState!.save();

    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final navigator = Navigator.of(context);

    if (widget.customer != null) {
      final updatedCustomer = Customer(
        id: widget.customer!.id,
        name: _name,
        email: _email,
        phone: _phone,
        address: _address,
        dateOfBirth: _dateOfBirth,
        registrationDate: widget.customer!.registrationDate,
      );
      await customerProvider.updateCustomer(updatedCustomer);
    } else {
      final newCustomer = Customer(
        id: const Uuid().v4(),
        name: _name,
        email: _email,
        phone: _phone,
        address: _address,
        dateOfBirth: _dateOfBirth,
        registrationDate: DateTime.now(),
      );
      await customerProvider.addCustomer(newCustomer);
    }

    navigator.pop();
  }

  Future<void> _pickDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirth = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 20.0),
          child: Text(
            widget.customer == null ? 'Add Customer' : 'Edit Customer',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter a name.' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Please enter a phone number.'
                                : null,
                    onSaved: (value) => _phone = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => _address = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date of Birth'),
                    subtitle: Text(
                      _dateOfBirth == null
                          ? 'Not set'
                          : DateFormat('d MMM yyyy').format(_dateOfBirth!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDateOfBirth,
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
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveForm, child: const Text('Save')),
            ],
          ),
        ),
      ],
    );
  }
}
