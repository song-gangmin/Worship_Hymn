import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/providers/color_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          '테마 설정 변경',
          style: AppTextStyles.headline(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ColorProvider>(
        builder: (context, colorProvider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 16),
                child: Text('색상을 선택해 주세요', style: AppTextStyles.sectionTitle(context)),
              ),
              Container(
                color: AppColors.getSurface(context),
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: colorProvider.availableColors.map((color) {
                    final isSelected = colorProvider.primaryColor.value == color.value;
                    return GestureDetector(
                      onTap: () => colorProvider.setColor(color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                  width: 3,
                                )
                              : Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12,
                                  width: 1,
                                ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
