import 'package:foundit/features/home/domain/post_model.dart';

class DummyData {
  static const List<PostModel> posts = [
    PostModel(
      id: '1',
      itemName: 'iPhone 14 Pro Max',
      isLost: true,
      date: 'Oct 24, 2023',
      location: 'Central Park, NY',
      latitude: 40.785091,
      longitude: -73.968285,
    ),
    PostModel(
      id: '2',
      itemName: 'Brown Leather Wallet',
      isLost: false,
      date: 'Oct 23, 2023',
      location: 'Starbucks, 5th Ave',
      latitude: 40.758896,
      longitude: -73.979809,
    ),
    PostModel(
      id: '3',
      itemName: 'Golden Retriever Dog',
      isLost: true,
      date: 'Oct 22, 2023',
      location: 'Brooklyn Bridge',
      latitude: 40.706086,
      longitude: -73.996864,
    ),
    PostModel(
      id: '4',
      itemName: 'Set of Car Keys',
      isLost: false,
      date: 'Oct 20, 2023',
      location: 'JFK Airport, Terminal 4',
      latitude: 40.643031,
      longitude: -73.782228,
    ),
    PostModel(
      id: '5',
      itemName: 'MacBook Pro 16"',
      isLost: true,
      date: 'Oct 19, 2023',
      location: 'NYU Library',
      latitude: 40.729782,
      longitude: -73.997232,
    ),
    PostModel(
      id: '6',
      itemName: 'Ray-Ban Sunglasses',
      isLost: false,
      date: 'Oct 15, 2023',
      location: 'Times Square',
      latitude: 40.7580,
      longitude: -73.9855,
    ),
  ];
}
