class NewsEntity {
  final int id;
  final String title;
  final String? url;

  NewsEntity({required this.id, required this.title, required this.url});

  factory NewsEntity.fromJson(Map<String, dynamic> json) {
    return NewsEntity(
      id: json['id'],
      title: json['title'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
    };
  }
}
