
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SongListPage(),
    );
  }
}

class SongListPage extends StatefulWidget {
  const SongListPage({super.key});

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  int? _currentIndex;
  bool _isPlaying = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndQuery();
  }

  Future<void> _requestPermissionAndQuery() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    List<SongModel> songs = await _audioQuery.querySongs();
    setState(() {
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _playSong(int index) async {
    final song = _songs[index];
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _audioPlayer.play();
      setState(() {
        _currentIndex = index;
        _isPlaying = true;
      });
    } catch (e) {
      // Handle error (e.g., file not found)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play this song.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingPage(
          song: song,
          isPlaying: _isPlaying,
          audioPlayer: _audioPlayer,
          onPlayPause: _togglePlayPause,
          onNext: _playNext,
          onPrev: _playPrev,
        ),
      ),
    ).then((_) {
      setState(() {}); // Refresh mini player state
    });
  }

  void _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _playNext() {
    if (_currentIndex == null || _songs.isEmpty) return;
    int next = (_currentIndex! + 1) % _songs.length;
    _playSong(next);
  }

  void _playPrev() {
    if (_currentIndex == null || _songs.isEmpty) return;
    int prev = (_currentIndex! - 1 + _songs.length) % _songs.length;
    _playSong(prev);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _songs.isEmpty
                  ? const Center(child: Text('No songs found', style: TextStyle(color: Colors.white)))
                  : Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                              child: Text(
                                'Music Player',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const TextField(
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 120, top: 8),
                                itemCount: _songs.length,
                                itemBuilder: (context, index) {
                                  final song = _songs[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Card(
                                      color: Colors.grey[900],
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: QueryArtworkWidget(
                                            id: song.id,
                                            type: ArtworkType.AUDIO,
                                            nullArtworkWidget: Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey[800],
                                              child: const Icon(Icons.music_note, color: Colors.white38),
                                            ),
                                            artworkHeight: 48,
                                            artworkWidth: 48,
                                          ),
                                        ),
                                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        subtitle: Text('${song.artist ?? "Unknown"} • ${song.album ?? "Unknown"}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                                        onTap: () => _playSong(index),
                                        trailing: _currentIndex == index && _isPlaying
                                            ? const Icon(Icons.equalizer, color: Colors.blue)
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_currentIndex != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 24,
                            child: MiniPlayerBar(
                              song: _songs[_currentIndex!],
                              isPlaying: _isPlaying,
                              onTap: () => _playSong(_currentIndex!),
                              onPlayPause: _togglePlayPause,
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
}

class MiniPlayerBar extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  const MiniPlayerBar({required this.song, required this.isPlaying, required this.onTap, required this.onPlayPause, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(24),
      color: Colors.grey[900],
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note, color: Colors.white38),
                  ),
                  artworkHeight: 48,
                  artworkWidth: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 36),
                onPressed: onPlayPause,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NowPlayingPage extends StatefulWidget {
  final SongModel song;
  final bool isPlaying;
  final AudioPlayer audioPlayer;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  const NowPlayingPage({required this.song, required this.isPlaying, required this.audioPlayer, required this.onPlayPause, required this.onNext, required this.onPrev, super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}


  double _progress = 0.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = widget.audioPlayer;
    _audioPlayer.positionStream.listen((pos) {
      setState(() {
        _position = pos;
        _duration = _audioPlayer.duration ?? Duration(milliseconds: widget.song.duration ?? 0);
        _progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Blurred background artwork
          Positioned.fill(
            child: QueryArtworkWidget(
              id: widget.song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: QueryArtworkWidget(
                      id: widget.song.id,
                      type: ArtworkType.AUDIO,
                      artworkHeight: 280,
                      artworkWidth: 280,
                      nullArtworkWidget: Container(
                        width: 280,
                        height: 280,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, size: 100, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(widget.song.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(widget.song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(widget.song.album ?? 'Unknown', style: const TextStyle(color: Colors.white38, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Slider(
                  value: _progress.isNaN ? 0 : _progress.clamp(0.0, 1.0),
                  onChanged: (v) async {
                    final newPosition = _duration * v;
                    await _audioPlayer.seek(newPosition);
                  },
                  min: 0,
                  max: 1,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(color: Colors.white54)),
                      Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40), onPressed: widget.onPrev),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 48),
                        onPressed: widget.onPlayPause,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 40), onPressed: widget.onNext),
                  ],
                ),
                const SizedBox(height: 32),
                Text('No lyrics', style: TextStyle(color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
  }
}