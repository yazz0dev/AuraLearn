import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/ai_service.dart';

/// Debug widget to display cache statistics and management options
class CacheDebugWidget extends StatefulWidget {
  const CacheDebugWidget({super.key});

  @override
  State<CacheDebugWidget> createState() => _CacheDebugWidgetState();
}

class _CacheDebugWidgetState extends State<CacheDebugWidget> {
  final CacheService _cache = CacheService();
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _aiCacheStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _cacheStats = _cache.getCacheStats();
      _aiCacheStats = AIService.instance.getCacheStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cache Debug Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Stats',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // General Cache Stats
            _buildStatsSection(
              'General Cache',
              [
                'Memory Cache Size: ${_cacheStats['memory_cache_size'] ?? 0}',
                'Initialized: ${_cacheStats['initialized'] ?? false}',
              ],
            ),
            
            const SizedBox(height: 16),
            
            // AI Cache Stats
            _buildStatsSection(
              'AI Cache',
              [
                'Cached Responses: ${_aiCacheStats['total_ai_cached_responses'] ?? 0}',
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cache Keys (if any)
            if (_cacheStats['memory_cache_keys'] != null && 
                (_cacheStats['memory_cache_keys'] as List).isNotEmpty) ...[
              const Text(
                'Active Cache Keys:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: (_cacheStats['memory_cache_keys'] as List).length,
                  itemBuilder: (context, index) {
                    final key = (_cacheStats['memory_cache_keys'] as List)[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearAllCache,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(51),
                    foregroundColor: Colors.red,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAICache,
                  icon: const Icon(Icons.psychology, size: 16),
                  label: const Text('Clear AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withAlpha(51),
                    foregroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha(51),
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(String title, List<String> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...stats.map((stat) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            stat,
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  Future<void> _clearAllCache() async {
    try {
      await _cache.clear();
      await AIService.instance.clearCache();
      _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAICache() async {
    try {
      await AIService.instance.clearCache();
      _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing AI cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}