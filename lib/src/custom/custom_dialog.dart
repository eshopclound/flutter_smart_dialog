import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/helper/config.dart';
import 'package:flutter_smart_dialog/src/helper/dialog_proxy.dart';

import '../../flutter_smart_dialog.dart';
import 'base_dialog.dart';

///main function : custom dialog
class CustomDialog extends BaseDialog {
  static List<String> _tagList = [];
  static List<OverlayEntry> _overlayList = [];
  static Map<String, List<OverlayEntry>> _overlayMap = Map();

  CustomDialog({
    required Config config,
    required OverlayEntry overlayEntry,
  }) : super(config: config, overlayEntry: overlayEntry);

  Future<void> show({
    required Widget widget,
    required AlignmentGeometry alignment,
    required bool isPenetrate,
    required bool isUseAnimation,
    required Duration animationDuration,
    required bool isLoading,
    required Color maskColor,
    required bool clickBgDismiss,
    required bool antiShake,
    required Widget? maskWidget,
    required String? tag,
    required bool backDismiss,
    VoidCallback? onDismiss,
  }) async {
    var proxy = DialogProxy.instance;

    // anti-shake
    if (antiShake) {
      var now = DateTime.now();
      var isShake = proxy.dialogLastTime != null &&
          now.difference(proxy.dialogLastTime!) <
              SmartDialog.config.antiShakeTime;
      proxy.dialogLastTime = now;
      if (isShake) return;
    }

    // handle dialog stack
    var dialogInfo = DialogInfo(this, backDismiss, isUseAnimation);
    proxy.dialogList.add(dialogInfo);
    if (tag != null) proxy.dialogMap[tag] = dialogInfo;
    // insert the dialog carrier into the page

    OverlayEntry? lastEntry = getBelowOverlayEntry(tag, proxy.dialogMap);

    if (lastEntry != null) {
      if (tag != null) sortOverlayEntry(overlayEntry: overlayEntry, tag: tag);
      // Overlay.of(DialogProxy.context)!.insert(
      //   overlayEntry,
      //   below: lastEntry,
      // );
    } else {
      Overlay.of(DialogProxy.context)!.insert(
        overlayEntry,
        below: proxy.entryLoading,
      );
    }

    config.isExist = true;
    config.isExistMain = true;
    return mainDialog.show(
      widget: widget,
      alignment: alignment,
      isPenetrate: isPenetrate,
      isUseAnimation: isUseAnimation,
      animationDuration: animationDuration,
      isLoading: isLoading,
      maskColor: maskColor,
      maskWidget: maskWidget,
      clickBgDismiss: clickBgDismiss,
      onDismiss: onDismiss,
      onBgTap: () => dismiss(),
    );
  }

  static Future<void> dismiss({bool back = false, String? tag}) async {
    var proxy = DialogProxy.instance;
    var length = proxy.dialogList.length;
    if (length == 0) return;

    var info =
        (tag == null ? proxy.dialogList[length - 1] : proxy.dialogMap[tag]);
    if (info == null || (!info.backDismiss && back)) return;

    //handle close dialog
    if (tag != null) proxy.dialogMap.remove(tag);
    proxy.dialogList.remove(info);
    var customDialog = info.dialog;
    await customDialog.mainDialog.dismiss();
    customDialog.overlayEntry.remove();

    if (proxy.dialogList.length == 0) {
      proxy.config.isExistMain = false;
      if (!proxy.config.isExistLoading) {
        proxy.config.isExist = false;
      }
    }

    if (CustomDialog._overlayList.isNotEmpty) {
      Overlay.of(DialogProxy.context)!.insert(
        CustomDialog._overlayList.first,
        below: proxy.entryLoading,
      );
      deleteSortOverlayEntry();
    }
  }

  static setTagRank(List<String> tagList) {
    CustomDialog._tagList = tagList;
  }

  // 从下往上找最近的 OverlayEntry
  static OverlayEntry? getBelowOverlayEntry(
      String? tag, Map<String, DialogInfo> dialogMap) {
    if (tag != null && CustomDialog._tagList.contains(tag)) {
      int currentTagIndex = CustomDialog._tagList.indexOf(tag);
      for (int i = currentTagIndex; i >= 0; i--) {
        String tmpTag = CustomDialog._tagList[i];
        if (tmpTag != tag &&
            dialogMap[tmpTag] != null &&
            dialogMap[tmpTag]?.dialog.overlayEntry != null) {
          return dialogMap[tmpTag]?.dialog.overlayEntry;
        }
      }
    }
    return null;
  }

  // 将未显示的弹窗，根据优先级进行排序
  static sortOverlayEntry({required OverlayEntry overlayEntry , required String tag}) {
    List<OverlayEntry> list = CustomDialog._overlayMap[tag] ?? [];
    if (!list.contains(overlayEntry)) {
      list.add(overlayEntry);
    }
    CustomDialog._overlayMap[tag] = list;
    List<OverlayEntry> overlist = [];
    CustomDialog._tagList.forEach((element1) {
      List<OverlayEntry> list2 = CustomDialog._overlayMap[element1] ?? [];
      list2.forEach((element2) {
        overlist.add(element2);
      });
    });
    CustomDialog._overlayList = overlist;
  }

  static deleteSortOverlayEntry() {
    OverlayEntry overlayEntry = CustomDialog._overlayList.first;
    String? tag;
    CustomDialog._overlayMap.forEach((key, value) {
      if (value.contains(overlayEntry)) {
        tag = key;
      }
    });
    CustomDialog._overlayMap[tag]?.remove(overlayEntry);
    CustomDialog._overlayList.remove(overlayEntry);
  }

}

class DialogInfo {
  DialogInfo(this.dialog, this.backDismiss, this.isUseAnimation);

  final CustomDialog dialog;

  final bool backDismiss;

  final bool isUseAnimation;
}
