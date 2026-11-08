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

  /// Posts attributed to the current user. Empty by default for live database posts.
  static const List<PostModel> myPosts = [];
}
