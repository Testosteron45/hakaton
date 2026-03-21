import 'venue.dart';
import '../../features/profile/models/assistant_customization.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.preferredTypes,
    required this.defaultGroup,
    this.assistantCustomization = AssistantCustomization.defaults,
    this.likedTypes = const {},
    this.likedFeatures = const {},
    this.preferredPrice = const {},
    this.preferredDistance = const {},
    this.preferredGroup = const {},
    this.totalSessions = 0,
    this.ownedVenueIds = const [],
  });

  final String uid;
  final String name;
  final List<VenueType> preferredTypes;
  final GroupTag defaultGroup;
  final AssistantCustomization assistantCustomization;

  // Accumulated interests from swipe sessions (liked venues only)
  final Map<String, int> likedTypes;
  final Map<String, int> likedFeatures;
  final Map<String, int> preferredPrice;
  final Map<String, int> preferredDistance;
  final Map<String, int> preferredGroup;
  final int totalSessions;

  // IDs of all venues this user owns
  final List<String> ownedVenueIds;

  UserProfile copyWith({
    String? uid,
    String? name,
    List<VenueType>? preferredTypes,
    GroupTag? defaultGroup,
    AssistantCustomization? assistantCustomization,
    Map<String, int>? likedTypes,
    Map<String, int>? likedFeatures,
    Map<String, int>? preferredPrice,
    Map<String, int>? preferredDistance,
    Map<String, int>? preferredGroup,
    int? totalSessions,
    List<String>? ownedVenueIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      preferredTypes: preferredTypes ?? this.preferredTypes,
      defaultGroup: defaultGroup ?? this.defaultGroup,
      assistantCustomization:
          assistantCustomization ?? this.assistantCustomization,
      likedTypes: likedTypes ?? this.likedTypes,
      likedFeatures: likedFeatures ?? this.likedFeatures,
      preferredPrice: preferredPrice ?? this.preferredPrice,
      preferredDistance: preferredDistance ?? this.preferredDistance,
      preferredGroup: preferredGroup ?? this.preferredGroup,
      totalSessions: totalSessions ?? this.totalSessions,
      ownedVenueIds: ownedVenueIds ?? this.ownedVenueIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'preferredTypes': preferredTypes.map((e) => e.name).toList(),
        'defaultGroup': defaultGroup.name,
        'assistantCustomization': assistantCustomization.toMap(),
        'likedTypes': likedTypes,
        'likedFeatures': likedFeatures,
        'preferredPrice': preferredPrice,
        'preferredDistance': preferredDistance,
        'preferredGroup': preferredGroup,
        'totalSessions': totalSessions,
        'ownedVenueIds': ownedVenueIds,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Backward compat: old docs had ownedVenueId (single string)
    final legacy = map['ownedVenueId'] as String?;
    final ids = (map['ownedVenueIds'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    if (legacy != null && !ids.contains(legacy)) ids.add(legacy);

    return UserProfile(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      preferredTypes: (map['preferredTypes'] as List<dynamic>? ?? [])
          .map((e) => VenueType.values.byName(e as String))
          .toList(),
      defaultGroup: map['defaultGroup'] != null
          ? GroupTag.values.byName(map['defaultGroup'] as String)
          : GroupTag.solo,
      assistantCustomization: AssistantCustomization.fromMap(
        map['assistantCustomization'] is Map
            ? Map<String, dynamic>.from(map['assistantCustomization'] as Map)
            : null,
      ),
      likedTypes: _intMap(map['likedTypes']),
      likedFeatures: _intMap(map['likedFeatures']),
      preferredPrice: _intMap(map['preferredPrice']),
      preferredDistance: _intMap(map['preferredDistance']),
      preferredGroup: _intMap(map['preferredGroup']),
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      ownedVenueIds: ids,
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw == null) return const {};
    return Map<String, int>.from(
      (raw as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    );
  }
}
