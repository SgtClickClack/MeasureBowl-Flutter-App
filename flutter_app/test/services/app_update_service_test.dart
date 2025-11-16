import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('AppUpdateService', () {
    test('should return true when remote version is newer than local version',
        () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+1'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+1',
        buildNumber: '1',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check if update is available with remote version '1.0.0+2'
      final result = await service.isUpdateAvailable('1.0.0+2');

      // Assert: Should return true because local version is older
      expect(result, isTrue);
    });

    test('should return false when local version is the same as remote version',
        () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+1'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+1',
        buildNumber: '1',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check if update is available with the same remote version
      final result = await service.isUpdateAvailable('1.0.0+1');

      // Assert: Should return false because versions are the same
      expect(result, isFalse);
    });

    test('should return false when local version is newer than remote version',
        () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+2'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+2',
        buildNumber: '2',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check if update is available with older remote version '1.0.0+1'
      final result = await service.isUpdateAvailable('1.0.0+1');

      // Assert: Should return false because local version is newer
      expect(result, isFalse);
    });

    test('should compare semantic versions correctly (major.minor.patch)',
        () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+1'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+1',
        buildNumber: '1',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check with newer semantic version
      final result = await service.isUpdateAvailable('1.0.1+1');

      // Assert: Should return true because remote patch version is newer
      expect(result, isTrue);
    });

    test('should compare build numbers when semantic versions are equal',
        () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+1'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+1',
        buildNumber: '1',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check with same semantic version but higher build number
      final result = await service.isUpdateAvailable('1.0.0+5');

      // Assert: Should return true because remote build number is higher
      expect(result, isTrue);
    });

    test('should handle versions without build numbers', () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0' (no build)
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0',
        buildNumber: '0',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check with version that has build number
      final result = await service.isUpdateAvailable('1.0.0+1');

      // Assert: Should return true because remote has build number
      expect(result, isTrue);
    });

    test('should handle major version differences', () async {
      // Arrange: Create a mock PackageInfo with local version '1.0.0+1'
      final mockPackageInfo = PackageInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0+1',
        buildNumber: '1',
        buildSignature: '',
      );

      final service = AppUpdateService(packageInfo: mockPackageInfo);

      // Act: Check with newer major version
      final result = await service.isUpdateAvailable('2.0.0+1');

      // Assert: Should return true because remote major version is newer
      expect(result, isTrue);
    });
  });
}
