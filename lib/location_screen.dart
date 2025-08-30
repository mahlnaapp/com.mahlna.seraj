import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'delivery_screen.dart';
import 'dart:async'; // أضف هذا الاستيراد

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _locationText = "جاري تحديد موقعك...";
  bool _isLoading = true;
  bool _permissionDeniedForever = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
      _locationText = message;
      _isLoading = false;
      _permissionDeniedForever = isDeniedForever;
    });
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    await _checkLocationPermission();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DeliveryScreen(deliveryCity: "الموصل"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تحديد الموقع"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 5,
                    )
                  : Icon(
                      _permissionDeniedForever
                          ? Icons.location_off
                          : Icons.location_on,
                      size: 80,
                      color: Colors.orange,
                    ),
              const SizedBox(height: 30),
              Text(
                _locationText,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              if (!_isLoading) ...[
                const SizedBox(height: 30),
                if (_permissionDeniedForever)
                  ElevatedButton(
                    onPressed: _openAppSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("فتح إعدادات الموقع"),
                  )
                else
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("حاول مرة أخرى"),
                  ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DeliveryScreen(deliveryCity: "الموصل"),
                      ),
                    );
                  },
                  child: const Text("أو اختر مدينة يدويًا"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
