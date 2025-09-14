import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tajer/merchant_provider.dart';
import 'merchant_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final Databases databases;
  final Storage storage;

  const RegisterScreen({
    super.key,
    required this.databases,
    required this.storage,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  final _phoneController = TextEditingController();

  String? selectedCategory;
  String? selectedZoneName;
  String? selectedNeighborhood;
  double? latitude;
  double? longitude;

  bool _isLoading = false;

  final List<String> categories = [
    'سوبرماركت',
    'البان واجبان',
    'أفران',
    'حلويات وكرزات',
    'مواد غذائية',
    'مطاعم',
    'عطارية',
    'مرطبات',
  ];

  List<Map<String, dynamic>> zones = [];
  List<String> neighborhoods = [];

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final res = await widget.databases.listDocuments(
        databaseId: 'mahllnadb',
        collectionId: 'zoneid',
      );

      setState(() {
        zones = res.documents.map((doc) => doc.data).toList();
      });
    } catch (e) {
      debugPrint("Error fetching zones: $e");
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تفعيل الموقع في الإعدادات')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم رفض إذن الموقع')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('إذن الموقع مرفوض دائمًا')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في الحصول على الموقع: $e')));
    }
  }

  Future<void> _registerAndSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تصنيف المتجر')),
      );
      return;
    }

    if (selectedZoneName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار القاطع')));
      return;
    }

    if (selectedNeighborhood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الحي')));
      return;
    }

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد الموقع الجغرافي')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newStore = await widget.databases.createDocument(
        databaseId: 'mahllnadb',
        collectionId: 'Stores',
        documentId: ID.unique(),
        data: {
          'name': _nameController.text,
          'stpass': _passController.text,
          'phone': _phoneController.text,
          'isOpen': true,
          'is_active': true,
          'latitude': latitude!,
          'longitude': longitude!,
          'category': selectedCategory!,
          'zone': selectedZoneName!, // فقط الاسم
          'neighborhood': selectedNeighborhood!, // فقط الحي
          'image': '',
        },
      );

      final storeId = newStore.$id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('storeId', storeId);
      await prefs.setString('zone', selectedZoneName!);
      await prefs.setString('neighborhood', selectedNeighborhood!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) =>
                  MerchantProvider(widget.databases, widget.storage, storeId),
              child: MerchantDashboard(
                databases: widget.databases,
                storage: widget.storage,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ في إنشاء الحساب: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب وإعداد المتجر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال كلمة المرور' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                decoration: const InputDecoration(
                  labelText: 'اختر تصنيف المتجر',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // 🔹 اختيار القاطع بالاسم فقط
              DropdownButtonFormField<String>(
                value: selectedZoneName,
                items: zones.map((zone) {
                  return DropdownMenuItem<String>(
                    value: zone['name'] as String,
                    child: Text(zone['name'] ?? 'بدون اسم'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedZoneName = val;
                    final zone = zones.firstWhere((z) => z['name'] == val);
                    neighborhoods = List<String>.from(
                      zone['neighborhoods'] ?? [],
                    );
                    selectedNeighborhood = null;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'اختر القاطع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedNeighborhood,
                items: neighborhoods.map((n) {
                  return DropdownMenuItem<String>(value: n, child: Text(n));
                }).toList(),
                onChanged: (val) => setState(() => selectedNeighborhood = val),
                decoration: const InputDecoration(
                  labelText: 'اختر الحي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('الموقع الجغرافي'),
                subtitle: Text(
                  latitude != null && longitude != null
                      ? 'Lat: ${latitude!.toStringAsFixed(4)}, Lon: ${longitude!.toStringAsFixed(4)}'
                      : 'غير محدد',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getLocation,
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerAndSetup,
                      child: const Text('إنشاء الحساب وبدء المتجر'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
