import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'location_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  late final Client client;
  late final Databases databases;

  final String databaseId = "mahllnadb";
  final String collectionId = "clients";

  @override
  void initState() {
    super.initState();
    client = Client()
        .setEndpoint("https://fra.cloud.appwrite.io/v1")
        .setProject("6887ee78000e74d711f1");
    databases = Databases(client);
  }

  Future<void> _signUp() async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          "name": nameController.text,
          "email": emailController.text,
          "password": passwordController.text,
        },
      );
      _showMessage("تم إنشاء الحساب بنجاح، يمكنك تسجيل الدخول الآن");
      setState(() => isLogin = true);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _login() async {
    try {
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal("email", emailController.text),
          Query.equal("password", passwordController.text),
        ],
      );

      if (result.documents.isNotEmpty) {
        // حفظ بيانات المستخدم في SharedPreferences
        final userData = result.documents.first.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', result.documents.first.$id);
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);

        _showMessage("تم تسجيل الدخول بنجاح");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LocationScreen()),
        );
      } else {
        _showError("البريد أو كلمة المرور غير صحيحة");
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loginAsGuest() async {
    try {
      // مسح أي بيانات مستخدم سابقة عند الدخول كضيف
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationScreen()),
      );
    } catch (e) {
      _showError("حدث خطأ أثناء الدخول كضيف: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.redAccent)),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  isLogin ? "تسجيل الدخول" : "إنشاء حساب",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                if (!isLogin)
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "الاسم",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) => v!.isEmpty ? "ادخل الاسم" : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "البريد الإلكتروني",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v!.isEmpty ? "ادخل البريد" : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) => v!.length < 6
                      ? "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      isLogin ? _login() : _signUp();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    isLogin ? "تسجيل الدخول" : "إنشاء حساب",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loginAsGuest,
                  child: const Text(
                    "الدخول كضيف",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? "ليس لديك حساب؟ سجل الآن" : "لديك حساب؟ سجل دخول",
                    style: const TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
