import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateType {
  none,
  softUpdate,
  forceUpdate,
}

class UpdateInfo {
  final UpdateType type;
  final String storeUrl;
  final String latestVersion;

  UpdateInfo({
    required this.type,
    required this.storeUrl,
    required this.latestVersion,
  });
}

class VersionChecker {
  /// Firestore에서 버전 정보를 확인하여 업데이트 필요 여부를 반환합니다.
  static Future<UpdateInfo> checkUpdate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('version_info')
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          return UpdateInfo(
            type: UpdateType.forceUpdate, 
            storeUrl: 'NOT_FOUND', 
            latestVersion: 'DB_ERROR: Document app_settings/version_info not found.'
          );
        }
        return UpdateInfo(type: UpdateType.none, storeUrl: '', latestVersion: '');
      }

      final data = doc.data()!;
      final String minVersionStr = data['minimum_version'] ?? '0.0.0';
      final String latestVersionStr = data['latest_version'] ?? '0.0.0';
      
      final String iosStoreUrl = data['ios_store_url'] ?? '';
      final String androidStoreUrl = data['android_store_url'] ?? '';

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionStr = packageInfo.version;

      final current = _parseVersion(currentVersionStr);
      final minimum = _parseVersion(minVersionStr);
      final latest = _parseVersion(latestVersionStr);

      final String storeUrl = Platform.isIOS ? iosStoreUrl : androidStoreUrl;

      // 1. 강제 업데이트 확인 (current < minimum)
      if (_isVersionLower(current, minimum)) {
        return UpdateInfo(
          type: UpdateType.forceUpdate,
          storeUrl: storeUrl,
          latestVersion: latestVersionStr,
        );
      }

      // 2. 권장(Soft) 업데이트 확인 (current < latest)
      if (_isVersionLower(current, latest)) {
        return UpdateInfo(
          type: UpdateType.softUpdate,
          storeUrl: storeUrl,
          latestVersion: latestVersionStr,
        );
      }

      // 업데이트 불필요
      return UpdateInfo(type: UpdateType.none, storeUrl: '', latestVersion: '');
      
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ VersionChecker Exception caught: $e');
        debugPrint('$stack');
        // 개발(디버그) 모드에서는 오류를 시각적으로 보여주어 바로 원인을 찾을 수 있게 함
        return UpdateInfo(
          type: UpdateType.forceUpdate, 
          storeUrl: 'ERROR', 
          latestVersion: 'DB_ERROR: ${e.toString()}'
        );
      }
      // 실제 서비스(Release) 모드에서는 네트워크 불안정이나 DB 일시 오류 등으로 인해 
      // 앱 실행 자체가 막히는 대참사를 방지하기 위해 업데이트 확인을 조용히 통과시킵니다.
      return UpdateInfo(type: UpdateType.none, storeUrl: '', latestVersion: '');
    }
  }

  /// 버전 문자열 "1.2.3"을 정수 리스트 [1, 2, 3]로 변환
  static List<int> _parseVersion(String version) {
    try {
      String cleanVersion = version.replaceAll('"', '').replaceAll("'", '').trim();
      cleanVersion = cleanVersion.split('+').first;
      return cleanVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    } catch (e) {
      return [0, 0, 0];
    }
  }

  /// v1이 v2보다 낮으면 true 반환
  static bool _isVersionLower(List<int> v1, List<int> v2) {
    for (int i = 0; i < 3; i++) {
      final p1 = i < v1.length ? v1[i] : 0;
      final p2 = i < v2.length ? v2[i] : 0;
      if (p1 < p2) return true;
      if (p1 > p2) return false;
    }
    return false;
  }
}
