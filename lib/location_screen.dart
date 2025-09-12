// File: location_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:appwrite/appwrite.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔹 استيراد المكتبة
import 'delivery_screen.dart';
import 'dart:async';
import 'cart_provider.dart'; // 🔹 استيراد CartProvider

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = true;

  List<Map<String, dynamic>> _neighborhoods = [];
  List<Map<String, dynamic>> _filteredNeighborhoods = [];
  String _searchText = '';

  late Client _client;
  late Databases _databases;

  @override
  void initState() {
    super.initState();
    _setupAppwrite();
    _checkSavedZone(); // 🔹 استدعاء الدالة الجديدة عند بدء التشغيل
  }

  void _setupAppwrite() {
    _client = Client();
    _client
        .setEndpoint('https://fra.cloud.appwrite.io/v1')
        .setProject('6887ee78000e74d711f1');
    _databases = Databases(_client);
    _loadNeighborhoods();
  }

  // 🔹 دالة جديدة للتحقق من zoneId المحفوظ
  Future<void> _checkSavedZone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedZoneId = prefs.getString('selectedZoneId');

    if (savedZoneId != null && mounted) {
      // إذا كان هناك zoneId محفوظ، انتقل مباشرة إلى شاشة التوصيل
      // يمكنك تمرير اسم المدينة الافتراضي هنا
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryScreen(
            deliveryCity: 'الموصل', // يمكنك تعديل هذه القيمة حسب الحاجة
            zoneId: savedZoneId,
          ),
        ),
      );
    } else {
      // إذا لم يكن هناك zoneId محفوظ، أكمل عملية التحقق من الموقع
      _checkLocationPermission();
    }
  }

  Future<void> _loadNeighborhoods() async {
    try {
      final result = await _databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'zoneid',
      );

      setState(() {
        // كل وثيقة تحتوي على اسم القاطع والمناطق التابعة له
        _neighborhoods = result.documents
            .map(
              (doc) => {
                'zone': doc.data['name'],
                'neighborhoods': List<String>.from(
                  doc.data['neighborhoods'] ?? [],
                ),
              },
            )
            .toList();

        // في البداية، نعرض كل المناطق
        _filteredNeighborhoods = _neighborhoods
            .expand(
              (zone) => (zone['neighborhoods'] as List<String>).map(
                (name) => {'zone': zone['zone'], 'name': name},
              ),
            )
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _neighborhoods = [];
        _filteredNeighborhoods = [];
        _isLoading = false;
      });
      print('فشل في جلب المناطق: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus(
          "الموقع معطل. الرجاء تفعيله في الإعدادات",
          isDeniedForever: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateStatus("تم رفض إذن الموقع", isDeniedForever: false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateStatus(
          "الإذن مرفوض دائمًا. الرجاء تغييره في الإعدادات",
          isDeniedForever: true,
        );
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      _updateStatus(
        "حدث خطأ أثناء التحقق من الصلاحيات: ${e.toString()}",
        isDeniedForever: false,
      );
    }
  }

  void _updateStatus(String message, {required bool isDeniedForever}) {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DeliveryScreen(deliveryCity: "تلقائي"),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } on TimeoutException {
      _updateStatus(
        "استغرقت عملية تحديد الموقع وقتًا طويلاً",
        isDeniedForever: false,
      );
    } catch (e) {
      _updateStatus(
        "فشل في الحصول على الموقع: ${e.toString()}",
        isDeniedForever: false,
      );
    }
  }

  void _filterNeighborhoods(String value) {
    setState(() {
      _searchText = value.toLowerCase();
      _filteredNeighborhoods = _neighborhoods
          .expand(
            (zone) => (zone['neighborhoods'] as List<String>).map(
              (name) => {'zone': zone['zone'], 'name': name},
            ),
          )
          .where(
            (neighborhood) =>
                neighborhood['name'].toLowerCase().contains(_searchText),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختر المنطقة السكنية"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن منطقتك...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _filterNeighborhoods,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text("استخدام الموقع تلقائيًا"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : Expanded(
                    child: _filteredNeighborhoods.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد مناطق متاحة',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredNeighborhoods.length,
                            itemBuilder: (context, index) {
                              final neighborhood =
                                  _filteredNeighborhoods[index];
                              return Card(
                                child: ListTile(
                                  title: Text(neighborhood['name']),
                                  subtitle: Text(
                                    'القاطع: ${neighborhood['zone']}',
                                  ),
                                  onTap: () async {
                                    // 🔹 جعل الدالة asynchronous
                                    // 🚀 الخطوة الجديدة: حفظ zoneId في shared_preferences
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      'selectedZoneId',
                                      neighborhood['zone'],
                                    );

                                    // تحديث مزود السلة بمعرف القاطع
                                    if (context.mounted) {
                                      Provider.of<CartProvider>(
                                        context,
                                        listen: false,
                                      ).updateZoneId(neighborhood['zone']);
                                    }

                                    // الانتقال إلى الشاشة التالية بعد حفظ الـ zoneId
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DeliveryScreen(
                                            deliveryCity: neighborhood['name'],
                                            zoneId: neighborhood['zone'],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
