import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  ///Checking that camera and storage permission granted or not (Platform vise)
  static Future<bool> cameraAndStoragePermissionsGranted() async {
    try {
      PermissionStatus cameraPermissionStatus = await _getCameraPermission();
      switch (Platform.isAndroid ? 1 : 0) {
        ///For Android
        case 1:
          PermissionStatus storagePermissionStatus =
              await _getStoragePermission();

          if (cameraPermissionStatus == PermissionStatus.granted &&
              storagePermissionStatus == PermissionStatus.granted) {
            return true;
          } else {
            _handleInvalidPermissions(
                cameraPermissionStatus, storagePermissionStatus);
            return false;
          }

        ///For iOS
        case 0:
          if (cameraPermissionStatus == PermissionStatus.granted) {
            return true;
          } else {
            _handleInvalidPermissions(cameraPermissionStatus, null);
            return false;
          }

        default:
          return false;
      }
    } catch (e, s) {
      debugPrint('Exception cameraAndStoragePermissionsGranted: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  ///Checking camera permission
  static Future<PermissionStatus> _getCameraPermission() async {
    try {
      PermissionStatus permission = await Permission.camera.status;
      if (permission != PermissionStatus.granted) {
        PermissionStatus permissionStatus = await Permission.camera.request();
        return permissionStatus;
      } else {
        return permission;
      }
    } catch (e, s) {
      debugPrint('Exception _getCameraPermission: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  ///Checking storage permission
  static Future<PermissionStatus> _getStoragePermission() async {
    try {
      PermissionStatus permission = await Permission.storage.status;
      if (permission != PermissionStatus.granted) {
        PermissionStatus permissionStatus = await Permission.storage.request();
        return permissionStatus;
      } else {
        return permission;
      }
    } catch (e, s) {
      debugPrint('Exception _getStoragePermission: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  ///Checking permission is available or not (Platform specific)
  static void _handleInvalidPermissions(
    PermissionStatus cameraPermissionStatus,
    PermissionStatus? storagePermissionStatus,
  ) async {
    try {
      if (Platform.isAndroid) {
        if (storagePermissionStatus == null) {
          PermissionStatus storagePermissionStatus =
              await _getStoragePermission();
          if (storagePermissionStatus.isPermanentlyDenied) {
            await openAppSettings();
            return;
          }
        } else {
          if (storagePermissionStatus.isPermanentlyDenied) {
            await openAppSettings();
            return;
          }
        }
      }

      if (cameraPermissionStatus.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }

      ((cameraPermissionStatus == PermissionStatus.denied) &&
              (storagePermissionStatus == PermissionStatus.denied))
          ? permissionDeniedMessage()
          : permissionDisabledMessage();
    } catch (e, s) {
      debugPrint('Exception _handleInvalidPermissions: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  ///Throw message for permission denied
  static void permissionDeniedMessage() {
    throw PlatformException(
      code: "PERMISSION_DENIED",
      message: "Access to camera and storage denied",
      details: null,
    );
  }

  ///Throw message for permission disabled
  static void permissionDisabledMessage() {
    throw PlatformException(
      code: "PERMISSION_DISABLED",
      message: "Camera data is not available on device",
      details: null,
    );
  }
}
