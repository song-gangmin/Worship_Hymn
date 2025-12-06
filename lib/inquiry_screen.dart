import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailIdController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  int titleCount = 0;
  int contentCount = 0;

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
        title: const Text('문의', style: AppTextStyles.headline),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("안녕하세요\n무엇을 도와드릴까요?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 28),

              // 이메일 제목
              _buildLabel("답변 받을 이메일 주소 *"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _emailIdController,
                      hint: "이메일 주소",
                      validator: (v) => v == null || v.isEmpty ? "필수 입력" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text("@"),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _emailDomainController,
                      hint: "직접 입력",
                      validator: (v) => v == null || v.isEmpty ? "필수 입력" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),
              _buildLabel("문의 제목 *"),
              const SizedBox(height: 6),

              Stack(
                alignment: Alignment.centerRight,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    hint: "제목을 입력해 주세요 (20자 이내)",
                    maxLength: 20,
                    onChanged: (v) => setState(() => titleCount = v.length),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "필수 입력"
                        : null,
                  ),
                  Positioned(
                    right: 12,
                    bottom: 10,
                    child: Text("$titleCount / 20",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 26),
              _buildLabel("문의 내용 *"),
              const SizedBox(height: 6),

              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextFormField(
                    controller: _contentController,
                    maxLines: 8,
                    maxLength: 1000,
                    onChanged: (v) => setState(() => contentCount = v.length),
                    decoration: _inputDecoration("내용을 입력해 주세요 (1000자 이내)"),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "필수 입력"
                        : null,
                  ),
                  Positioned(
                    right: 12,
                    bottom: 10,
                    child: Text("$contentCount / 1000",
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
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  문의 제출 함수
  // ─────────────────────────────────────────────
  void _submitInquiry() {
    if (!_formKey.currentState!.validate()) return;

    final email = "${_emailIdController.text}@${_emailDomainController.text}";
    final title = _titleController.text;
    final content = _contentController.text;

    // TODO: Firestore or backend 업로드 로직 추가 가능
    // FirebaseFirestore.instance.collection("inquiries").add({...})

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("문의가 접수되었습니다!"),
        content: Text("답변은 입력하신 이메일로 발송됩니다.\n($email)"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog 닫기
              Navigator.pop(context); // InquiryScreen 닫기
            },
            child: const Text("확인"),
          )
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Label
  // ─────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ));
  }

  // ─────────────────────────────────────────────
  //  공통 텍스트필드
  // ─────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      counterText: "",
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}
