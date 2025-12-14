import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/auth_service.dart';
import '../services/album_service.dart';
import '../services/theme_service.dart';
import 'camera_screen.dart';
import 'album_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlbumService _albumService = AlbumService.instance;
  final AuthService _authService = AuthService.instance;
  final ThemeService _themeService = ThemeService.instance;
  List<Album> _albums = [];
  bool _isLoading = true;
  Album? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    _loadAlbums();
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAlbums() async {
    // Otomatik silme işlemini arka planda tetikle
    _albumService.performAutoDelete().then((_) {});

    setState(() => _isLoading = true);
    try {
      final albums = await _albumService.getUserAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Albümler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _showCreateAlbumDialog() async {
    final controller = TextEditingController();
    int selectedHours = 720; // 30 gün varsayılan
    bool deleteWithPhotos = false;
    final theme = Theme.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Albüm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Albüm Adı',
                    hintText: 'Örnek: Proje A',
                  ),
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  enableSuggestions: true,
                  autocorrect: false,
                ),
                const SizedBox(height: 24),
                Text(
                  'Otomatik Silme Ayarları',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedHours,
                  decoration: const InputDecoration(
                    labelText: 'Silme Süresi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('Asla Silme')),
                    DropdownMenuItem(value: 12, child: Text('12 Saat')),
                    DropdownMenuItem(value: 24, child: Text('1 Gün')),
                    DropdownMenuItem(value: 72, child: Text('3 Gün')),
                    DropdownMenuItem(value: 168, child: Text('1 Hafta')),
                    DropdownMenuItem(value: 720, child: Text('1 Ay')),
                    DropdownMenuItem(value: 2160, child: Text('3 Ay')),
                    DropdownMenuItem(value: 8760, child: Text('1 Yıl')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedHours = value ?? 720);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Albümü de sil', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Fotoğraflar silindiğinde albüm de silinsin',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: deleteWithPhotos,
                  onChanged: (value) {
                    setDialogState(() => deleteWithPhotos = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'name': controller.text,
                'days': selectedHours,
                'deleteWithPhotos': deleteWithPhotos,
              }),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['name']?.isNotEmpty == true) {
      await _albumService.createManualAlbum(
        result['name'],
        autoDeleteDays: result['days'],
        deleteAlbumWithPhotos: result['deleteWithPhotos'],
      );
      _loadAlbums();
    }
  }

  Future<void> _showAlbumSelectionDialog() async {
    final theme = Theme.of(context);
    
    // Sadece manuel oluşturulan albümleri filtrele
    final manualAlbums = _albums.where((album) => !album.isAutoGenerated).toList();
    
    if (manualAlbums.isEmpty) {
      // Albüm yoksa kullanıcıyı bilgilendir
      final shouldCreate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Albüm Yok'),
          content: const Text(
            'Henüz bir albüm oluşturmadınız. Fotoğraf çekmek için önce bir albüm oluşturmanız gerekiyor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Albüm Oluştur'),
            ),
          ],
        ),
      );
      
      if (shouldCreate == true) {
        _showCreateAlbumDialog();
      }
      return;
    }

    final result = await showDialog<Album>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albüm Seç'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: manualAlbums
                .map((album) => ListTile(
                      leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                      title: Text(album.name),
                      subtitle: Text(_getAlbumSubtitle(album)),
                      onTap: () => Navigator.pop(context, album),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateAlbumDialog();
            },
            child: const Text('Yeni Albüm'),
          ),
        ],
      ),
    );

    if (result != null) {
      _selectedAlbum = result;
      _openCamera();
    }
  }
  
  String _getAlbumSubtitle(Album album) {
    int hours = _convertToHoursStatic(album.autoDeleteDays);
    
    if (hours == -1) {
      return 'Silinmez';
    }
    
    final deleteDate = album.createdAt.add(Duration(hours: hours));
    final remaining = deleteDate.difference(DateTime.now());
    
    if (remaining.isNegative) {
      return 'Süresi doldu';
    }
    
    if (remaining.inHours < 24) {
      if (remaining.inHours < 1) {
        return '${remaining.inMinutes} dk kaldı';
      }
      return '${remaining.inHours} saat kaldı';
    }
    
    return '${remaining.inDays} gün kaldı';
  }
  
  // Static helper metod
  int _convertToHoursStatic(int value) {
    if (value == -1) return -1;
    if (value == 0) return 720;
    if (value == 1) return 24;
    if (value == 3) return 72;
    if (value == 7) return 168;
    if (value == 30) return 720;
    if (value == 90) return 2160;
    if (value == 365) return 8760;
    if ([12, 24, 72, 168, 720, 2160, 8760].contains(value)) return value;
    return 720;
  }

  void _openCamera() {
    if (_selectedAlbum == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(album: _selectedAlbum!),
      ),
    ).then((_) {
      _loadAlbums();
      _selectedAlbum = null;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _deleteAlbum(Album album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albümü Sil'),
        content: Text('${album.name} albümünü ve içindeki tüm fotoğrafları silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _albumService.deleteAlbum(album.id!);
      if (success) {
        _loadAlbums();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Albüm silindi')),
          );
        }
      }
    }
  }

  Future<void> _showAlbumSettingsDialog(Album album) async {
    // Eski değerleri yeni saat formatına çevir
    int savedValue = album.autoDeleteDays;
    int selectedHours;
    if (savedValue == 0) {
      selectedHours = 720; // Varsayılan 30 gün
    } else if (savedValue == -1) {
      selectedHours = -1; // Asla silme
    } else if (savedValue == 1) {
      selectedHours = 24; // 1 gün -> 24 saat
    } else if (savedValue == 3) {
      selectedHours = 72; // 3 gün -> 72 saat
    } else if (savedValue == 7) {
      selectedHours = 168; // 1 hafta -> 168 saat
    } else if (savedValue == 30) {
      selectedHours = 720; // 1 ay -> 720 saat
    } else if (savedValue == 90) {
      selectedHours = 2160; // 3 ay -> 2160 saat
    } else if (savedValue == 365) {
      selectedHours = 8760; // 1 yıl -> 8760 saat
    } else if ([12, 24, 72, 168, 720, 2160, 8760].contains(savedValue)) {
      selectedHours = savedValue; // Zaten yeni formatta
    } else {
      selectedHours = 720; // Bilinmeyen değer için varsayılan
    }
    bool deleteWithPhotos = album.deleteAlbumWithPhotos;
    final theme = Theme.of(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(album.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Otomatik Silme Ayarları',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedHours,
                  decoration: const InputDecoration(
                    labelText: 'Silme Süresi',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('Asla Silme')),
                    DropdownMenuItem(value: 12, child: Text('12 Saat')),
                    DropdownMenuItem(value: 24, child: Text('1 Gün')),
                    DropdownMenuItem(value: 72, child: Text('3 Gün')),
                    DropdownMenuItem(value: 168, child: Text('1 Hafta')),
                    DropdownMenuItem(value: 720, child: Text('1 Ay')),
                    DropdownMenuItem(value: 2160, child: Text('3 Ay')),
                    DropdownMenuItem(value: 8760, child: Text('1 Yıl')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedHours = value ?? 720);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Albümü de sil', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    'Fotoğraflar silindiğinde albüm de silinsin',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: deleteWithPhotos,
                  onChanged: (value) {
                    setDialogState(() => deleteWithPhotos = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDeleteInfoText(selectedHours, deleteWithPhotos),
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'days': selectedHours,
                'deleteWithPhotos': deleteWithPhotos,
              }),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final updatedAlbum = album.copyWith(
        autoDeleteDays: result['days'],
        deleteAlbumWithPhotos: result['deleteWithPhotos'],
      );
      final success = await _albumService.updateAlbum(updatedAlbum);
      if (success) {
        _loadAlbums();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Albüm ayarları güncellendi')),
          );
        }
      }
    }
  }

  String _getDeleteInfoText(int hours, bool deleteWithPhotos) {
    if (hours == -1) {
      return 'Bu albümdeki fotoğraflar otomatik silinmeyecek.';
    }
    
    String timeText;
    if (hours == 12) {
      timeText = '12 saat sonra';
    } else if (hours == 24) {
      timeText = '1 gün sonra';
    } else if (hours == 72) {
      timeText = '3 gün sonra';
    } else if (hours == 168) {
      timeText = '1 hafta sonra';
    } else if (hours == 720) {
      timeText = '1 ay sonra';
    } else if (hours == 2160) {
      timeText = '3 ay sonra';
    } else if (hours == 8760) {
      timeText = '1 yıl sonra';
    } else {
      timeText = '${hours ~/ 24} gün sonra';
    }
    
    if (deleteWithPhotos) {
      return 'Fotoğraflar $timeText silinecek ve albüm de kaldırılacak.';
    } else {
      return 'Fotoğraflar $timeText silinecek, albüm kalacak.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _authService.currentUser?.name ?? '',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        title: const Text('IsKa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlbums,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _albums.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 100,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz albüm yok',
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fotoğraf çekmeye başlayın',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlbums,
                  child: Builder(
                    builder: (context) {
                      // Sadece manuel oluşturulan albümleri göster
                      final manualAlbums = _albums.where((a) => !a.isAutoGenerated).toList();
                      
                      if (manualAlbums.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 100,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz albüm yok',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Albüm oluşturup fotoğraf çekmeye başlayın',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: manualAlbums.length,
                    itemBuilder: (context, index) {
                      final album = manualAlbums[index];
                      return _AlbumCard(
                        album: album,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(album: album),
                            ),
                          ).then((_) => _loadAlbums());
                        },
                        onDelete: () => _deleteAlbum(album),
                        onSettings: () => _showAlbumSettingsDialog(album),
                      );
                    },
                  );
                    },
                  ),
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'create_album',
            onPressed: _showCreateAlbumDialog,
            backgroundColor: isDark ? colorScheme.surface : Colors.white,
            foregroundColor: colorScheme.primary,
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: _showAlbumSelectionDialog,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Fotoğraf Çek'),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSettings;

  const _AlbumCard({
    required this.album,
    required this.onTap,
    required this.onDelete,
    required this.onSettings,
  });

  // Eski gün değerlerini saat değerine çevir
  int _convertToHours(int value) {
    if (value == -1) return -1;
    if (value == 0) return 720;
    // Eski gün formatı değerleri
    if (value == 1) return 24;
    if (value == 3) return 72;
    if (value == 7) return 168;
    if (value == 30) return 720;
    if (value == 90) return 2160;
    if (value == 365) return 8760;
    // Zaten saat formatında veya bilinmeyen
    if ([12, 24, 72, 168, 720, 2160, 8760].contains(value)) return value;
    return 720; // Varsayılan
  }
  
  String _getAlbumTypeText() {
    String type = album.isAutoGenerated ? 'Otomatik' : 'Manuel';
    int hours = _convertToHours(album.autoDeleteDays);
    
    if (hours == -1) {
      return '$type • Silinmez';
    }
    
    // Silinme tarihini hesapla (saat cinsinden)
    final deleteDate = album.createdAt.add(Duration(hours: hours));
    final now = DateTime.now();
    final remaining = deleteDate.difference(now);
    
    if (remaining.isNegative) {
      return '$type • Süresi doldu';
    }
    
    // 24 saatten az kaldıysa saat/dakika olarak göster
    if (remaining.inHours < 24) {
      if (remaining.inHours < 1) {
        return '$type • ${remaining.inMinutes} dk kaldı';
      }
      return '$type • ${remaining.inHours} saat kaldı';
    }
    
    // 24 saatten fazla kaldıysa gün olarak göster
    final remainingDays = remaining.inDays;
    if (remainingDays == 1) {
      return '$type • 1 gün kaldı';
    }
    return '$type • $remainingDays gün kaldı';
  }
  
  Color _getRemainingTimeColor(BuildContext context) {
    int hours = _convertToHours(album.autoDeleteDays);
    
    if (hours == -1) return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    
    final deleteDate = album.createdAt.add(Duration(hours: hours));
    final now = DateTime.now();
    final remaining = deleteDate.difference(now);
    
    if (remaining.isNegative || remaining.inHours < 6) {
      return Colors.red;
    } else if (remaining.inHours < 24) {
      return Colors.orange;
    } else if (remaining.inDays <= 3) {
      return Colors.amber.shade700;
    }
    return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Tema moduna göre albüm kartı renkleri
    Color autoColor = colorScheme.primary;
    Color manualColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    Color autoCardBg = colorScheme.primary.withOpacity(isDark ? 0.2 : 0.15);
    Color manualCardBg = (isDark ? Colors.orange.shade300 : Colors.orange).withOpacity(isDark ? 0.2 : 0.15);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: album.isAutoGenerated ? autoCardBg : manualCardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  album.isAutoGenerated ? Icons.calendar_today : Icons.folder,
                  size: 60,
                  color: album.isAutoGenerated ? autoColor : manualColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getAlbumTypeText(),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getRemainingTimeColor(context),
                            fontWeight: _getRemainingTimeColor(context) != theme.textTheme.bodySmall?.color 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onSettings,
                            child: Icon(
                              Icons.settings,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (!album.isAutoGenerated) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onDelete,
                              child: Icon(
                                Icons.delete,
                                size: 18,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
