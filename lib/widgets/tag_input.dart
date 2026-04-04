import 'package:flutter/material.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final List<String>? suggestedTags;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.suggestedTags,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();

  void _addTag(String tag) {
    tag = tag.trim().toLowerCase();
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      final newTags = List<String>.from(widget.tags)..add(tag);
      widget.onTagsChanged(newTags);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag input field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'Add tags (e.g., urgent, work, personal)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.local_offer),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text),
              tooltip: 'Add tag',
            ),
          ),
          onSubmitted: _addTag,
        ),
        
        const SizedBox(height: 8),
        
        // Tag chips
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.shade50,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                avatar: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.tag, size: 10, color: Colors.white),
                ),
              );
            }).toList(),
          ),
        
        // Suggested tags
        if (widget.suggestedTags != null && widget.suggestedTags!.isNotEmpty && widget.tags.length < 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested tags:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.suggestedTags!.map((tag) {
                    if (widget.tags.contains(tag)) return const SizedBox.shrink();
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () => _addTag(tag),
                      backgroundColor: Colors.grey.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}