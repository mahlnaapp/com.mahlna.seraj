import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mandop/app_constants.dart';
import '../appwrite_service.dart';
import 'main_delivery_screen.dart';
import 'whatsapp_activation_screen.dart';
import 'delivery_provider.dart';

class MandopLoginScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const MandopLoginScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<MandopLoginScreen> createState() => _MandopLoginScreenState();
}

class _MandopLoginScreenState extends State<MandopLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAgentId = prefs.getString('agentId');
    final savedZoneId = prefs.getString('agentZoneId');

    if (savedAgentId != null && savedZoneId != null && savedZoneId.isNotEmpty) {
      final deliveryProvider = Provider.of<DeliveryProvider>(
        context,
        listen: false,
      );
      deliveryProvider.setCurrentAgentId(savedAgentId);
      await deliveryProvider.loadAllOrders(zoneId: savedZoneId);
      deliveryProvider.startRealtimeListener(zoneId: savedZoneId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainDeliveryScreen(zoneId: savedZoneId),
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await widget.databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.agentsCollectionId,
        queries: [
          Query.equal('agentName', _usernameController.text),
          Query.equal('agentPassword', _passwordController.text),
        ],
      );

      if (response.documents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
        );
        return;
      }

      final agentData = response.documents.first;
      final agentId = agentData.$id;
      final agentZoneId = agentData.data['zoneId'] as String?;
      final loginAllowed = agentData.data['loginAllowed'] as bool? ?? false;

      final deliveryProvider = Provider.of<DeliveryProvider>(
        context,
        listen: false,
      );
      deliveryProvider.setCurrentAgentId(agentId);
      await deliveryProvider.loadAgentDashboardData(agentId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agentId', agentId);
      await prefs.setString('agentZoneId', agentZoneId ?? '');

      if (!loginAllowed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WhatsAppActivationScreen()),
        );
        return;
      }

      if (agentZoneId != null) {
        await deliveryProvider.loadAllOrders(zoneId: agentZoneId);
        deliveryProvider.startRealtimeListener(zoneId: agentZoneId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDeliveryScreen(zoneId: agentZoneId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ: لم يتم العثور على منطقة المندوب')),
        );
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول المندوب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تسجيل الدخول'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
