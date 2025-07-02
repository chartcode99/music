
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void _playSong(int index) {
    setState(() {
      _currentIndex = index;
      _isPlaying = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingPage(
          song: _songs[index],
          isPlaying: _isPlaying,
          onPlayPause: _togglePlayPause,
          onNext: _playNext,
          onPrev: _playPrev,
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
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
      appBar: AppBar(
        title: const Text('Songs'),
        backgroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('No songs found', style: TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return ListTile(
                          leading: QueryArtworkWidget(
                            id: song.id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: const CircleAvatar(child: Icon(Icons.music_note)),
                          ),
                          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${song.artist ?? "Unknown"} | ${song.album ?? "Unknown"}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _playSong(index),
                          trailing: _currentIndex == index && _isPlaying
                              ? Icon(Icons.equalizer, color: Colors.blue)
                              : null,
                        );
                      },
                    ),
                    if (_currentIndex != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: MiniPlayerBar(
                          song: _songs[_currentIndex!],
                          isPlaying: _isPlaying,
                          onTap: () => _playSong(_currentIndex!),
                          onPlayPause: _togglePlayPause,
                        ),
                      ),
                  ],
                ),
      backgroundColor: Colors.black,
    );
  }
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
      elevation: 8,
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkBorder: BorderRadius.circular(24),
                nullArtworkWidget: const CircleAvatar(child: Icon(Icons.music_note)),
                artworkHeight: 48,
                artworkWidth: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 32),
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
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  const NowPlayingPage({required this.song, required this.isPlaying, required this.onPlayPause, required this.onNext, required this.onPrev, super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  double _progress = 0.1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.equalizer, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QueryArtworkWidget(
                id: widget.song.id,
                type: ArtworkType.AUDIO,
                artworkHeight: 260,
                artworkWidth: 260,
                nullArtworkWidget: Container(
                  width: 260,
                  height: 260,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, size: 100, color: Colors.white38),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(widget.song.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(widget.song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(widget.song.album ?? 'Unknown', style: const TextStyle(color: Colors.white38, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 24),
          Slider(
            value: _progress,
            onChanged: (v) => setState(() => _progress = v),
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
                Text(_formatDuration(Duration(seconds: ((widget.song.duration ?? 0) * _progress ~/ 1000))), style: const TextStyle(color: Colors.white54)),
                Text(_formatDuration(Duration(milliseconds: widget.song.duration ?? 0)), style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36), onPressed: widget.onPrev),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 64),
                onPressed: widget.onPlayPause,
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36), onPressed: widget.onNext),
            ],
          ),
          const SizedBox(height: 32),
          Text('No lyrics', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}';
  }
}