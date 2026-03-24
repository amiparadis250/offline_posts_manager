class Post {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final String? image; // base64 encoded image

  Post({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'image': image,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      image: map['image'] as String?,
    );
  }
}
