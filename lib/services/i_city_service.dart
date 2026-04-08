abstract class ICityService {
  Future<Map<String, dynamic>> getAllCities();
  Future<List<Map<String, String>>> searchPlaces(String input, String apiKey);
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String apiKey);
}
