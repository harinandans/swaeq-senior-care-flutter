/// Fallback / demo timeline schedule when the real API returns empty or
/// minimal data. Uses the same slot structure as /senior/today API response.
///
/// This ensures testers always see multiple playable cards with 9:16 mock videos.
library;

import 'config.dart';
import 'mock_videos.dart';

class MockTimeline {
  MockTimeline._();

  /// Generate a demo day schedule for testing.
  /// Returns a structure matching the /senior/today API response.
  static Map<String, dynamic> generateDaySchedule({String? date}) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final dateStr = date ??
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return {
      'date': dateStr,
      'summary': {
        'completed': 0,
        'total': _demoSlots.length,
      },
      'slots': _demoSlots,
    };
  }

  /// Check if API response needs mock fallback.
  /// Returns true if slots list is empty or has very few items.
  static bool needsFallback(Map<String, dynamic>? apiResponse) {
    if (apiResponse == null) return true;
    final slots = apiResponse['slots'] as List?;
    if (slots == null || slots.length < 3) return true;
    return false;
  }

  /// Merge mock slots into API response, preserving any real data.
  static Map<String, dynamic> withFallback(Map<String, dynamic>? apiResponse) {
    if (!needsFallback(apiResponse)) return apiResponse!;
    
    final mock = generateDaySchedule(date: apiResponse?['date']?.toString());
    
    if (apiResponse == null) return mock;
    
    final realSlots = List<Map<String, dynamic>>.from(
      apiResponse['slots'] as List? ?? [],
    );
    final mockSlots = List<Map<String, dynamic>>.from(mock['slots'] as List);
    
    final realIds = realSlots.map((s) => s['id']).toSet();
    for (final slot in mockSlots) {
      if (!realIds.contains(slot['id'])) {
        realSlots.add(slot);
      }
    }
    
    realSlots.sort((a, b) {
      final timeA = a['time']?.toString() ?? '00:00';
      final timeB = b['time']?.toString() ?? '00:00';
      return timeA.compareTo(timeB);
    });
    
    return {
      ...apiResponse,
      'slots': realSlots,
      'summary': {
        'completed': (apiResponse['summary'] as Map?)?['completed'] ?? 0,
        'total': realSlots.length,
      },
    };
  }

  static String _mockStreamUrl(String slotId) {
    final key = MockVideos.keysBySlotId[slotId];
    if (key == null) return '';
    final base = AppConfig.assetsBaseUrl.replaceAll(RegExp(r'/+\$'), '');
    return '$base/$key';
  }

  static final List<Map<String, dynamic>> _demoSlots = [
    {
      'id': 'wake',
      'time': '06:00',
      'title': 'Wake Up',
      'subtitle': 'Panchang & Morning Blessing',
      'mediaKind': 'video',
      'contentId': 'scn-wake',
      'streamUrl': _mockStreamUrl('wake'),
      'thumbUrl': '${AppConfig.assetsBaseUrl}/swaeq-mock-videos/thumbs/panchang.jpg',
    },
    {
      'id': 'warm-water',
      'time': '06:15',
      'title': 'Warm Water',
      'subtitle': 'Methi water for digestion',
      'mediaKind': 'video',
      'contentId': 'scn-warm-water',
      'streamUrl': _mockStreamUrl('warm-water'),
    },
    {
      'id': 'prayer',
      'time': '06:30',
      'title': 'Morning Prayer',
      'subtitle': 'Karaagre Vasate Lakshmi',
      'mediaKind': 'video',
      'contentId': 'scn-prayer',
      'streamUrl': _mockStreamUrl('prayer'),
    },
    {
      'id': 'yoga',
      'time': '07:00',
      'title': 'Yoga',
      'subtitle': 'Gentle stretching exercises',
      'mediaKind': 'video',
      'contentId': 'scn-yoga',
      'streamUrl': _mockStreamUrl('yoga'),
    },
    {
      'id': 'pranayama',
      'time': '07:30',
      'title': 'Pranayama',
      'subtitle': 'Breathing exercises',
      'mediaKind': 'video',
      'contentId': 'scn-pranayama',
      'streamUrl': _mockStreamUrl('pranayama'),
    },
    {
      'id': 'ragi-drink',
      'time': '08:00',
      'title': 'Ragi Malt',
      'subtitle': 'Healthy breakfast drink',
      'mediaKind': 'video',
      'contentId': 'scn-ragi',
      'streamUrl': _mockStreamUrl('ragi-drink'),
    },
    {
      'id': 'morning-walk',
      'time': '08:30',
      'title': 'Morning Walk',
      'subtitle': 'Light exercise',
      'mediaKind': 'video',
      'contentId': 'scn-morning-walk',
      'streamUrl': _mockStreamUrl('morning-walk'),
    },
    {
      'id': 'cow-puja',
      'time': '09:30',
      'title': 'Cow Puja',
      'subtitle': 'Gomata blessing',
      'mediaKind': 'video',
      'contentId': 'scn-cow-puja',
      'streamUrl': _mockStreamUrl('cow-puja'),
    },
    {
      'id': 'dev-darshan',
      'time': '10:00',
      'title': 'Dev Darshan',
      'subtitle': 'Temple visit / Bhajan',
      'mediaKind': 'video',
      'contentId': 'scn-darshan',
      'streamUrl': _mockStreamUrl('dev-darshan'),
    },
    {
      'id': 'water-1330',
      'time': '13:30',
      'title': 'Hydration',
      'subtitle': 'Afternoon water reminder',
      'mediaKind': 'video',
      'contentId': 'scn-breakfast',
      'streamUrl': _mockStreamUrl('water-1330'),
    },
    {
      'id': 'evening-walk',
      'time': '17:00',
      'title': 'Evening Walk',
      'subtitle': 'Gentle movement',
      'mediaKind': 'video',
      'contentId': 'scn-evening-walk',
      'streamUrl': _mockStreamUrl('evening-walk'),
    },
    {
      'id': 'bhajan',
      'time': '18:00',
      'title': 'Evening Bhajan',
      'subtitle': 'Devotional songs',
      'mediaKind': 'video',
      'contentId': 'scn-bhajan',
      'streamUrl': _mockStreamUrl('bhajan'),
    },
    {
      'id': 'evening-drink',
      'time': '19:00',
      'title': 'Evening Drink',
      'subtitle': 'Light refreshment',
      'mediaKind': 'video',
      'contentId': 'scn-evening-drink',
      'streamUrl': _mockStreamUrl('evening-drink'),
    },
    {
      'id': 'water-2015',
      'time': '20:15',
      'title': 'Night Hydration',
      'subtitle': 'Before sleep water',
      'mediaKind': 'video',
      'contentId': 'scn-warm-water',
      'streamUrl': _mockStreamUrl('water-2015'),
    },
  ];
}
