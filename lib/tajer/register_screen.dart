import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:uuid/uuid.dart';

import 'activation_screen.dart'; // Import the new activation screen

class RegisterScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const RegisterScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final res = await widget.databases.listDocuments(
          databaseId: 'mahllnadb',
          collectionId: 'storesowner',
          queries: [Query.equal('stname', _nameController.text)],
        );

        if (res.documents.isNotEmpty) {
          // A store with this name already exists, which means it's a valid account
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم العثور على حسابك. يمكنك تسجيل الدخول الآن!'),
              ),
            );
            Navigator.pop(context); // Go back to the login screen
          }
        } else {
          // No store found, create a new one with is_active = false
          const uuid = Uuid();
          final newStoreId = uuid.v4();
          await widget.databases.createDocument(
            databaseId: 'mahllnadb',
            collectionId: 'storesowner',
            documentId: newStoreId,
            data: {
              'stid': newStoreId,
              'stname': _nameController.text,
              'stpass': _passController.text,
              'is_active': false,
            },
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ActivationScreen()),
            );
          }
        }
      } catch (e) {
        debugPrint('Registration Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ في إنشاء الحساب: ${e.toString()}')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال كلمة المرور' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('إنشاء الحساب'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
