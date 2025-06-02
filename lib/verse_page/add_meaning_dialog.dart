import 'package:flutter/material.dart';
import 'word_meaning_service.dart';

class AddMeaningDialog extends StatefulWidget {
  final String word;
  final Function(String, String) onMeaningAdded;
  
  const AddMeaningDialog({
    Key? key,
    required this.word,
    required this.onMeaningAdded,
  }) : super(key: key);

  @override
  State<AddMeaningDialog> createState() => _AddMeaningDialogState();
}

class _AddMeaningDialogState extends State<AddMeaningDialog> {
  final TextEditingController _meaningController = TextEditingController();
  final WordMeaningService _wordMeaningService = WordMeaningService();
  bool _isLoading = false;

  @override
  void dispose() {
    _meaningController.dispose();
    super.dispose();
  }

  void _addMeaning() async {
    if (_meaningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meaning')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save to the word meaning service
      await _wordMeaningService.addCustomMeaning(
        widget.word,
        _meaningController.text.trim(),
      );

      // Call the callback
      widget.onMeaningAdded(widget.word, _meaningController.text.trim());

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added meaning for "${widget.word}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding meaning: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add meaning for "${widget.word}"',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This word doesn\'t have a meaning yet. Please provide one:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _meaningController,
            decoration: const InputDecoration(
              hintText: 'Enter the meaning...',
              border: OutlineInputBorder(),
              helperText: 'Example: "of the embodied soul"',
            ),
            maxLines: 3,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMeaning,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Add Meaning'),
        ),
      ],
    );
  }
}