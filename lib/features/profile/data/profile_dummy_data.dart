import 'package:foundit/features/home/domain/post_model.dart';
import 'package:foundit/features/profile/domain/user_profile_model.dart';

/// Frontend-only dummy data for the Profile feature.
///
/// Mirrors the existing `DummyData` pattern used by the Home screen.
/// Nothing here is fetched or persisted — it only exists so the UI has
/// something realistic to render during development.
class ProfileDummyData {
  ProfileDummyData._();

  /// The "signed-in" user. Replace with real auth state later.
  static const UserProfileModel currentUser = UserProfileModel(
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1 (123) 456-7890',
  );

  /// Posts attributed to the current user. Reuses the shared [PostModel]
  /// so navigation into the existing [PostDetailScreen] works unchanged.
  static const List<PostModel> myPosts = [
    PostModel(
      id: 'u1',
      itemName: 'Silver House Keys',
      isLost: true,
      date: 'Oct 26, 2023',
      location: 'Main Library',
    ),
    PostModel(
      id: 'u2',
      itemName: 'Brown Leather Wallet',
      isLost: false,
      date: 'Oct 25, 2023',
      location: 'University Cafeteria',
    ),
    PostModel(
      id: 'u3',
      itemName: 'Black Headphones',
      isLost: true,
      date: 'Oct 24, 2023',
      location: 'Lecture Hall B',
    ),
    PostModel(
      id: 'u4',
      itemName: 'Student ID Card',
      isLost: false,
      date: 'Oct 23, 2023',
      location: 'Admin Office',
    ),
  ];
}
