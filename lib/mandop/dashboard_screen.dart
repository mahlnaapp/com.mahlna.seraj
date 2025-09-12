import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mandop/delivery_provider.dart';
import 'whatsapp_activation_screen.dart';
import 'package:appwrite/appwrite.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  int _daysLeft = 30;

  late final Client _client;
  late final Databases _databases;

  @override
  void initState() {
    super.initState();

    // إعداد Appwrite Client
    _client = Client()
        .setEndpoint('https://fra.cloud.appwrite.io/v1') // رابط Appwrite
        .setProject('6887ee78000e74d711f1'); // معرف المشروع
    _databases = Databases(_client);

    _loadSavedAgent();
  }

  Future<void> _loadSavedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final agentId = prefs.getString('currentAgentId');
    final agentName = prefs.getString('currentAgentName');
    final agentZone = prefs.getString('currentAgentZone');

    if (agentId != null) {
      final provider = Provider.of<DeliveryProvider>(context, listen: false);
      provider.setCurrentAgent(
        agentId: agentId,
        agentName: agentName,
        agentZoneName: agentZone,
      );

      // بدء العد التنازلي
      _startCountdown(agentId);
    }
  }

  Future<void> _startCountdown(String? agentId) async {
    if (agentId == null) return;

    try {
      final agentDocument = await _databases.getDocument(
        databaseId: 'mahllnadb',
        collectionId: 'DeliveryAgents',
        documentId: agentId,
      );

      final loginAllowed = agentDocument.data['loginAllowed'] as bool? ?? false;
      final startMillis = agentDocument.data['subscriptionStart'] as int?;

      if (!loginAllowed || startMillis == null) return;

      _updateDaysLeft(startMillis);

      // تحديث العد كل ساعة
      _timer = Timer.periodic(const Duration(hours: 1), (_) {
        _updateDaysLeft(startMillis);
      });
    } catch (e) {
      debugPrint('Error fetching agent data: $e');
    }
  }

  Future<void> _updateDaysLeft(int startMillis) async {
    final startDate = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final daysLeft = 30 - daysPassed;

    if (daysLeft <= 0) {
      _timer?.cancel();

      final provider = Provider.of<DeliveryProvider>(context, listen: false);
      final agentId = provider.currentAgentId;
      if (agentId != null) {
        try {
          await _databases.updateDocument(
            databaseId: 'mahllnadb',
            collectionId: 'DeliveryAgents',
            documentId: agentId,
            data: {'loginAllowed': false},
          );
        } catch (e) {
          debugPrint('Error updating loginAllowed: $e');
        }
      }

      _redirectToWhatsApp();
    } else {
      setState(() {
        _daysLeft = daysLeft;
      });
    }
  }

  void _redirectToWhatsApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WhatsAppActivationScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(
                  'مرحباً بك',
                  provider.currentAgentName ?? 'المندوب',
                  Icons.person,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'المنطقة',
                  provider.currentAgentZoneName ?? 'غير محدد',
                  Icons.location_on,
                  Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'الطلبات المكتملة',
                  provider.completedOrders.length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'إجمالي الأرباح',
                  NumberFormat.currency(
                    symbol: 'د.ع',
                    decimalDigits: 0,
                  ).format(provider.totalEarnings),
                  Icons.monetization_on,
                  Colors.teal,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'الأيام المتبقية للاشتراك',
                  '$_daysLeft',
                  Icons.timer,
                  Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
