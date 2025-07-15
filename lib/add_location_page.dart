import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'models/category_model.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  File? _image;
  LatLng? _photoLatLng;
  LatLng? _currentLatLng;
  double? _accuracy;
  bool _canTakePhoto = false;
  bool _isUploading = false;

  final _nameController = TextEditingController();

  List<Position> _positionHistory = [];

  @override
  void initState() {
    super.initState();
    _startLocationMonitoring();
  }

  void _startLocationMonitoring() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentLatLng = latLng;
        _accuracy = pos.accuracy;
        _positionHistory.add(pos);
        if (_positionHistory.length > 3) _positionHistory.removeAt(0);

        _canTakePhoto = _isLocationStable(_positionHistory) && pos.accuracy <= 20;
      });
    });
  }

  bool _isLocationStable(List<Position> positions) {
    if (positions.length < 2) return false;
    final last = positions.last;
    final prev = positions[positions.length - 2];

    double dist = Geolocator.distanceBetween(
      last.latitude, last.longitude,
      prev.latitude, prev.longitude,
    );

    return dist < 5; // 5m 이내면 안정된 위치
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();

    // 1. 촬영 시작 직전의 위치 저장
    final Position startPos = await Geolocator.getCurrentPosition();
    final LatLng startLatLng = LatLng(startPos.latitude, startPos.longitude);

    // 2. 카메라 촬영 실행
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("촬영이 취소되었습니다.")));
      return;
    }

    // 3. 촬영 직후의 위치 다시 측정
    final Position endPos = await Geolocator.getCurrentPosition();
    final LatLng endLatLng = LatLng(endPos.latitude, endPos.longitude);

    // 4. 거리 계산
    final distance = Geolocator.distanceBetween(
      startLatLng.latitude, startLatLng.longitude,
      endLatLng.latitude, endLatLng.longitude,
    );

    // 5. 촬영 중 이동 여부 판단
    if (distance > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("촬영 중 이동이 감지되어 등록이 취소되었습니다.\n(${distance.toStringAsFixed(1)}m 이동)")),
      );
      return;
    }

    // 6. 촬영 성공 → 이미지 및 위치 저장
    setState(() {
      _image = File(picked.path);
      _photoLatLng = endLatLng; // 촬영 시점의 위치로 저장
    });
  }


  Future<void> _uploadData() async {
    if (_image == null || _photoLatLng == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("모든 정보를 입력해주세요.")));
      return;
    }

    setState(() => _isUploading = true);

    final uri = Uri.parse("http://34.47.75.182/location/uploadLocation");
    final request = http.MultipartRequest('POST', uri)
      ..fields['locName'] = _nameController.text
      ..fields['latitude'] = _photoLatLng!.latitude.toString()
      ..fields['longitude'] = _photoLatLng!.longitude.toString()
      ..fields['categoryId'] = selectedCategory!.categoryId.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();
    setState(() => _isUploading = false);

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("업로드 성공: $resStr")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("업로드 실패 (${response.statusCode})")));
    }
  }

  CategoryModel? selectedCategory;
  Future<List<CategoryModel>> fetchCategories() async {
    final url = Uri.parse('http://34.47.75.182:8080/game/getCategories');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> list = json['categoryList'];
      return list.map((item) => CategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('카테고리 불러오기 실패: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("장소 등록")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 200, fit: BoxFit.cover)
                : Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(child: Icon(Icons.add_a_photo, size: 50)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '장소 이름'),
            ),
            SizedBox(height: 16),
            FutureBuilder<List<CategoryModel>>(
                future: fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('카테고리가 없습니다.');
                  } else {
                    final categories = snapshot.data!;
                    return DropdownButton<CategoryModel>(
                      value: selectedCategory,
                      hint: Text('카테고리 선택'),
                      items: categories.map((category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Text(category.categoryName),
                        );
                      }).toList(),
                      onChanged: (CategoryModel? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    );
                  }
                }
            ),
            if (_currentLatLng != null && _accuracy != null)
              Column(
                children: [
                  Text("📍 현재 위치: ${_currentLatLng!.latitude.toStringAsFixed(6)}, ${_currentLatLng!.longitude.toStringAsFixed(6)}"),
                  Text("🎯 위치 정확도: ±${_accuracy!.toStringAsFixed(1)}m"),
                ],
              )
            else
              CircularProgressIndicator(),
            SizedBox(height: 20),
            _canTakePhoto
                ? ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: Icon(Icons.camera_alt),
              label: Text("촬영하기"),
            )
                : Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("GPS 안정화 중입니다.\n움직이지 말고 기다려주세요."),
              ],
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadData,
              child: _isUploading
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("등록하기"),
            ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}