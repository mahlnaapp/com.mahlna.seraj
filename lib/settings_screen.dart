// ===================== مكتبات أساسية ===================== //
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mandop/app_constants.dart';
import '../mandop/delivery_provider.dart';
import '../appwrite_service.dart';
import '../mandop/main_delivery_screen.dart';
import '../mandop/whatsapp_activation_screen.dart';
import '../tajer/login_screen.dart';
import 'location_screen.dart';

// ===================== شاشة تسجيل دخول المندوب ===================== //
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
          );
        }
        return;
      }

      final agentData = response.documents.first;
      final agentZoneId = agentData.data['zoneId'] as String?;
      final agentId = agentData.$id;
      final loginAllowed = agentData.data['loginAllowed'] as bool? ?? false;

      if (!loginAllowed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WhatsAppActivationScreen()),
          );
        }
        return;
      }

      if (agentZoneId != null) {
        final deliveryProvider = Provider.of<DeliveryProvider>(
          context,
          listen: false,
        );
        await deliveryProvider.loadAgentDashboardData(agentId);

        if (mounted) {
          deliveryProvider.setCurrentAgentId(agentId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MainDeliveryScreen(zoneId: agentZoneId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ: لم يتم العثور على منطقة للمندوب'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

// ===================== شاشة الإعدادات ===================== //
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('darkMode', _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('تغيير القاطع أو الموقع'),
            leading: const Icon(Icons.location_city, color: Colors.orange),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('selectedZoneId');
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationScreen()),
                );
              }
            },
          ),
          ListTile(
            title: const Text('معلومات طلباتك'),
            leading: const Icon(Icons.person_outline, color: Colors.orange),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderInfoScreen()),
              );
            },
          ),
          SwitchListTile(
            title: const Text('الإشعارات'),
            value: _notifications,
            onChanged: (value) {
              setState(() => _notifications = value);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('الوضع المظلم'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('سياسة الخصوصية'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            title: const Text('الشروط والأحكام'),
            leading: const Icon(Icons.description),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          ListTile(
            title: const Text('اتصل بنا'),
            leading: const Icon(Icons.contact_support),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUsScreen()),
            ),
          ),
          ListTile(
            title: const Text('حول التطبيق'),
            leading: const Icon(Icons.info),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          ListTile(
            title: const Text('تطبيق التاجر'),
            leading: const Icon(Icons.store),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    databases: AppwriteService.databases,
                    storage: AppwriteService.storage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================== شاشة معلومات الطلب ===================== //
class OrderInfoScreen extends StatefulWidget {
  const OrderInfoScreen({super.key});

  @override
  State<OrderInfoScreen> createState() => _OrderInfoScreenState();
}

class _OrderInfoScreenState extends State<OrderInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('checkout_name') ?? '';
      _phoneController.text = prefs.getString('checkout_phone') ?? '';
      _notesController.text = prefs.getString('checkout_notes') ?? '';
      _landmarkController.text = prefs.getString('checkout_landmark') ?? '';
    });
  }

  Future<void> _saveInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkout_name', _nameController.text);
    await prefs.setString('checkout_phone', _phoneController.text);
    await prefs.setString('checkout_notes', _notesController.text);
    await prefs.setString('checkout_landmark', _landmarkController.text);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المعلومات بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات طلباتك')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'أقرب نقطة دالة',
                prefixIcon: Icon(Icons.location_pin),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'حفظ المعلومات',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== باقي الشاشات (سياسة الخصوصية، الشروط، اتصل بنا، حول التطبيق، الأسئلة الشائعة، الاسترداد) ===================== //
// ... سأكمل بقية الشاشات بنفس الأسلوب إذا أحببت، مع فصل كل شاشة لسهولة الصيانة
// ===================== شاشة سياسة الخصوصية ===================== //
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. المعلومات التي نجمعها',
              '- بيانات الموقع لتحديد المتاجر القريبة\n'
                  '- معلومات الطلبات (المتجر، المنتجات، المبلغ)\n'
                  '- بيانات الاتصال عند الطلب (الاسم، الهاتف، العنوان)\n'
                  '- لا نخزن بيانات الدفع البنكية',
            ),
            _buildSection(
              '2. كيفية استخدام البيانات',
              '- تنفيذ عمليات الشراء والتوصيل\n'
                  '- تحسين تجربة المستخدم\n'
                  '- التواصل معك عند الضرورة',
            ),
            _buildSection(
              '3. الحماية والأمان',
              '- نستخدم تشفير SSL لحماية البيانات\n'
                  '- لا نشارك بياناتك مع أطراف ثالثة إلا للضرورة القانونية',
            ),
            _buildSection(
              '4. حقوقك',
              '- يمكنك طلب تصحيح أو حذف بياناتك\n'
                  '- إلغاء الاشتراك من الإعلانات',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ===================== شاشة الشروط والأحكام ===================== //
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والأحكام')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''1. القبول: باستخدامك التطبيق، فإنك توافق على هذه الشروط.
2. الطلبات:
   - الأسعار قد تتغير حسب المتجر.
   - يمكن إلغاء الطلب خلال ساعة من تقديمه.
3. المسؤولية:
   - جودة المنتجات هي مسؤولية المتجر.
   - نضمن فقط عملية التوصيل.
4. الحساب:
   - يجب أن تكون معلوماتك صحيحة وكاملة.
   - يحق لنا تعليق الحساب عند المخالفة.
5. التعديلات: سيتم إعلامك بأي تغييرات عبر التطبيق.''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ===================== شاشة اتصل بنا ===================== //
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتصل بنا')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildContactCard(
              icon: Icons.email,
              title: 'البريد الإلكتروني',
              subtitle: 'isyrajcomp@gmail.com',
              onTap: () => _launchUrl('mailto:isyrajcomp@gmail.com'),
            ),
            _buildContactCard(
              icon: Icons.phone,
              title: 'الهاتف',
              subtitle: '+9647882948833',
              onTap: () => _launchUrl('tel:+9647882948833'),
            ),
            _buildContactCard(
              icon: Icons.location_on,
              title: 'المقر الرئيسي',
              subtitle: 'الموصل، العراق',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

// ===================== شاشة حول التطبيق ===================== //
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Icon(Icons.shopping_basket, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'تطبيق محلنا',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'الإصدار: 1.0.0\nتاريخ الإصدار: 2025-8-01\n\n© 2025 جميع الحقوق محفوظة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'طورنا هذا التطبيق لتسهيل عملية التسوق والتوصيل من المتاجر المحلية في مدينتك.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== شاشة الأسئلة الشائعة ===================== //
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأسئلة الشائعة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQuestion(
              question: 'كيف أتتبع طلبي؟',
              answer: 'انتقل إلى قسم "طلباتي" واختر الطلب لرؤية حالته.',
            ),
            _buildQuestion(
              question: 'ما وقت التوصيل المتوقع؟',
              answer: 'من 30 دقيقة إلى ساعتين حسب الموقع والازدحام.',
            ),
            _buildQuestion(
              question: 'هل يمكنني إلغاء الطلب؟',
              answer: 'نعم، خلال 60 دقيقة من تقديم الطلب.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [ListTile(title: Text(answer))],
    );
  }
}

// ===================== شاشة سياسة الاسترداد ===================== //
class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الاسترداد')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''1. طلبات الإرجاع:
   - يمكنك طلب إرجاع المنتج خلال 24 ساعة من الاستلام.
2. الشروط:
   - يجب أن يكون المنتج في حالته الأصلية.
   - يُستثنى: المواد الغذائية الطازجة.
3. طريقة الاسترداد:
   - سيتم إرجاع المبلغ خلال 3-5 أيام عمل بنفس طريقة الدفع.''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
