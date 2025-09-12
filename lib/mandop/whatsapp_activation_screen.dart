import 'package:appfotajer/mandop/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../appwrite_service.dart';
// تأكد من استدعاء صفحة تسجيل الدخول للمندوب

class WhatsAppActivationScreen extends StatelessWidget {
  const WhatsAppActivationScreen({super.key});

  Future<void> _openWhatsApp() async {
    const phone = "+9647882948833"; // رقمك الصحيح
    final url = Uri.parse("https://wa.me/$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفعيل الحساب')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'تم إنشاء حسابك بنجاح ✅\n\nالرجاء التواصل معنا عبر واتساب لتفعيل الحساب ومتابعة الإجراءات.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openWhatsApp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              label: const Text(
                'فتح واتساب الآن',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // العودة لشاشة تسجيل الدخول مع تمرير البراميترين المطلوبين
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MandopLoginScreen(
                      databases: AppwriteService.databases,
                      storage: AppwriteService.storage,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'العودة لتسجيل الدخول',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
