import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_im_base/tencent_im_base.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';

import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/video_screen.dart';

class TIMUIKitVideoElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;

  const TIMUIKitVideoElem(this.message,
      {Key? key,
      this.isShowJump = false,
      this.clearJump,
      this.isFrom,
      this.isShowMessageReaction,
      required this.chatModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitVideoElemState();
}

class _TIMUIKitVideoElemState extends TIMUIKitState<TIMUIKitVideoElem> {
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  final MessageService _messageService = serviceLocator<MessageService>();
  late V2TimVideoElem stateElement = widget.message.videoElem!;
  Widget errorDisplay(TUITheme? theme) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        width: 1,
        color: Colors.black12,
      )),
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            Text(
              TIM_t("视频加载失败"),
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget generateSnapshot(TUITheme theme, int height) {
    if (!PlatformUtils().isWeb) {
      final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
      final timeStamp = widget.message.timestamp ?? current;
      if (current - timeStamp < 300) {
        if (stateElement.snapshotPath != null &&
            stateElement.snapshotPath != '') {
          File imgF = File(stateElement.snapshotPath!);
          bool isExist = imgF.existsSync();
          if (isExist) {
            return Image.file(File(stateElement.snapshotPath!),
                fit: BoxFit.fitWidth);
          }
        }
      }
    }

    if ((stateElement.snapshotUrl == null ||
            stateElement.snapshotUrl == '') &&
        (stateElement.snapshotPath == null ||
            stateElement.snapshotPath == '')) {
      return Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            border: Border.all(
              width: 1,
              color: Colors.black12,
            )),
        height: double.parse(height.toString()),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: theme.weakTextColor ?? Colors.grey,
                size: 28,
              )
            ],
          ),
        ),
      );
    }
    return (!kIsWeb && stateElement.snapshotUrl == null ||
            widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING)
        ? (stateElement.snapshotPath!.isNotEmpty
            ? Image.file(File(stateElement.snapshotPath!),
                fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth))
        : (kIsWeb ||
                stateElement.localSnapshotUrl == null ||
                stateElement.localSnapshotUrl == "")
            ? Image.network(stateElement.snapshotUrl!, fit: BoxFit.fitWidth)
            : Image.file(File(stateElement.localSnapshotUrl!),
                fit: BoxFit.fitWidth);
  }

  downloadMessageDetailAndSave() async {
    if (widget.message.msgID != null && widget.message.msgID != '') {
      if (widget.message.videoElem!.videoUrl == null ||
          widget.message.videoElem!.videoUrl == '') {
        final response = await _messageService.getMessageOnlineUrl(
            msgID: widget.message.msgID!);
        widget.message.videoElem = response.data!.videoElem;
        Future.delayed(const Duration(microseconds: 10), () {
          setState(() => stateElement = response.data!.videoElem!);
        });
      }
      if (!PlatformUtils().isWeb) {
        if (widget.message.videoElem!.localVideoUrl == null ||
            widget.message.videoElem!.localVideoUrl == '') {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: false);
        }
        if (widget.message.videoElem!.localSnapshotUrl == null ||
            widget.message.videoElem!.localSnapshotUrl == '') {
          _messageService.downloadMessage(
              msgID: widget.message.msgID!,
              messageType: 5,
              imageType: 0,
              isSnapshot: true);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    downloadMessageDetailAndSave();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final heroTag =
        "${widget.message.msgID ?? widget.message.id ?? widget.message.timestamp ?? DateTime.now().millisecondsSinceEpoch}${widget.isFrom}";

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false, // set to false
            pageBuilder: (_, __, ___) => VideoScreen(
              message: widget.message,
              heroTag: heroTag,
              videoElement: stateElement,
            ),
          ),
        );
      },
      child: ScreenUtilInit(
        builder: (BuildContext context, Widget? child) {
          return Hero(
              tag: heroTag,
              child: TIMUIKitMessageReactionWrapper(
                  chatModel: widget.chatModel,
                  message: widget.message,
                  isShowJump: widget.isShowJump,
                  isShowMessageReaction: widget.isShowMessageReaction ?? true,
                  clearJump: widget.clearJump,
                  isFromSelf: widget.message.isSelf ?? true,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    child: LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      double positionRadio = 0.56;
                      if (stateElement.snapshotWidth != null &&
                          stateElement.snapshotHeight != null &&
                          stateElement.snapshotWidth != 0 &&
                          stateElement.snapshotHeight != 0) {
                        positionRadio = (stateElement.snapshotWidth! /
                            stateElement.snapshotHeight!);
                      }

                      return ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: PlatformUtils().isWeb
                                  ? 300
                                  : constraints.maxWidth * 0.5,
                              maxHeight: min(constraints.maxHeight * 0.8, 300),
                              minHeight: 20,
                              minWidth: 20),
                          child: AspectRatio(
                            aspectRatio: positionRadio,
                            child: Stack(
                              children: <Widget>[
                                if (stateElement.snapshotUrl != null ||
                                    stateElement.snapshotUrl != null)
                                  AspectRatio(
                                    aspectRatio: positionRadio,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.transparent),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: generateSnapshot(
                                            theme,
                                            stateElement.snapshotHeight ??
                                                100))
                                  ],
                                ),
                                if (widget.message.status !=
                                            MessageStatus
                                                .V2TIM_MSG_STATUS_SENDING &&
                                        (stateElement.snapshotUrl != null ||
                                            stateElement.snapshotPath !=
                                                null) &&
                                        stateElement.videoPath != null ||
                                    stateElement.videoUrl != null)
                                  Positioned.fill(
                                    // alignment: Alignment.center,
                                    child: Center(
                                        child: Image.asset('images/play.png',
                                            package: 'tencent_cloud_chat_uikit',
                                            height: 64)),
                                  ),
                                Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Text(
                                        MessageUtils.formatVideoTime(widget
                                                    .message
                                                    .videoElem
                                                    ?.duration ??
                                                0)
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12))),
                              ],
                            ),
                          ));
                    }),
                  )));
        },
      ),
    );
  }
}
