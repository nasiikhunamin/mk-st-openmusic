import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';

class MoodCocktailView extends StatefulWidget {
  final String trackId;
  const MoodCocktailView({super.key, required this.trackId});

  @override
  State<MoodCocktailView> createState() => _MoodCocktailViewState();
}

class _MoodCocktailViewState extends State<MoodCocktailView> {
  bool _isLoading = false;
  String? _errorMessage;

  String? _mood;
  Map<String, dynamic> _moodTags = {};

  String? _cocktailName;
  String? _cocktailImage;
  List<String> _cocktailIngredients = [];

  @override
  void initState() {
    super.initState();
    _fetchMoodAndCocktail();
  }

  @override
  void didUpdateWidget(covariant MoodCocktailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackId != widget.trackId) {
      _fetchMoodAndCocktail();
    }
  }

  Future<void> _fetchMoodAndCocktail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mood = null;
      _cocktailName = null;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      // Run both requests concurrently
      final responses = await Future.wait([
        apiClient.dio.get('/api/tracks/${widget.trackId}/mood'),
        apiClient.dio.get('/api/tracks/${widget.trackId}/cocktail'),
      ]);

      final moodResponse = responses[0];
      final cocktailResponse = responses[1];

      if (moodResponse.statusCode == 200 && cocktailResponse.statusCode == 200) {
        setState(() {
          _mood = moodResponse.data['mood'] as String?;
          _moodTags = (moodResponse.data['tags'] as Map<String, dynamic>?) ?? {};

          _cocktailName = cocktailResponse.data['cocktail_name'] as String?;
          _cocktailImage = cocktailResponse.data['image_url'] as String?;
          
          final ingredientsList = cocktailResponse.data['ingredients'] as List?;
          _cocktailIngredients = ingredientsList != null 
              ? ingredientsList.map((i) => i.toString()).toList() 
              : [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat analisis mood & cocktail pairing.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMoodTag(String key, dynamic value) {
    final doubleVal = double.tryParse(value.toString()) ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.mutedText),
              ),
              Text(
                '${(doubleVal * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.tealAccent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: doubleVal,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.mutedText),
        ),
      );
    }

    if (_mood == null || _cocktailName == null) {
      return const Center(
        child: Text(
          'Analisis tidak tersedia.',
          style: TextStyle(color: AppTheme.mutedText),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Mood Section
          Text(
            'Analisis Mood Lagu',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: AppTheme.tealAccent, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Mood Terdeteksi: ',
                        style: textTheme.bodyLarge?.copyWith(color: AppTheme.mutedText),
                      ),
                      Text(
                        _mood!.toUpperCase(),
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.tealAccent,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Colors.white10),
                  ..._moodTags.entries.map((entry) => _buildMoodTag(entry.key, entry.value)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Cocktail Pairing Section
          Text(
            'Cocktail Pairing',
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_cocktailImage != null && _cocktailImage!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _cocktailImage!,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.black26,
                          child: const Icon(Icons.local_bar, size: 64, color: AppTheme.mutedText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _cocktailName!,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bahan-bahan (Ingredients):',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._cocktailIngredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppTheme.tealAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
