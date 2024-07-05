import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:news/entity.dart';
import 'package:news/util.dart';

final newsService = _HackerNewsService();

class _HackerNewsService {
  final String baseUrl = 'https://hacker-news.firebaseio.com/v0';

  Future<List<NewsEntity>> getNews(int page) async {
    const int pageSize = 20; // Define the number of items per page
    final int start = (page - 1) * pageSize;
    final int end = start + pageSize;

    final response = await http.get(Uri.parse('$baseUrl/topstories.json'));

    if (response.statusCode == 200) {
      List<dynamic> storyIds = jsonDecode(response.body);
      List<Future<NewsEntity>> futureStories = [];

      for (int i = start; i < end && i < storyIds.length; i++) {
        futureStories.add(_fetchStory(storyIds[i]));
      }

      return await Future.wait(futureStories);
    } else {
      throw CustomException(message: 'Failed to load news', isOffline: false);
    }
  }

  Future<NewsEntity> _fetchStory(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/item/$id.json'));

    if (response.statusCode == 200) {
      return NewsEntity.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load story');
    }
  }
}
