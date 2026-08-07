enum ListingKind {
  marketplace,
  rental,
  roommate,
  tutor,
  internship,
  event,
  service,
  business,
  deal,
}

extension ListingKindX on ListingKind {
  String get title => switch (this) {
        ListingKind.marketplace => 'Marketplace',
        ListingKind.rental => 'Rentals',
        ListingKind.roommate => 'Roommates',
        ListingKind.tutor => 'Tutors',
        ListingKind.internship => 'Internships',
        ListingKind.event => 'Events',
        ListingKind.service => 'Services',
        ListingKind.business => 'Businesses',
        ListingKind.deal => 'Deals',
      };

  String get emoji => switch (this) {
        ListingKind.marketplace => '🛍️',
        ListingKind.rental => '🏠',
        ListingKind.roommate => '👥',
        ListingKind.tutor => '🎓',
        ListingKind.internship => '💼',
        ListingKind.event => '🎟️',
        ListingKind.service => '🛠️',
        ListingKind.business => '🏪',
        ListingKind.deal => '🏷️',
      };

  String get actionLabel => switch (this) {
        ListingKind.marketplace => 'Message seller',
        ListingKind.rental => 'Contact landlord',
        ListingKind.roommate => 'Connect',
        ListingKind.tutor => 'Book tutor',
        ListingKind.internship => 'Apply now',
        ListingKind.event => 'Buy ticket',
        ListingKind.service => 'Book service',
        ListingKind.business => 'Message business',
        ListingKind.deal => 'Claim deal',
      };
}

class CampusListing {
  const CampusListing({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.emoji,
    required this.location,
    this.price,
    this.rating = 0,
    this.badge,
    this.owner = 'CampusX Member',
    this.details = const {},
  });

  final String id;
  final ListingKind kind;
  final String title;
  final String subtitle;
  final String description;
  final String emoji;
  final String location;
  final int? price;
  final double rating;
  final String? badge;
  final String owner;
  final Map<String, String> details;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'emoji': emoji,
        'location': location,
        'price': price,
        'rating': rating,
        'badge': badge,
        'owner': owner,
        'details': details,
      };

  factory CampusListing.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? ListingKind.marketplace.name;
    final kind = ListingKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => ListingKind.marketplace,
    );
    return CampusListing(
      id: json['id'] as String,
      kind: kind,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? kind.emoji,
      location: json['location'] as String? ?? 'Campus',
      price: (json['price'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      badge: json['badge'] as String?,
      owner: json['owner'] as String? ?? 'CampusX Member',
      details: Map<String, String>.from(json['details'] as Map? ?? const {}),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.pending = false,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final bool pending;

  ChatMessage copyWith({bool? pending}) => ChatMessage(
        id: id,
        text: text,
        sentAt: sentAt,
        isMine: isMine,
        pending: pending ?? this.pending,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'isMine': isMine,
        'pending': pending,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
        isMine: json['isMine'] as bool? ?? false,
        pending: json['pending'] as bool? ?? false,
      );
}

class CampusState {
  const CampusState({
    required this.darkMode,
    required this.onboarded,
    required this.university,
    required this.interests,
    required this.savedIds,
    required this.messages,
    required this.createdListings,
  });

  factory CampusState.initial() => const CampusState(
        darkMode: false,
        onboarded: false,
        university: 'Kabale University',
        interests: {},
        savedIds: {},
        messages: {},
        createdListings: [],
      );

  final bool darkMode;
  final bool onboarded;
  final String university;
  final Set<String> interests;
  final Set<String> savedIds;
  final Map<String, List<ChatMessage>> messages;
  final List<CampusListing> createdListings;

  CampusState copyWith({
    bool? darkMode,
    bool? onboarded,
    String? university,
    Set<String>? interests,
    Set<String>? savedIds,
    Map<String, List<ChatMessage>>? messages,
    List<CampusListing>? createdListings,
  }) {
    return CampusState(
      darkMode: darkMode ?? this.darkMode,
      onboarded: onboarded ?? this.onboarded,
      university: university ?? this.university,
      interests: interests ?? this.interests,
      savedIds: savedIds ?? this.savedIds,
      messages: messages ?? this.messages,
      createdListings: createdListings ?? this.createdListings,
    );
  }

  Map<String, dynamic> toJson() => {
        'darkMode': darkMode,
        'onboarded': onboarded,
        'university': university,
        'interests': interests.toList(),
        'savedIds': savedIds.toList(),
        'messages': messages.map(
          (key, value) => MapEntry(key, value.map((message) => message.toJson()).toList()),
        ),
        'createdListings': createdListings.map((listing) => listing.toJson()).toList(),
      };

  factory CampusState.fromJson(Map<String, dynamic> json) {
    final rawMessages = Map<String, dynamic>.from(json['messages'] as Map? ?? const {});
    return CampusState(
      darkMode: json['darkMode'] as bool? ?? false,
      onboarded: json['onboarded'] as bool? ?? false,
      university: json['university'] as String? ?? 'Kabale University',
      interests: Set<String>.from(json['interests'] as List? ?? const []),
      savedIds: Set<String>.from(json['savedIds'] as List? ?? const []),
      messages: rawMessages.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
        ),
      ),
      createdListings: (json['createdListings'] as List? ?? const [])
          .map((item) => CampusListing.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
