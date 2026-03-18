import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sponsor_layout.dart';

class SponsorActivitySelectionScreen extends StatefulWidget {
  final Set<String> initialSelected;

  const SponsorActivitySelectionScreen({
    super.key,
    required this.initialSelected,
  });

  @override
  State<SponsorActivitySelectionScreen> createState() =>
      _SponsorActivitySelectionScreenState();
}

class _SponsorActivitySelectionScreenState
    extends State<SponsorActivitySelectionScreen> {
  final _client = Supabase.instance.client;

  final Map<String, List<Map<String, dynamic>>> _activitiesByCategory = {};
  final Set<String> _selectedIds = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelected);
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD ACTIVITIES (SAME SOURCE AS YOUR ACTIVITIES)
  // --------------------------------------------------

  Future<void> _loadActivities() async {
    try {
      final categories =
      await _client.from('activity_categories').select('id, name');

      final activities =
      await _client.from('activities').select('id, name, category_id');

      _activitiesByCategory.clear();

      for (final category in categories) {
        final categoryName = category['name'] as String;

        final items = activities
            .where((a) => a['category_id'] == category['id'])
            .toList();

        if (items.isNotEmpty) {
          _activitiesByCategory[categoryName] = items;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------------------------------------
  // CHIP (PROFESSIONAL + FUNCTIONAL)
  // --------------------------------------------------

  Widget _buildChip(String id, String name) {
    final isSelected = _selectedIds.contains(id);
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(id);
          } else {
            _selectedIds.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withOpacity(0.10)
              : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? primary.withOpacity(0.4)
                : const Color(0xFFE3E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.add_circle_outline,
              size: 16,
              color:
              isSelected ? primary : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // CATEGORY SECTION
  // --------------------------------------------------

  Widget _buildCategory(
      String title, List<Map<String, dynamic>> activities) {
    final filtered = activities.where((activity) {
      final name = activity['name']
          .toString()
          .replaceAll('_', ' ')
          .toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text(
          '$title · ${filtered.length}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filtered.map((activity) {
            final id = activity['id'] as String;
            final name = activity['name']
                .toString()
                .replaceAll('_', ' ');
            return _buildChip(id, name);
          }).toList(),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select activities to sponsor'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedIds);
            },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
      child: SponsorLayout(
      child: ListView(
      children: [
          const Text(
            'Choose one or more activities that your business would like to sponsor.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // SEARCH
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities',
              prefixIcon:
              const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
              const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  width: 1.2,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close,
                    size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(
                          () => _searchQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (value) {
              setState(() =>
              _searchQuery = value.toLowerCase());
            },
          ),

          const SizedBox(height: 20),

          // CATEGORY LIST
          ..._activitiesByCategory.entries.map(
                (entry) =>
                _buildCategory(entry.key, entry.value),
          ),

          const SizedBox(height: 80),
      ],
      ),
      ),
      ),
    );
  }
}