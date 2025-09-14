import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tajer/merchant_provider.dart';
import 'merchant_dashboard.dart';
import 'payment_due_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const LoginScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final res = await widget.databases.listDocuments(
          databaseId: 'mahllnadb',
          collectionId: 'Stores',
          queries: [
            Query.equal('name', _nameController.text),
            Query.equal('stpass', _passController.text),
          ],
        );

        if (res.documents.isNotEmpty) {
          final storeData = res.documents.first.data;
          final storeStatus = storeData['is_active'] ?? false;

          if (storeStatus) {
            final storeId = res.documents.first.$id;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('storeId', storeId);

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                    create: (_) => MerchantProvider(
                      widget.databases,
                      widget.storage,
                      storeId,
                    ),
                    child: MerchantDashboard(
                      databases: widget.databases,
                      storage: widget.storage,
                    ),
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PaymentDueScreen()),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('اسم المستخدم أو كلمة المرور غير صحيحة'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Login Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ في تسجيل الدخول: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAccessCodeAndNavigate() async {
    final codeController = TextEditingController();

    bool? allowed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال الرمز للوصول'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'ادخل الرمز للوصول'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // إلغاء
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text == '1212') {
                Navigator.of(context).pop(true); // السماح بالدخول
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('الرمز غير صحيح')));
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (allowed == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterScreen(
            databases: widget.databases,
            storage: widget.storage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول التاجر')),
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
                      onPressed: _login,
                      child: const Text('تسجيل الدخول'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _checkAccessCodeAndNavigate,
                child: const Text('إنشاء حساب جديد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
