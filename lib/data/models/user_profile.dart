import 'venue.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.preferredTypes,
    required this.defaultGroup,
  });

  final String uid;
  final String name;
  final List<VenueType> preferredTypes;
  final GroupTag defaultGroup;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'preferredTypes': preferredTypes.map((e) => e.name).toList(),
        'defaultGroup': defaultGroup.name,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        name: map['name'] as String,
        preferredTypes: (map['preferredTypes'] as List<dynamic>)
            .map((e) => VenueType.values.byName(e as String))
            .toList(),
        defaultGroup: GroupTag.values.byName(map['defaultGroup'] as String),
      );
}
