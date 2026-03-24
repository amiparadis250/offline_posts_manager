import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class PostFormScreen extends StatefulWidget {
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _imageCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.post?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.post?.content ?? '');
    _imageCtrl = TextEditingController(text: widget.post?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final post = Post(
        id: widget.post?.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: _isEditing ? widget.post!.createdAt : DateTime.now().toIso8601String(),
        imageUrl: _imageCtrl.text.trim(),
      );
      if (_isEditing) {
        await DatabaseHelper.instance.updatePost(post);
      } else {
        await DatabaseHelper.instance.insertPost(post);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ListenableBuilder(
                listenable: _imageCtrl,
                builder: (context, _) {
                  final url = _imageCtrl.text.trim();
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: url.isNotEmpty
                        ? ClipRRect(
                            key: ValueKey(url),
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              url,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.red),
                                    SizedBox(height: 8),
                                    Text('Invalid image URL', style: TextStyle(color: Colors.red)),
                                  ],
                                )),
                              ),
                            ),
                          )
                        : Container(
                            key: const ValueKey('placeholder'),
                            height: 180,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Add a cover image URL', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            )),
                          ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Image URL field
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  hintText: 'https://images.unsplash.com/...',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Give your post a catchy title...',
                  prefixIcon: Icon(Icons.title),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Content
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your blog post here...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 100), child: Icon(Icons.article)),
                ),
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _savePost,
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                  label: Text(_isEditing ? 'Update Post' : 'Publish Post', style: const TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


