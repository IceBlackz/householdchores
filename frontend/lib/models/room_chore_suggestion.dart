import '../constants/app_constants.dart';

class RoomChoreSuggestion {
  const RoomChoreSuggestion({
    required this.id,
    required this.prompt,
    required this.title,
    required this.description,
    required this.desiredInterval,
    required this.maxInterval,
    this.intervalUnit = IntervalUnits.days,
    this.icon = 'task_alt',
  });

  final String id;
  final String prompt;
  final String title;
  final String description;
  final int desiredInterval;
  final int maxInterval;
  final String intervalUnit;
  final String icon;

  Map<String, dynamic> toChoreBody(String roomId) {
    return {
      'title': title,
      'description': description,
      'interval_desired_days': desiredInterval,
      'interval_max_days': maxInterval,
      'interval_unit': intervalUnit,
      'season': 'All',
      'default_assignee': '',
      'onetimeonly_assignee': '',
      'season_spring_override': 0,
      'season_summer_override': 0,
      'season_autumn_override': 0,
      'season_winter_override': 0,
      'room': roomId,
    };
  }
}

class RoomChoreSuggestions {
  static const basics = [
    RoomChoreSuggestion(
      id: 'floor',
      prompt: 'Do you want to add cleaning the floor?',
      title: 'Clean the floor',
      description: 'Vacuum, sweep, or mop the floor as needed.',
      desiredInterval: 7,
      maxInterval: 14,
      icon: 'cleaning_services',
    ),
    RoomChoreSuggestion(
      id: 'windows',
      prompt: 'Does this room have windows you want to clean?',
      title: 'Clean windows',
      description: 'Clean glass, sill, and visible fingerprints.',
      desiredInterval: 1,
      maxInterval: 3,
      intervalUnit: IntervalUnits.months,
      icon: 'window',
    ),
    RoomChoreSuggestion(
      id: 'dust',
      prompt: 'Should dusting be tracked here?',
      title: 'Dust surfaces',
      description: 'Dust shelves, lamps, ledges, and other visible surfaces.',
      desiredInterval: 14,
      maxInterval: 30,
      icon: 'auto_awesome',
    ),
    RoomChoreSuggestion(
      id: 'trash',
      prompt: 'Is there a bin that needs emptying?',
      title: 'Empty bin',
      description: 'Empty the room bin and replace the liner if needed.',
      desiredInterval: 7,
      maxInterval: 10,
      icon: 'delete_outline',
    ),
    RoomChoreSuggestion(
      id: 'tidy',
      prompt: 'Do you want a general tidy/reset task?',
      title: 'Tidy and reset',
      description: 'Put items back where they belong and clear clutter.',
      desiredInterval: 3,
      maxInterval: 7,
      icon: 'inventory_2',
    ),
  ];

  static List<RoomChoreSuggestion> forRoomName(String roomName) {
    final normalized = roomName.toLowerCase();
    final suggestions = [...basics];

    if (normalized.contains('bath') ||
        normalized.contains('toilet') ||
        normalized.contains('wc')) {
      suggestions.addAll(_bathroom);
    }

    if (normalized.contains('kitchen')) {
      suggestions.addAll(_kitchen);
    }

    if (normalized.contains('bed')) {
      suggestions.addAll(_bedroom);
    }

    return suggestions;
  }

  static const _bathroom = [
    RoomChoreSuggestion(
      id: 'toilet',
      prompt: 'Do you want to track cleaning the toilet?',
      title: 'Clean toilet',
      description: 'Clean bowl, seat, outside, and nearby floor.',
      desiredInterval: 7,
      maxInterval: 10,
      icon: 'wc',
    ),
    RoomChoreSuggestion(
      id: 'sink_mirror',
      prompt: 'Should the sink and mirror be a separate task?',
      title: 'Clean sink and mirror',
      description: 'Clean sink, tap, mirror, and toothpaste spots.',
      desiredInterval: 7,
      maxInterval: 14,
      icon: 'water_drop',
    ),
  ];

  static const _kitchen = [
    RoomChoreSuggestion(
      id: 'counters',
      prompt: 'Do you want a counter and stovetop reset?',
      title: 'Wipe counters and stovetop',
      description: 'Clear crumbs, wipe counters, and clean stovetop spills.',
      desiredInterval: 1,
      maxInterval: 2,
      icon: 'countertops',
    ),
    RoomChoreSuggestion(
      id: 'fridge',
      prompt: 'Should fridge cleanup be tracked?',
      title: 'Check and clean fridge',
      description: 'Remove old food and wipe obvious spills.',
      desiredInterval: 14,
      maxInterval: 30,
      icon: 'kitchen',
    ),
  ];

  static const _bedroom = [
    RoomChoreSuggestion(
      id: 'bedding',
      prompt: 'Do you want to track changing bedding?',
      title: 'Change bedding',
      description: 'Change sheets and pillowcases.',
      desiredInterval: 14,
      maxInterval: 21,
      icon: 'bed',
    ),
  ];
}
