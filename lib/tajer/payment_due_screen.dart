import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentDueScreen extends StatelessWidget {
  const PaymentDueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Uri whatsappUrl = Uri.parse('https://wa.me/9647882948833');

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر غير فعال'),
        // زر العودة يعود إلى شاشة تسجيل الدخول
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'متجرك غير فعال حاليًا.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'الرجاء التواصل مع الدعم الفني لتفعيل المتجر وتجديد اشتراكك.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl);
                    // العودة إلى شاشة تسجيل الدخول بعد فتح واتساب
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تعذر فتح واتساب. يرجى التحقق من تثبيته.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(FontAwesomeIcons.whatsapp),
                label: const Text('تواصل على واتساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
