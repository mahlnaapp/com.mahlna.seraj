import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cart_provider.dart';
import 'onboarding_screen.dart';
import 'location_screen.dart';
import 'delivery_screen.dart';
import 'store_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'orders_screen.dart';
import 'orders_provider.dart';
import 'appwrite_service.dart';
import 'store_service.dart';
import 'order_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.init();
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        Provider(create: (_) => StoreService(AppwriteService.databases)),
        Provider(create: (_) => OrderService(AppwriteService.databases)),
      ],
      child: MyApp(showOnboarding: !seenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق محلنا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: showOnboarding ? '/' : '/location',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/location': (context) => const LocationScreen(),
        '/delivery': (context) => const DeliveryScreen(deliveryCity: "الموصل"),
        '/store': (context) => StoreScreen(storeName: "متجر", storeId: "1"),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => CheckoutScreen(
          totalAmount: Provider.of<CartProvider>(context).totalPrice,
        ),
        '/orders': (context) => const OrdersScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/terms': (context) => const TermsScreen(),
        '/contact': (context) => const ContactUsScreen(),
        '/about': (context) => const AboutScreen(),
        '/faq': (context) => const FaqScreen(),
        '/refund': (context) => const RefundPolicyScreen(),
      },
    );
  }
}

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

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والأحكام')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('''
1. القبول:
باستخدامك التطبيق، فإنك توافق على هذه الشروط.

2. الطلبات:
- الأسعار قد تتغير حسب المتجر.
- يمكن إلغاء الطلب خلال ساعة من تقديمه.

3. المسؤولية:
- جودة المنتجات هي مسؤولية المتجر.
- نضمن فقط عملية التوصيل.

4. الحساب:
- يجب أن تكون معلوماتك صحيحة وكاملة.
- يحق لنا تعليق الحساب عند المخالفة.

5. التعديلات:
سيتم إعلامك بأي تغييرات عبر التطبيق.
''', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.shopping_basket, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'تطبيق محلنا',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'الإصدار: 1.0.0\n'
              'تاريخ الإصدار: 2025-8-01\n'
              '\n'
              '© 2025 جميع الحقوق محفوظة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Padding(
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

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الاسترداد')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('''
1. طلبات الإرجاع:
- يمكنك طلب إرجاع المنتج خلال 24 ساعة من الاستلام.

2. الشروط:
- يجب أن يكون المنتج في حالته الأصلية.
- يُستثنى: المواد الغذائية الطازجة.

3. طريقة الاسترداد:
- سيتم إرجاع المبلغ خلال 3-5 أيام عمل بنفس طريقة الدفع.
''', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

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
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('الشروط والأحكام'),
            leading: const Icon(Icons.description),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
          ),
          ListTile(
            title: const Text('اتصل بنا'),
            leading: const Icon(Icons.contact_support),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactUsScreen()),
            ),
          ),
          ListTile(
            title: const Text('حول التطبيق'),
            leading: const Icon(Icons.info),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
