import 'dart:convert';
import 'dart:developer';

import 'package:go_sathi/services/i_city_service.dart';
import 'package:go_sathi/utils/apis.dart';
import 'package:http/http.dart' as http;

class CityService with Apis implements ICityService {
  @override
  Future<Map<String, dynamic>> getAllCities() async {
    try {
      final uri = Uri.parse(getAllCitiesUrl);
      final body = {
        "access_token": "d1b45ce4b219230c49f7f7b0013e70d1",
        "user": "Taxivaxi",
      };
      final response = await http.post(uri, body: body);
      log(response.body);
      final data = json.decode(response.body);
      return {"statusCode": response.statusCode, "body": data};
    } catch (e) {
      return {
        "statusCode": 500,
        "body": {"success": "0", "error": "Something went wrong"},
      };
    }
  }

  @override
  Future<List<Map<String, String>>> searchPlaces(
    String input,
    String apiKey,
  ) async {
    if (input.isEmpty) return [];

    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete'
      '?input=$input'
      '&key=$apiKey',
    );
    print(url);
    try {
      final response = await http.get(url);
      print('Places API response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = <Map<String, String>>[];
        if (data['suggestions'] != null) {
          for (var suggestion in data['suggestions']) {
            final placePrediction = suggestion['placePrediction'];
            if (placePrediction != null) {
              suggestions.add({
                'description': placePrediction['text']['text'] ?? '',
                'placeId': placePrediction['placeId'] ?? '',
              });
            }
          }
        }
        return suggestions;
      } else {
        print('Places API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Search places error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getPlaceDetails(
    String placeId,
    String apiKey,
  ) async {
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places/$placeId'
      '?key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['location'];
        if (location != null) {
          return {
            'name': data['displayName']?['text'] ?? '',
            'lat': double.tryParse(location['latitude'].toString()),
            'lng': double.tryParse(location['longitude'].toString()),
            'address': data['formattedAddress'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('Place details error: $e');
      return null;
    }
  }
}
