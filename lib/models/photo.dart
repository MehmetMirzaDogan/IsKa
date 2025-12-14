class Photo {
  final int? id;
  final String path;
  final int albumId;
  final int userId;
  final DateTime takenAt;
  final String takenBy;
  final bool isVideo;
  final bool isFavorite;

  Photo({
    this.id,
    required this.path,
    required this.albumId,
    required this.userId,
    required this.takenAt,
    required this.takenBy,
    this.isVideo = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'album_id': albumId,
      'user_id': userId,
      'taken_at': takenAt.toIso8601String(),
      'taken_by': takenBy,
      'is_video': isVideo ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      path: map['path'],
      albumId: map['album_id'],
      userId: map['user_id'],
      takenAt: DateTime.parse(map['taken_at']),
      takenBy: map['taken_by'],
      isVideo: map['is_video'] == 1,
      isFavorite: map['is_favorite'] == 1,
    );
  }
}

