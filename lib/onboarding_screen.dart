// File: onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart'; // استدعاء صفحة AuthScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: "كل الي تريده",
      description: "اطلب من متجرك الي متعود عليه",
      image: "assets/images/onboarding1.png",
    ),
    OnboardingItem(
      title: "توصيل مجاني طبعاً",
      description: "كل الطلبيات بتوصيل مجاني ضمن نطاق خمسة كيلو متر",
      image: "assets/images/onboarding2.png",
    ),
    OnboardingItem(
      title: "شوف الي يعجبك",
      description: "تصفح الي تريده واطلبه واحنا نوصله الك لباب البيت",
      image: "assets/images/onboarding3.png",
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true); // حفظ الحالة

    // الانتقال إلى شاشة المصادقة باستخدام pushReplacement
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) =>
                OnboardingPage(item: _pages[index]),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildPageIndicator(),
                const SizedBox(height: 20),
                _buildNextButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: _currentPage == index ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.orangeAccent
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 6,
        ),
        onPressed: () {
          if (_currentPage < _pages.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
          } else {
            _completeOnboarding();
          }
        },
        child: Text(
          _currentPage == _pages.length - 1 ? "ابدأ الآن" : "التالي",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(item.image, height: 280),
          const SizedBox(height: 40),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String image;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}
