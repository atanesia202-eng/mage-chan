import 'package:flutter/material.dart';
import 'package:mage_chan/features/quickbox/presentation/screens/quickbox_detail_screen.dart';

class QuickBoxListScreen extends StatefulWidget {
  const QuickBoxListScreen({super.key});

  @override
  State<QuickBoxListScreen> createState() => _QuickBoxListScreenState();
}

class _QuickBoxListScreenState extends State<QuickBoxListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // ในอนาคตอาจจะดึงจากฐานข้อมูล แต่ตอนนี้ hardcode 1 กล่องก่อน
  final List<Map<String, dynamic>> _allBoxes = [
    {
      'id': 'bts_mrt',
      'name': 'BTS/MRT',
      'icon': Icons.train,
      'color': Colors.green,
    }
  ];

  List<Map<String, dynamic>> _filteredBoxes = [];

  @override
  void initState() {
    super.initState();
    _filteredBoxes = _allBoxes;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBoxes = _allBoxes.where((box) {
        final name = box['name'] as String;
        return name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('กล่องเก็บของ (Quick Boxes)'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหากล่อง (เช่น BTS)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          
          // List of Boxes
          Expanded(
            child: _filteredBoxes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('ไม่พบกล่องที่ค้นหา', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _filteredBoxes.length,
                    itemBuilder: (context, index) {
                      final box = _filteredBoxes[index];
                      return _buildBoxCard(context, box);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxCard(BuildContext context, Map<String, dynamic> box) {
    final theme = Theme.of(context);
    final Color color = box['color'] as Color;
    
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuickBoxDetailScreen(
                boxId: box['id'] as String,
                boxName: box['name'] as String,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(box['icon'] as IconData, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              box['name'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
