import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openmusic_frontend/models/track.dart';
import 'package:openmusic_frontend/services/api_client.dart';
import 'package:openmusic_frontend/services/player_service.dart';
import 'package:openmusic_frontend/theme/app_theme.dart';
import 'package:openmusic_frontend/screens/player_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Track> _trendingTracks = [];
  List<Track> _synthwaveTracks = [];
  bool _isLoadingTrending = true;
  bool _isLoadingSynthwave = true;
  String _currentMood = "Chill";
  String _currentCocktail = "Mojito 🍹";
  bool _isLoadingCocktail = false;
  bool _isSearchingArtist = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    
    // Load Trending
    try {
      final response = await apiClient.dio.get('/api/tracks', queryParameters: {'q': 'hits'});
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _trendingTracks = data.map((item) => Track.fromJson(item)).toList();
          _isLoadingTrending = false;
        });
        
        // Load default cocktail pairing based on first trending track if available
        if (_trendingTracks.isNotEmpty) {
          _fetchCocktailPairing(_trendingTracks.first.id);
        }
      }
    } catch (_) {
      setState(() => _isLoadingTrending = false);
    }

    // Load Synthwave
    try {
      final response = await apiClient.dio.get('/api/tracks', queryParameters: {'q': 'synthwave'});
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        setState(() {
          _synthwaveTracks = data.map((item) => Track.fromJson(item)).toList();
          _isLoadingSynthwave = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingSynthwave = false);
    }
  }

  Future<void> _fetchCocktailPairing(String trackId) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    setState(() => _isLoadingCocktail = true);
    try {
      final moodRes = await apiClient.dio.get('/api/tracks/$trackId/mood');
      final cocktailRes = await apiClient.dio.get('/api/tracks/$trackId/cocktail');
      if (moodRes.statusCode == 200 && cocktailRes.statusCode == 200) {
        setState(() {
          _currentMood = moodRes.data['mood'] ?? 'Chill';
          _currentCocktail = "${cocktailRes.data['name'] ?? 'Mojito'} 🍹";
        });
      }
    } catch (_) {
      // Keep defaults
    } finally {
      if (mounted) {
        setState(() => _isLoadingCocktail = false);
      }
    }
  }

  Future<void> _playArtistTracks(String artistName) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final playerService = Provider.of<PlayerService>(context, listen: false);

    setState(() => _isSearchingArtist = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memutar lagu teratas dari $artistName...'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.surface,
      ),
    );

    try {
      final response = await apiClient.dio.get('/api/tracks', queryParameters: {'q': artistName});
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final tracks = data.map((item) => Track.fromJson(item)).toList();
        if (tracks.isNotEmpty) {
          await playerService.playTrack(tracks.first, newQueue: tracks);
          _fetchCocktailPairing(tracks.first.id);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak dapat menemukan lagu untuk artis ini'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghubungkan ke server'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingArtist = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final playerService = Provider.of<PlayerService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.music_note, color: AppTheme.primary, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                'SONA',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surface,
              backgroundImage: const NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCHVRZmtFnWgbZwRi_WxWflbvr6M_9ybtBaXjkBDElV-NpOMH9WFqnIOGoGTXQZ-3fUBYSNhXuNVuAlejDQo-sN4oB0coP2e3GageLuOWKZxGcD-moVSq4rFB7lnIoDxLelAqy73ehgy9S7KgHDEBnjIQTO0sl5II6GetFdwHsSdN7eWNydCSUJB-tkgTlbRyv3Oxk7Rkh4xvewL6fIAyoE9ayzeGujj7NL5QvRegeOVJ3stggRCzc4',
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTracks,
        color: AppTheme.tealAccent,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              // Top Search Bar (Simulated button to navigate to Explore tab)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSearchTap,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppTheme.mutedText),
                      SizedBox(width: 12),
                      Text(
                        'Artis, lagu, atau genre...',
                        style: TextStyle(color: AppTheme.mutedText, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bento Grid Section
              _buildBentoGrid(textTheme, playerService),
              
              const SizedBox(height: 32),
              
              // Trending Tracks List
              _buildSectionHeader(textTheme, "Trending Tracks", widget.onSearchTap ?? () {}),
              const SizedBox(height: 16),
              _isLoadingTrending
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
                  : _buildTrendingList(playerService),
                  
              const SizedBox(height: 32),
              
              // Trending Artists Section
              _buildArtistsSection(textTheme),
              
              const SizedBox(height: 32),
              
              // Synthwave List
              _buildSectionHeader(textTheme, "Because you like Synthwave", widget.onSearchTap ?? () {}),
              const SizedBox(height: 16),
              _isLoadingSynthwave
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.tealAccent))
                  : _buildSynthwaveList(playerService),
              
              const SizedBox(height: 120), // Padding bottom for mini player
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(TextTheme textTheme, PlayerService playerService) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left large hero card: New Release
            Expanded(
              flex: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_trendingTracks.isNotEmpty) {
                    playerService.playTrack(_trendingTracks.first, newQueue: _trendingTracks);
                  }
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBAmG8X9cQSx8NBwuddOK988YVsBfh64Pb0sdhlbu8RV2IazD-GUcdlisbFTfh0PD7snwdHIIgMOP4xq6nuNvOBXw9L_SgOk98sf0qn4p0bMXm2cH3vUECyKOox2n296MXjthTxsuKCB_ZcixnbZHJ1RkM3bESCatkO5ZD4UTiQyQsvw9d-iN3cZqbfntzTcXy2wnmCpFhDPyrOF9fKwmn9zwDOz8X-qedMYf4JTmr1Q-MWKNHjOh4r'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'NEW RELEASE',
                          style: textTheme.labelLarge?.copyWith(
                            color: AppTheme.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _trendingTracks.isNotEmpty ? _trendingTracks.first.title : 'Midnight Pulsar',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _trendingTracks.isNotEmpty ? _trendingTracks.first.artist : 'Luna Vibe',
                          style: textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right Card: Daily Mix
            Expanded(
              flex: 1,
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Daily Mix',
                      style: textTheme.headlineMedium?.copyWith(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Untuk Anda',
                      style: textTheme.labelLarge?.copyWith(color: AppTheme.mutedText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_trendingTracks.isNotEmpty) {
                          // Shuffle and play
                          final shuffled = List<Track>.from(_trendingTracks)..shuffle();
                          playerService.playTrack(shuffled.first, newQueue: shuffled);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('Putar', style: textTheme.labelLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom Banner: Cocktail Pairing
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Open PlayerScreen to show pairing detail if music is playing
            if (playerService.currentTrack != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Putar musik untuk melihat analisis Cocktail Pairing aktif!'),
                  backgroundColor: AppTheme.surface,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(Icons.local_bar, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COCKTAIL PAIRING',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppTheme.primary,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _isLoadingCocktail 
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealAccent))
                        : Text(
                            'Mood: $_currentMood. Coba $_currentCocktail',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.mutedText),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(TextTheme textTheme, String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(
            'Lihat Semua',
            style: textTheme.labelLarge?.copyWith(
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingList(PlayerService playerService) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _trendingTracks.length,
        itemBuilder: (context, index) {
          final track = _trendingTracks[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                playerService.playTrack(track, newQueue: _trendingTracks);
                _fetchCocktailPairing(track.id);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                              ? Image.network(
                                  track.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.surface,
                                    child: const Icon(Icons.music_note, color: AppTheme.primary),
                                  ),
                                )
                              : Container(
                                  color: AppTheme.surface,
                                  child: const Icon(Icons.music_note, color: AppTheme.primary),
                                ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSynthwaveList(PlayerService playerService) {
    return Column(
      children: List.generate(_synthwaveTracks.length > 5 ? 5 : _synthwaveTracks.length, (index) {
        final track = _synthwaveTracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              playerService.playTrack(track, newQueue: _synthwaveTracks);
              _fetchCocktailPairing(track.id);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                    ? Image.network(
                        track.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surface,
                          child: const Icon(Icons.music_note, color: AppTheme.primary),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface,
                        child: const Icon(Icons.music_note, color: AppTheme.primary),
                      ),
              ),
            ),
            title: Text(
              track.title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist,
              style: const TextStyle(color: AppTheme.mutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (track.duration != null)
                  Text(
                    "${(track.duration! ~/ 60)}:${(track.duration! % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert, color: AppTheme.mutedText),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildArtistsSection(TextTheme textTheme) {
    final List<Map<String, String>> artists = [
      {
        "name": "Zola",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCf59POeQrQMWJmirhKcQpQoTe4LnUuufOd4niRALLJLNkyFtysVRzI1NeKIvLdhN0OtflhwcTzG5A7_Ewbjkdp-HehMjnTJyCp-xlcm7rLjwUVFewA_JK_J3pa9AX3X6WX8BSjHe_9N1g6P20VKJ2bO0nSCTtMEVIO8zpzOyqwE_D98ve3NS1Ot5_cV2G_VslLrJ95vnAQJExW6YaxQ1biSPmIGoFBHZxyAEnLk3tf9bUfE8vD9-cb"
      },
      {
        "name": "Elias",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuBXwEo3RmC6wb6oIcc33RoWF85rYuhR3gOuW8kAmUm-ep5T5uuu_C0A1xAgVrDAk-Y8LdZRYTv6AQ7XvTrsz0F99yfRsQ-cA2TYE-f-TGzbxoJSa4NjLg-rG8jpalUIrig2K6YITHmZGGt3mubf2GMVJi_KfsXFa72T2hcWbOOQFbJxfR5TfhpFTYFCmAu9lazdvhPb-_IjdaGtnW1II3bddAW0j8j5siRCbBlQ4bCp09Rq3oy9l6ml"
      },
      {
        "name": "Vector",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuAmohgesEACj-PQW07gugOWKdxlgs02z853vKDGvcGtURfEOhmtLM94uS_WyCHsKRoQBz7zVhBr8973v1b5XO34t0SZanWG7eWcDJlGn_Vs9hUMHOUlS-TB9R7ZZoIO0GT0P1c8skD3OIxRhqJ2buj65-UcC8JO1YX5XOAzsTyz027CIjRvmu5Rbz2NS5AyFQcUPvU1f5TZQMdp3e8Chu3CYB9EOn0tjymv3UOCTZ4_nrKDf0G_iVzH"
      },
      {
        "name": "Maya",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuBLwlKr-1oAqf8HueVjArN5xXKe07HCl9wzVGIuPiFoqkKYHwJG5ZhU7oKnu6BVEncIGoa359mnT6imSGA-w4NnhfRI40_kbWiPcXf8V-60pSL3mxgkEsZSoIZg2wUUBSqSpXO-dtp0rbKX-JG9vw-BBiQWkjRNSEchNPwvq6YDHRcofZNqN_d-0XOvM5Ofe3fXeE--qzJNSudtfXclVW79e9BrUv4d6elhFaqzzB0O2SEe60gqgkdn"
      },
      {
        "name": "Ghost",
        "url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCrPPiYOZSxd4ZFRvuuBdLglCr_42r8N-jJdtoW8odjrVwMVIxAJ0Z84rhH8-q4xRwruAnLtticWCYGC3X4jp8IK3LNh9yWmXG3TcZBXB8dGbNJfX09iIpeoQJiEbwsYayK4zYdLkx1lG5rt8ZO0Y6PgmGLrfdta_bV6quiKwz5HfEssj48P9BxqHUD_o3wonjyuIE1R1rtue3CLbNJILSZ-I1wpZFhU4LWNpN6R7un-QnVintDcxEv"
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Trending Artists",
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isSearchingArtist)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealAccent),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Container(
                margin: const EdgeInsets.only(right: 24),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isSearchingArtist ? null : () => _playArtistTracks(artist['name']!),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: Image.network(
                            artist['url']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surface,
                              child: const Icon(Icons.person, color: AppTheme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist['name']!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
