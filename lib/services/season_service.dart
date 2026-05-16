// ============================================================
// RAWBY — Season Service
// Detects the current season based on the user's region
// ============================================================

class SeasonService {
  SeasonService._();

  static String getCurrentSeason(String region) {
    final month = DateTime.now().month; // 1-12
    final southernCountries = [
      'australia',
      'new zealand',
      'argentina',
      'brazil',
      'south africa',
      'chile',
      'peru',
      'uruguay',
      'paraguay',
    ];

    final isSouthern = southernCountries.any(
      (c) => region.toLowerCase().contains(c),
    );

    if (month >= 3 && month <= 5) return isSouthern ? 'autumn' : 'spring';
    if (month >= 6 && month <= 8) return isSouthern ? 'winter' : 'summer';
    if (month >= 9 && month <= 11) return isSouthern ? 'spring' : 'autumn';
    return isSouthern ? 'summer' : 'winter';
  }

  static String getSeasonHint(String region, bool seasonalPrompts) {
    if (!seasonalPrompts) return '';
    final season = getCurrentSeason(region);
    return 'The current season in $region is $season. 1/3 prompts should lean into this season, 2/3 can be neutral, none may contradict it.';
  }
}
