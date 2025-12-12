import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/font_provider.dart';
import '../../../constants/text_styles.dart';
import '../../../constants/colors.dart';

class FontScreen extends StatelessWidget {
  const FontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("폰트 설정", style: AppTextStyles.headline(context).copyWith(fontSize: 22)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<FontProvider>(
        builder: (context, font, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 프리뷰 카드
                Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "미리보기",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: font.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "주 하나님 지으신 모든 세계",
                          style: AppTextStyles.headline(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "내 마음 속에 그리어 볼 때\n하늘의 별 울려 퍼지는 뇌성\n주님의 권능 우주에 찼네",
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. 글자 크기 조절
                Text("글자 크기", style: AppTextStyles.sectionTitle(context)),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("작게", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("${font.fontSizeStep}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("크게", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                        Slider(
                          value: font.fontSizeStep.toDouble(),
                          min: -5,
                          max: 5,
                          divisions: 10,
                          label: "${font.fontSizeStep}",
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            font.setFontSizeStep(val.toInt());
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. 글자 두께 조절
                Text("글자 두께", style: AppTextStyles.sectionTitle(context)),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("얇게", style: TextStyle(fontWeight: FontWeight.w200, color: Colors.grey)),
                            Text("${font.fontWeightStep}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("굵게", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
                          ],
                        ),
                        Slider(
                          value: font.fontWeightStep.toDouble(),
                          min: -2,
                          max: 2,
                          divisions: 4,
                          label: "${font.fontWeightStep}",
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            font.setFontWeightStep(val.toInt());
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. 초기화 버튼
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      font.setFontSizeStep(0);
                      font.setFontWeightStep(0);
                    },
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    label: const Text("설정 초기화", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
