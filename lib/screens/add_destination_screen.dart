import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../db/database_helper.dart';
import '../models/destination_model.dart';
import 'location_picker_screen.dart';

class AddDestinationScreen extends StatefulWidget {
  final Destination? destination;

  const AddDestinationScreen({super.key, this.destination});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _timeController = TextEditingController();

  File? _selectedImage;
  bool _isEditMode = false;
  bool _isGettingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      _isEditMode = true;
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final dest = widget.destination!;
    _nameController.text = dest.name;
    _descController.text = dest.description;
    _locationController.text = dest.location;
    _latController.text = dest.latitude.toString();
    _lngController.text = dest.longitude.toString();
    _timeController.text = dest.openTime;

    if (dest.imagePath != null) {
      setState(() {
        _selectedImage = File(dest.imagePath!);
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    setState(() {
      _isGettingAddress = true;
      _locationController.text = "Sedang mengambil alamat...";
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');

      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.nikkkdevvv.travelwisatalokal'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String address = data['display_name'] ?? "Alamat tidak ditemukan";

        if (mounted) {
          setState(() {
            _locationController.text = address;
          });
        }
      } else {
        if (mounted) _locationController.text = "Gagal mengambil alamat";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      if (mounted) _locationController.text = "";
    } finally {
      if (mounted) {
        setState(() {
          _isGettingAddress = false;
        });
      }
    }
  }

  Future<void> _pickLocationFromMap() async {
    double? initialLat = double.tryParse(_latController.text);
    double? initialLng = double.tryParse(_lngController.text);

    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi dipilih! Mengambil alamat...")),
      );

      await _getAddressFromCoordinates(result.latitude, result.longitude);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        final format = DateFormat.Hm();
        _timeController.text = format.format(dt);
      });
    }
  }

  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      String? finalImagePath;

      if (_selectedImage != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = path.basename(_selectedImage!.path);
          final savedImage = await _selectedImage!.copy('${directory.path}/$fileName');
          finalImagePath = savedImage.path;
        } catch (e) {
          finalImagePath = _selectedImage!.path;
        }
      } else {
        finalImagePath = widget.destination?.imagePath;
      }

      final destination = Destination(
        id: widget.destination?.id,
        name: _nameController.text,
        description: _descController.text,
        location: _locationController.text,
        latitude: double.tryParse(_latController.text) ?? 0.0,
        longitude: double.tryParse(_lngController.text) ?? 0.0,
        openTime: _timeController.text,
        imagePath: finalImagePath,
      );

      if (_isEditMode) {
        await DatabaseHelper.instance.update(destination);
      } else {
        await DatabaseHelper.instance.create(destination);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Data berhasil diperbarui!' : 'Destinasi berhasil disimpan!')),
        );

        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Destinasi' : 'Tambah Destinasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo_outlined, size: 40),
                      SizedBox(height: 8),
                      Text("Ketuk untuk tambah foto"),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Nama Tempat Wisata',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                maxLines: 2,
                readOnly: _isGettingAddress,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isGettingAddress
                      ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              const Text("Lokasi Koordinat",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: 'Latitude', border: InputBorder.none),
                            validator: (value) =>
                            value!.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            readOnly: true,
                            decoration: const InputDecoration(
                                labelText: 'Longitude', border: InputBorder.none),
                            validator: (value) =>
                            value!.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _pickLocationFromMap,
                        icon: const Icon(Icons.map),
                        label: const Text("Pilih Titik di Peta"),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: () => _selectTime(context),
                decoration: const InputDecoration(
                    labelText: 'Jam Buka',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: _saveData,
                icon: Icon(_isEditMode ? Icons.edit : Icons.save),
                label: Text(_isEditMode ? 'Update Data' : 'Simpan Data'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}