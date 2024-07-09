import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:news/entity.dart';
import 'package:news/util.dart';

final newsService = _HackerNewsService();

class _HackerNewsService {
  final String baseUrl = 'https://hacker-news.firebaseio.com/v0';

  List<int>? entityIds;

  Future<List<NewsEntity>> getNews({
    required int start,
    required int end,
    bool force = false,
  }) async {
    Future<List<NewsEntity>> fetchNewsItem(List<int> storyIds) {
      List<Future<NewsEntity>> futureStories = [];

      for (int i = start; i < end && i < storyIds.length; i++) {
        futureStories.add(_fetchStory(storyIds[i]));
      }

      return Future.wait(futureStories);
    }

    if (force || entityIds == null) {
      final response = await http.get(Uri.parse('$baseUrl/topstories.json'));
      if (response.statusCode == 200) {
        entityIds = (jsonDecode(response.body) as List).cast();
      } else {
        throw CustomException(message: 'Failed to load news', isOffline: false);
      }
    }

    return fetchNewsItem(entityIds!);
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
