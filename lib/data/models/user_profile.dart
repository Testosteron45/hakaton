import 'venue.dart';
import '../../features/profile/models/assistant_customization.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.preferredTypes,
    required this.defaultGroup,
    this.assistantCustomization = AssistantCustomization.defaults,
  });

  final String uid;
  final String name;
  final List<VenueType> preferredTypes;
  final GroupTag defaultGroup;
  final AssistantCustomization assistantCustomization;

  UserProfile copyWith({
    String? uid,
    String? name,
    List<VenueType>? preferredTypes,
    GroupTag? defaultGroup,
    AssistantCustomization? assistantCustomization,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      preferredTypes: preferredTypes ?? this.preferredTypes,
      defaultGroup: defaultGroup ?? this.defaultGroup,
      assistantCustomization:
          assistantCustomization ?? this.assistantCustomization,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'preferredTypes': preferredTypes.map((e) => e.name).toList(),
        'defaultGroup': defaultGroup.name,
        'assistantCustomization': assistantCustomization.toMap(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String,
        name: map['name'] as String,
        preferredTypes: (map['preferredTypes'] as List<dynamic>)
            .map((e) => VenueType.values.byName(e as String))
            .toList(),
        defaultGroup: GroupTag.values.byName(map['defaultGroup'] as String),
        assistantCustomization: AssistantCustomization.fromMap(
          map['assistantCustomization'] is Map
              ? Map<String, dynamic>.from(
                  map['assistantCustomization'] as Map,
                )
              : null,
        ),
      );
}
