import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  int titleCount = 0;
  int contentCount = 0;

  // 🔴 각 필드 에러 상태를 직접 관리
  bool _emailIdError = false;
  bool _emailDomainError = false;
  bool _titleError = false;
  bool _contentError = false;

  @override
  void dispose() {
    _emailIdController.dispose();
    _emailDomainController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '문의',
          style: AppTextStyles.headline.copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "안녕하세요\n무엇을 도와드릴까요?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),

            // 이메일
            _buildLabel("답변 받을 이메일 주소", required: true),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emailIdController,
                    hint: "이메일 주소",
                    isError: _emailIdError,
                    onChanged: (_) {
                      if (_emailIdError) {
                        setState(() => _emailIdError = false);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text("@"),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _emailDomainController,
                    hint: "직접 입력",
                    isError: _emailDomainError,
                    onChanged: (_) {
                      if (_emailDomainError) {
                        setState(() => _emailDomainError = false);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            _buildLabel("문의 제목", required: true),
            const SizedBox(height: 6),

            Stack(
              alignment: Alignment.centerRight,
              children: [
                _buildTextField(
                  controller: _titleController,
                  hint: "제목을 입력해 주세요 (20자 이내)",
                  maxLength: 20,
                  isError: _titleError,
                  onChanged: (v) {
                    setState(() {
                      titleCount = v.length;
                      if (_titleError && v.isNotEmpty) {
                        _titleError = false;
                      }
                    });
                  },
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Text(
                    "$titleCount / 20",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              ],
            ),

            const SizedBox(height: 26),
            _buildLabel("문의 내용", required: true),
            const SizedBox(height: 6),

            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextFormField(
                  controller: _contentController,
                  maxLines: 8,
                  maxLength: 1000,
                  onChanged: (v) {
                    setState(() {
                      contentCount = v.length;
                      if (_contentError && v.isNotEmpty) {
                        _contentError = false;
                      }
                    });
                  },
                  decoration: _inputDecoration(
                    "내용을 입력해 주세요 (1000자 이내)",
                    isError: _contentError,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Text(
                    "$contentCount / 1000",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              ],
            ),

            const SizedBox(height: 30),

            // 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitInquiry,
                child: const Text(
                  "문의 접수",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _submitInquiry() async {
    final emailId = _emailIdController.text.trim();
    final emailDomain = _emailDomainController.text.trim();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    bool hasError = false;

    if (emailId.isEmpty) {
      _emailIdError = true;
      hasError = true;
    }
    if (emailDomain.isEmpty) {
      _emailDomainError = true;
      hasError = true;
    }
    if (title.isEmpty) {
      _titleError = true;
      hasError = true;
    }
    if (content.isEmpty) {
      _contentError = true;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final replyEmail = "$emailId@$emailDomain";

    try {
      await FirebaseFirestore.instance.collection('inquiries').add({
        'title': title,
        'content': content,
        'replyEmail': replyEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'ios', // 필요하면 안드/ios 구분용
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 저장 중 오류가 발생했습니다: $e')),
      );
      return;
    }
    _showInquiryCompleteDialog(replyEmail);
  }

  void _showInquiryCompleteDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            '문의가 접수되었습니다!',
            style: AppTextStyles.sectionTitle,
          ),
          content: SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '관리자가 확인 후 입력하신 이메일로 답변 드리겠습니다.\n($email)',
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // dialog 닫기
                  Navigator.pop(context); // InquiryScreen 닫기
                },
                child: Text(
                  '확인',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }




  // Label
  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black, // 기본 글자색
        ),
        children: required
            ? const [
          TextSpan(
            text: ' *',              // 별표는 따로
            style: TextStyle(
              color: Colors.red,     // 🔴 여기만 빨간색
            ),
          ),
        ]
            : [],
      ),
    );
  }

  // 공통 텍스트필드
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isError = false,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: _inputDecoration(hint, isError: isError),
    );
  }

  // 에러 여부에 따라 border 색만 바꿈 (에러 텍스트 없음 → 간격 변화 X)
  InputDecoration _inputDecoration(String hint, {bool isError = false}) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isError ? Colors.red : Colors.grey,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isError ? Colors.red : AppColors.primary,
      ),
    );

    return InputDecoration(
      hintText: hint,
      counterText: "",
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: baseBorder,
      focusedBorder: focusedBorder,
      // validator를 안 쓰기 때문에 errorBorder도 필요 없음
    );
  }
}
