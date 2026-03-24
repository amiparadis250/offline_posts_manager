import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

// Default blog images to cycle through when user doesn't provide one
const _defaultImages = [
  'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=600',
  'https://images.unsplash.com/photo-1432821596592-e2c18b78144f?w=600',
  'https://images.unsplash.com/photo-1488190211105-8b0e65b80b4e?w=600',
  'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=600',
  'https://images.unsplash.com/photo-1471107340929-a87cd0f5b5f3?w=600',
  'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=600',
];

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List<Post> _posts = [];
  List<Post> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchCtrl.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterPosts() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _posts
          : _posts.where((p) => p.title.toLowerCase().contains(query) || p.content.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _loadPosts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final posts = await DatabaseHelper.instance.getAllPosts();
      setState(() { _posts = posts; _filtered = posts; _isLoading = false; });
      _filterPosts();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _getImage(Post post, int index) {
    return post.imageUrl.isNotEmpty ? post.imageUrl : _defaultImages[index % _defaultImages.length];
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Delete Post')]),
        content: Text('Delete "${post.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deletePost(post.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${post.title}" deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _loadPosts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful app bar
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('📝 My Blog', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search posts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchCtrl.clear())
                      : null,
                ),
              ),
            ),
          ),

          // Post count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${_filtered.length} post${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton.icon(onPressed: _loadPosts, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      _searchCtrl.text.isNotEmpty ? 'No posts match your search' : 'No posts yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchCtrl.text.isNotEmpty ? 'Try a different keyword' : 'Tap + to write your first post!',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _filtered[index];
                    final imageUrl = _getImage(post, index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PostCard(
                        post: post,
                        imageUrl: imageUrl,
                        formattedDate: _formatDate(post.createdAt),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post, imageUrl: imageUrl)),
                          );
                          _loadPosts();
                        },
                        onDelete: () => _deletePost(post),
                      ),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PostFormScreen()));
          _loadPosts();
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('New Post'),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final String imageUrl;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.imageUrl,
    required this.formattedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with gradient overlay
            Stack(
              children: [
                Hero(
                  tag: 'post-image-${post.id}',
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(Icons.image_not_supported, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ),
                // Date badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                // Delete button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black38,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Title & preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Read more', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
