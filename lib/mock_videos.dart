/// Mock vertical (9:16) demo videos on the vidarka-tx-output CloudFront.
///
/// Keys live under `swaeq-mock-videos/9x16/hls/<name>/index.m3u8` and are served via
/// [AppConfig.assetsBaseUrl]. Mapped to senior content / slot ids so timeline
/// taps play the matching clip without waiting on a DynamoDB re-seed.
library;

import 'config.dart';

class MockVideos {
  MockVideos._();

  /// S3 object keys relative to the assets CDN root.
  static const Map<String, String> keysByContentId = {
    // Morning routine
    'scn-wake': 'swaeq-mock-videos/9x16/hls/5_Panchang_Kannada_9x16/index.m3u8',
    'scn-warm-water': 'swaeq-mock-videos/9x16/hls/4_methi_9x16/index.m3u8',
    'scn-prayer':
        'swaeq-mock-videos/9x16/hls/1_Kargrey_vasathi_Laxmi_9x16/index.m3u8',
    'scn-yoga':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    'scn-pranayama':
        'swaeq-mock-videos/9x16/hls/6_Breathe_9_16_English_s_9x16/index.m3u8',
    'scn-ragi': 'swaeq-mock-videos/9x16/hls/8_raagi_S_9x16/index.m3u8',
    'scn-morning-walk':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    // Devotional / midday
    'scn-cow-puja':
        'swaeq-mock-videos/9x16/hls/2_Kargrey_vasathi_Meaning_Kannada_9x16/index.m3u8',
    'scn-abhishek':
        'swaeq-mock-videos/9x16/hls/2_Kargrey_vasathi_Meaning_Kannada_9x16/index.m3u8',
    'scn-darshan':
        'swaeq-mock-videos/9x16/hls/3_vande_out_110sec_AV_9x16/index.m3u8',
    'scn-bhajan':
        'swaeq-mock-videos/9x16/hls/3_vande_out_110sec_AV_9x16/index.m3u8',
    // Evening movement / drink
    'scn-evening-walk':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    'scn-evening-drink': 'swaeq-mock-videos/9x16/hls/8_raagi_S_9x16/index.m3u8',
    // Extra methi clip for the second water reminder style slots if needed
    'scn-breakfast': 'swaeq-mock-videos/9x16/hls/4_1_methi2_9x16/index.m3u8',
  };

  /// Also allow lookup by timeline slot id (same clips where useful).
  static const Map<String, String> keysBySlotId = {
    'wake': 'swaeq-mock-videos/9x16/hls/5_Panchang_Kannada_9x16/index.m3u8',
    'warm-water': 'swaeq-mock-videos/9x16/hls/4_methi_9x16/index.m3u8',
    'prayer':
        'swaeq-mock-videos/9x16/hls/1_Kargrey_vasathi_Laxmi_9x16/index.m3u8',
    'yoga':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    'pranayama':
        'swaeq-mock-videos/9x16/hls/6_Breathe_9_16_English_s_9x16/index.m3u8',
    'ragi-drink': 'swaeq-mock-videos/9x16/hls/8_raagi_S_9x16/index.m3u8',
    'morning-walk':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    'cow-puja':
        'swaeq-mock-videos/9x16/hls/2_Kargrey_vasathi_Meaning_Kannada_9x16/index.m3u8',
    'abhishek':
        'swaeq-mock-videos/9x16/hls/2_Kargrey_vasathi_Meaning_Kannada_9x16/index.m3u8',
    'dev-darshan':
        'swaeq-mock-videos/9x16/hls/3_vande_out_110sec_AV_9x16/index.m3u8',
    'bhajan':
        'swaeq-mock-videos/9x16/hls/3_vande_out_110sec_AV_9x16/index.m3u8',
    'evening-walk':
        'swaeq-mock-videos/9x16/hls/7_exercise9_16_English_s_9x16/index.m3u8',
    'evening-drink': 'swaeq-mock-videos/9x16/hls/8_raagi_S_9x16/index.m3u8',
    'water-1330': 'swaeq-mock-videos/9x16/hls/4_1_methi2_9x16/index.m3u8',
    'water-2015': 'swaeq-mock-videos/9x16/hls/4_1_methi2_9x16/index.m3u8',
  };

  static String? keyFor({String? contentId, String? slotId}) {
    if (contentId != null && keysByContentId.containsKey(contentId)) {
      return keysByContentId[contentId];
    }
    if (slotId != null && keysBySlotId.containsKey(slotId)) {
      return keysBySlotId[slotId];
    }
    return null;
  }

  static String? urlFor({String? contentId, String? slotId}) {
    final key = keyFor(contentId: contentId, slotId: slotId);
    if (key == null) return null;
    final base = AppConfig.assetsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/$key';
  }
}
