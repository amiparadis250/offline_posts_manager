import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/post.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;
  final Color color;
  final IconData icon;

  const PostDetailScreen({super.key, required this.post, required this.color, required this.icon});

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = post.image != null && post.image!.isNotEmpty;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 280 : 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(base64Decode(post.image!), fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
              title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 48),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.person, color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Staff Writer', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(_formatDate(post.createdAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  Text(
                    post.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag(label: 'Blog', color: colorScheme.primary),
                      _Tag(label: 'Offline', color: colorScheme.tertiary),
                      _Tag(label: 'Local', color: colorScheme.secondary),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostFormScreen(post: post)),
          );
          if (context.mounted) Navigator.pop(context);
        },
        icon: const Icon(Icons.edit),
        label: const Text('Edit Post'),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
