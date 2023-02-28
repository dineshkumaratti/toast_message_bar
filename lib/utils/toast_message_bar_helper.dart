import 'package:flutter/material.dart';

import '../toast_message_bar.dart';

class ToastMessageBarHelper {
  static ToastMessageBar createSuccess(
      {required String message,
      String? title,
      Duration duration = const Duration(seconds: 3)}) {
    return ToastMessageBar(
      title: title,
      message: message,
      icon: Icon(
        Icons.check_circle,
        color: Colors.green[300],
      ),
      leftBarIndicatorColor: Colors.green[300],
      duration: duration,
    );
  }

  static ToastMessageBar createInformation(
      {required String message,
      String? title,
      Duration duration = const Duration(seconds: 3)}) {
    return ToastMessageBar(
      title: title,
      message: message,
      icon: Icon(
        Icons.info_outline,
        size: 28.0,
        color: Colors.blue[300],
      ),
      leftBarIndicatorColor: Colors.blue[300],
      duration: duration,
    );
  }

  static ToastMessageBar createError(
      {required String message,
      String? title,
      Duration duration = const Duration(seconds: 3)}) {
    return ToastMessageBar(
      title: title,
      message: message,
      icon: Icon(
        Icons.warning,
        size: 28.0,
        color: Colors.red[300],
      ),
      leftBarIndicatorColor: Colors.red[300],
      duration: duration,
    );
  }

  static ToastMessageBar createAction(
      {required String message,
      required Widget button,
      String? title,
      Duration duration = const Duration(seconds: 3)}) {
    return ToastMessageBar(
      title: title,
      message: message,
      duration: duration,
      mainButton: button,
    );
  }

  static ToastMessageBar createLoading(
      {required String message,
      required LinearProgressIndicator linearProgressIndicator,
      String? title,
      Duration duration = const Duration(seconds: 3),
      AnimationController? progressIndicatorController,
      Color? progressIndicatorBackgroundColor}) {
    return ToastMessageBar(
      title: title,
      message: message,
      icon: Icon(
        Icons.cloud_upload,
        color: Colors.blue[300],
      ),
      duration: duration,
      showProgressIndicator: true,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
    );
  }

  static ToastMessageBar createInputToastMessageBar({required Form textForm}) {
    return ToastMessageBar(
      duration: null,
      userInputForm: textForm,
    );
  }
}
