import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:worship_hymn/constants/colors.dart';
import 'package:worship_hymn/constants/text_styles.dart';
import 'package:worship_hymn/providers/display_provider.dart';
import 'package:worship_hymn/screens/settings/theme_settings_screen.dart';
import 'package:worship_hymn/screens/settings/font_screen.dart';

class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: Text(
          '화면 설정',
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
      body: Consumer<DisplayProvider>(
        builder: (context, provider, child) {
          final isDark = provider.themeMode == ThemeMode.dark;
          return ListView(
            children: [

              _buildSwitchTile(
                context,
                title: '최근 본 찬송가 표시',
                value: provider.showRecent,
                onChanged: (val) => provider.toggleRecent(val),
              ),
              const SizedBox(height: 4),
              _buildSwitchTile(
                context,
                title: '인기 찬송가 TOP3 표시',
                value: provider.showPopular,
                onChanged: (val) => provider.togglePopular(val),
              ),
              const SizedBox(height: 20),
              _buildNavigationTile(
                context,
                title: '테마 설정 변경',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildNavigationTile(
                context,
                title: '글자 설정',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FontScreen()),
                  );
                },
              ),
              const SizedBox(height: 4),
              _buildSwitchTile(
                context,
                title: '다크 모드',
                value: isDark,
                onChanged: (val) {
                  provider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.getSurface(context),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.body(context).copyWith(fontSize: 16),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: AppColors.getSurface(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.body(context).copyWith(fontSize: 16),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
