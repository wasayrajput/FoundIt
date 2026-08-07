import 'dart:typed_data';

/// Approval status set by the Admin Panel.
enum PostStatus { pending, approved, rejected }

class PostModel {
  final String id;
  final String itemName;
  final bool isLost; // true = Lost, false = Found
  final String date;
  final String location;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double? latitude;
  final double? longitude;
  final PostStatus status;

  const PostModel({
    required this.id,
    required this.itemName,
    required this.isLost,
    required this.date,
    required this.location,
    this.imageUrl,
    this.imageBytes,
    this.latitude,
    this.longitude,
    this.status = PostStatus.pending,
  });

  PostModel copyWith({
    String? id,
    String? itemName,
    bool? isLost,
    String? date,
    String? location,
    String? imageUrl,
    Uint8List? imageBytes,
    double? latitude,
    double? longitude,
    PostStatus? status,
  }) {
    return PostModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      isLost: isLost ?? this.isLost,
      date: date ?? this.date,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }
}
