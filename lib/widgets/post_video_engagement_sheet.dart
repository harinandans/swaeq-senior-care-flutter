import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Like + optional comment after video completion.
Future<void> showPostVideoEngagementSheet({
  required BuildContext context,
  required String title,
  required bool initialLiked,
  required String initialComment,
  required void Function(bool liked, String comment) onSave,
}) {
  var liked = initialLiked;
  final commentCtrl = TextEditingController(text: initialComment);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How was this video?',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.brand900,
              ),
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: AppColors.slate600),
              ),
            ],
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setLocal) {
                return SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => setLocal(() => liked = !liked),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 28,
                    ),
                    label: Text(
                      liked ? 'Liked' : 'Like this video',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          liked ? AppColors.brand600 : AppColors.brand100,
                      foregroundColor:
                          liked ? Colors.white : AppColors.brand900,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Optional comment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                onSave(liked, commentCtrl.text.trim());
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand600,
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    },
  );
}
