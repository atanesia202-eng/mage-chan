import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class QuickBoxDetailScreen extends StatefulWidget {
  final String boxId;
  final String boxName;

  const QuickBoxDetailScreen({
    super.key,
    required this.boxId,
    required this.boxName,
  });

  @override
  State<QuickBoxDetailScreen> createState() => _QuickBoxDetailScreenState();
}

class _QuickBoxDetailScreenState extends State<QuickBoxDetailScreen> {
  String? _imagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  String get _prefKey => 'quickbox_image_${widget.boxId}';

  Future<void> _loadImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(_prefKey);
      
      if (path != null && File(path).existsSync()) {
        setState(() {
          _imagePath = path;
        });
      } else if (path != null) {
        // File is missing but path is saved, clean it up
        await prefs.remove(_prefKey);
      }
    } catch (e) {
      debugPrint('Error loading image for box ${widget.boxId}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Copy image to app's document directory so it stays forever
        final appDir = await getApplicationDocumentsDirectory();
        final String fileExtension = image.name.split('.').last;
        final String newFileName = 'quickbox_${widget.boxId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final String newPath = '${appDir.path}/$newFileName';

        final File newFile = await File(image.path).copy(newPath);

        // Delete old image if it exists
        if (_imagePath != null && File(_imagePath!).existsSync()) {
          try {
            File(_imagePath!).deleteSync();
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }

        // Save new path to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, newFile.path);

        setState(() {
          _imagePath = newFile.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ')),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    // Confirm delete
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรูปภาพนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true && _imagePath != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (File(_imagePath!).existsSync()) {
          File(_imagePath!).deleteSync();
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefKey);

        setState(() {
          _imagePath = null;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error deleting image: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for viewing images
      appBar: AppBar(
        title: Text(widget.boxName),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_imagePath != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'เปลี่ยนรูปภาพ',
              onPressed: _pickAndSaveImage,
            ),
          if (_imagePath != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'ลบรูปภาพ',
              onPressed: _deleteImage,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imagePath != null
              ? Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : _buildEmptyState(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            'ยังไม่มีรูปภาพในกล่องนี้',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'เพิ่มรูปภาพที่คุณใช้งานบ่อย (เช่น ตั๋ว, แผนที่)',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickAndSaveImage,
            icon: const Icon(Icons.image),
            label: const Text('เลือกรูปภาพ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
