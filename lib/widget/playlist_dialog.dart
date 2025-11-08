import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class PlaylistDialog extends StatelessWidget {
  final String title;
  final String confirmText;
  final TextEditingController? controller;
  final VoidCallback? onConfirm;
  final bool showTextField;

  const PlaylistDialog({
    super.key,
    required this.title,
    required this.confirmText,
    this.controller,
    this.onConfirm,
    this.showTextField = true, // ✅ 기본값 true
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Text(title, style: AppTextStyles.sectionTitle),
      content: SizedBox(
        width: 300,
        child: showTextField
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              hintText: '제목을 입력하세요',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 16),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
            ),
          ),
        )
            : const SizedBox.shrink(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _dialogBtn(
              context,
              '취소',
              Colors.grey.shade200,
              Colors.black,
                  () => Navigator.pop(context, false),
            ),
            const SizedBox(width: 10),
            _dialogBtn(
              context,
              confirmText,
              AppColors.primary,
              Colors.white,
                  () {
                onConfirm?.call();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _dialogBtn(
      BuildContext ctx,
      String text,
      Color bg,
      Color fg,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: 74,
      height: 38,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: fg,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
