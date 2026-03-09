import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';

class GalleryPreviewScreen extends StatefulWidget {
  const GalleryPreviewScreen({super.key});

  @override
  State<GalleryPreviewScreen> createState() => _GalleryPreviewScreenState();
}

class _GalleryPreviewScreenState extends State<GalleryPreviewScreen> {
  Uint8List? _imageBytes;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    // Auto-open gallery picker
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (file == null) {
        // User cancelled
        if (mounted) Navigator.pop(context);
        return;
      }

      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.disconnectedRed,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Gallery Print'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
            tooltip: 'Pick another image',
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Image preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Consumer<SettingsService>(
                          builder: (context, ss, _) {
                            return ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/preview',
                                  arguments: _imageBytes,
                                );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Preview & Print'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
