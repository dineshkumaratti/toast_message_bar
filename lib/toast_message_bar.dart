library toast_message_bar;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:toast_message_bar/utils/toast_message_bar_route.dart' as route;

const String toastMessageBarRouteName = '/toastMessageBarRoute';

typedef ToastMessageBarStatusCallback = void Function(
    ToastMessageBarStatus? status);
typedef OnTap = void Function(ToastMessageBar toastMessageBar);

/// ignore: must_be_immutable
class ToastMessageBar<T> extends StatefulWidget {
  ToastMessageBar(
      {Key? key,
      this.title,
      this.titleColor,
      this.titleSize,
      this.message,
      this.messageSize,
      this.messageColor,
      this.titleText,
      this.messageText,
      this.icon,
      this.shouldIconPulse = true,
      this.maxWidth,
      this.margin = const EdgeInsets.all(0.0),
      this.padding = const EdgeInsets.all(16),
      this.borderRadius,
      this.textDirection = TextDirection.ltr,
      this.borderColor,
      this.borderWidth = 1.0,
      this.backgroundColor = const Color(0xFF303030),
      this.leftBarIndicatorColor,
      this.boxShadows,
      this.backgroundGradient,
      this.mainButton,
      this.onTap,
      this.duration,
      this.isDismissible = true,
      this.toastMessageBarDirection = ToastMessageBarDismissDirection.vertical,
      this.showProgressIndicator = false,
      this.progressIndicatorController,
      this.progressIndicatorBackgroundColor,
      this.progressIndicatorValueColor,
      this.toastMessageBarPosition = ToastMessageBarPosition.bottom,
      this.positionOffset = 0.0,
      this.toastMessageBarStyle = ToastMessageBarStyle.floating,
      this.forwardAnimationCurve = Curves.easeOutCirc,
      this.reverseAnimationCurve = Curves.easeOutCirc,
      this.animationDuration = const Duration(seconds: 1),
      ToastMessageBarStatusCallback? onStatusChanged,
      this.barBlur = 0.0,
      this.blockBackgroundInteraction = false,
      this.routeBlur,
      this.routeColor,
      this.userInputForm,
      this.endOffset,
      this.toastMessageBarRoute})
      : super(key: key) {
    onStatusChanged = onStatusChanged ?? (status) {};
  }

  /// Call your toast message
  ToastMessageBarStatusCallback? onStatusChanged;

  ///Add title for your toast message

  final String? title;

  ///Add title Size for your toast message

  final double? titleSize;

  ///Add title color for your toast message

  final Color? titleColor;

  ///Add message for your toast

  final String? message;

  ///Add message Size for your toast message

  final double? messageSize;

  ///Add message color for your toast message

  final Color? messageColor;

  ///Add title which you want to display i.e
  /// Widget such as Text('Your title') for your message

  final Widget? titleText;

  ///Add message which you want to display i.e
  /// Widget such as Text('Your messageText') for your message

  final Widget? messageText;

  ///Add backgroundColor for your toast message

  final Color backgroundColor;

  final Color? leftBarIndicatorColor;

  final List<BoxShadow>? boxShadows;

  final Gradient? backgroundGradient;

  final Widget? icon;

  final bool shouldIconPulse;

  final Widget? mainButton;

  final OnTap? onTap;

  final Duration? duration;

  final bool showProgressIndicator;

  final AnimationController? progressIndicatorController;

  final Color? progressIndicatorBackgroundColor;

  final Animation<Color>? progressIndicatorValueColor;

  final bool isDismissible;

  final double? maxWidth;

  final EdgeInsets margin;

  final EdgeInsets padding;

  final BorderRadius? borderRadius;

  final TextDirection textDirection;

  final Color? borderColor;

  final double borderWidth;

  final ToastMessageBarPosition toastMessageBarPosition;

  final double positionOffset;

  final ToastMessageBarDismissDirection toastMessageBarDirection;

  final ToastMessageBarStyle toastMessageBarStyle;

  final Curve forwardAnimationCurve;

  final Curve reverseAnimationCurve;

  final Duration animationDuration;

  final double barBlur;

  final bool blockBackgroundInteraction;

  final double? routeBlur;

  final Color? routeColor;

  final Form? userInputForm;

  final Offset? endOffset;

  route.ToastMessageBarRoute<T?>? toastMessageBarRoute;

  /// Initializing the Toast CallBack
  void initState() {
    onStatusChanged = onStatusChanged;
  }

  ///Adding Route for ToastMessage

  Future<T?> show(BuildContext context) async {
    toastMessageBarRoute = route.showToastMessageBar<T>(
      context: context,
      toastMessageBar: this,
    ) as route.ToastMessageBarRoute<T?>;

    return await Navigator.of(context, rootNavigator: false)
        .push(toastMessageBarRoute as Route<T>);
  }

  /// Adding Dismiss functionality to close the Toast
  Future<T?> dismiss([T? result]) async {
    if (toastMessageBarRoute == null) {
      return null;
    }

    if (toastMessageBarRoute!.isCurrent) {
      toastMessageBarRoute!.navigator!.pop(result);
      return toastMessageBarRoute!.completed;
    } else if (toastMessageBarRoute!.isActive) {
      toastMessageBarRoute!.navigator!.removeRoute(toastMessageBarRoute!);
    }

    return null;
  }

  /// Adding boolean values to identify the state of Toast Message
  bool isShowing() {
    if (toastMessageBarRoute == null) {
      return false;
    }
    return toastMessageBarRoute!.currentStatus == ToastMessageBarStatus.showing;
  }

  bool isDismissed() {
    if (toastMessageBarRoute == null) {
      return false;
    }
    return toastMessageBarRoute!.currentStatus ==
        ToastMessageBarStatus.dismissed;
  }

  bool isAppearing() {
    if (toastMessageBarRoute == null) {
      return false;
    }
    return toastMessageBarRoute!.currentStatus ==
        ToastMessageBarStatus.isAppearing;
  }

  bool isHiding() {
    if (toastMessageBarRoute == null) {
      return false;
    }
    return toastMessageBarRoute!.currentStatus ==
        ToastMessageBarStatus.isHiding;
  }

  @override
  State createState() => _ToastMessageBarState<T?>();
}

class _ToastMessageBarState<K extends Object?> extends State<ToastMessageBar<K>>
    with TickerProviderStateMixin {
  final Duration _pulseAnimationDuration = const Duration(seconds: 1);
  final Widget _emptyWidget = const SizedBox();
  final double _initialOpacity = 1.0;
  final double _finalOpacity = 0.4;

  GlobalKey? _backgroundBoxKey;
  ToastMessageBarStatus? currentStatus;
  AnimationController? _fadeController;
  late Animation<double> _fadeAnimation;
  late bool _isTitlePresent;
  late double _messageTopMargin;
  FocusScopeNode? _focusNode;
  late FocusAttachment _focusAttachment;
  late Completer<Size> _boxHeightCompleter;

  CurvedAnimation? _progressAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundBoxKey = GlobalKey();
    _boxHeightCompleter = Completer<Size>();

    assert(
        widget.userInputForm != null ||
            ((widget.message != null && widget.message!.isNotEmpty) ||
                widget.messageText != null),
        'A message is mandatory if you are not using userInputForm. Set either a message or messageText');

    _isTitlePresent = (widget.title != null || widget.titleText != null);
    _messageTopMargin = _isTitlePresent ? 6.0 : widget.padding.top;

    _configureLeftBarFuture();
    _configureProgressIndicatorAnimation();

    if (widget.icon != null && widget.shouldIconPulse) {
      _configurePulseAnimation();
      _fadeController?.forward();
    }

    _focusNode = FocusScopeNode();
    _focusAttachment = _focusNode!.attach(context);
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    widget.progressIndicatorController?.dispose();

    _focusAttachment.detach();
    _focusNode!.dispose();
    super.dispose();
  }

  void _configureLeftBarFuture() {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        final keyContext = _backgroundBoxKey!.currentContext;

        if (keyContext != null) {
          final box = keyContext.findRenderObject() as RenderBox;
          _boxHeightCompleter.complete(box.size);
        }
      },
    );
  }

  void _configureProgressIndicatorAnimation() {
    if (widget.showProgressIndicator &&
        widget.progressIndicatorController != null) {
      _progressAnimation = CurvedAnimation(
          curve: Curves.linear, parent: widget.progressIndicatorController!);
    }
  }

  void _configurePulseAnimation() {
    _fadeController =
        AnimationController(vsync: this, duration: _pulseAnimationDuration);
    _fadeAnimation = Tween(begin: _initialOpacity, end: _finalOpacity).animate(
      CurvedAnimation(
        parent: _fadeController!,
        curve: Curves.linear,
      ),
    );

    _fadeController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeController!.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        _fadeController!.forward();
      }
    });

    _fadeController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      heightFactor: 1.0,
      child: Material(
        color: widget.toastMessageBarStyle == ToastMessageBarStyle.floating
            ? Colors.transparent
            : widget.backgroundColor,
        child: SafeArea(
          minimum:
              widget.toastMessageBarPosition == ToastMessageBarPosition.bottom
                  ? EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom +
                          widget.positionOffset)
                  : EdgeInsets.only(
                      top: MediaQuery.of(context).viewInsets.top +
                          widget.positionOffset),
          bottom:
              widget.toastMessageBarPosition == ToastMessageBarPosition.bottom,
          top: widget.toastMessageBarPosition == ToastMessageBarPosition.top,
          left: false,
          right: false,
          child: _getToastMessageBar(),
        ),
      ),
    );
  }

  Widget _getToastMessageBar() {
    Widget toastMessageBar;

    if (widget.userInputForm != null) {
      toastMessageBar = _generateInputToastMessageBar();
    } else {
      toastMessageBar = _generateToastMessageBar();
    }

    return Stack(
      children: [
        FutureBuilder(
          future: _boxHeightCompleter.future,
          builder: (context, AsyncSnapshot<Size> snapshot) {
            if (snapshot.hasData) {
              if (widget.barBlur == 0) {
                return _emptyWidget;
              }
              return ClipRRect(
                borderRadius: widget.borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: widget.barBlur, sigmaY: widget.barBlur),
                  child: Container(
                    height: snapshot.data!.height,
                    width: snapshot.data!.width,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                ),
              );
            }
            return _emptyWidget;
          },
        ),
        toastMessageBar,
      ],
    );
  }

  Widget _generateInputToastMessageBar() {
    return Container(
      key: _backgroundBoxKey,
      constraints: widget.maxWidth != null
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundGradient,
        boxShadow: widget.boxShadows,
        borderRadius: widget.borderRadius,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 8.0, right: 8.0, bottom: 8.0, top: 16.0),
        child: FocusScope(
          node: _focusNode,
          autofocus: true,
          child: widget.userInputForm!,
        ),
      ),
    );
  }

  Widget _generateToastMessageBar() {
    return Container(
      key: _backgroundBoxKey,
      constraints: widget.maxWidth != null
          ? BoxConstraints(maxWidth: widget.maxWidth!)
          : null,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundGradient,
        boxShadow: widget.boxShadows,
        borderRadius: widget.borderRadius,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressIndicator(),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: _getAppropriateRowLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (widget.showProgressIndicator && _progressAnimation != null) {
      return AnimatedBuilder(
          animation: _progressAnimation!,
          builder: (_, __) {
            return LinearProgressIndicator(
              value: _progressAnimation!.value,
              backgroundColor: widget.progressIndicatorBackgroundColor,
              valueColor: widget.progressIndicatorValueColor,
            );
          });
    }

    if (widget.showProgressIndicator) {
      return LinearProgressIndicator(
        backgroundColor: widget.progressIndicatorBackgroundColor,
        valueColor: widget.progressIndicatorValueColor,
      );
    }

    return _emptyWidget;
  }

  List<Widget> _getAppropriateRowLayout() {
    double buttonRightPadding;
    var iconPadding = 0.0;
    if (widget.padding.right - 12 < 0) {
      buttonRightPadding = 4;
    } else {
      buttonRightPadding = widget.padding.right - 12;
    }

    if (widget.padding.left > 16.0) {
      iconPadding = widget.padding.left;
    }

    if (widget.icon == null && widget.mainButton == null) {
      return [
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon != null && widget.mainButton == null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: widget.padding.left,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon == null && widget.mainButton != null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: buttonRightPadding),
          child: _getMainActionButton(),
        ),
      ];
    } else {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: 8.0,
                      ),
                      child: _getTitleText(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: widget.messageText ?? _getDefaultNotificationText(),
              ),
            ],
          ),
        ),
        _getMainActionButton() != null
            ? Padding(
                padding: EdgeInsets.only(right: buttonRightPadding),
                child: _getMainActionButton(),
              )
            : _emptyWidget,
      ];
    }
  }

  Widget _buildLeftBarIndicator() {
    if (widget.leftBarIndicatorColor != null) {
      return FutureBuilder(
        future: _boxHeightCompleter.future,
        builder: (BuildContext buildContext, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasData) {
            return Container(
              width: 8.0,
              height: snapshot.data!.height,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius == null
                    ? null
                    : widget.textDirection == TextDirection.ltr
                        ? BorderRadius.only(
                            topLeft: widget.borderRadius!.topLeft,
                            bottomLeft: widget.borderRadius!.bottomLeft)
                        : BorderRadius.only(
                            topRight: widget.borderRadius!.topRight,
                            bottomRight: widget.borderRadius!.bottomRight),
                color: widget.leftBarIndicatorColor,
              ),
            );
          } else {
            return _emptyWidget;
          }
        },
      );
    } else {
      return _emptyWidget;
    }
  }

  Widget? _getIcon() {
    if (widget.icon != null && widget.icon is Icon && widget.shouldIconPulse) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: widget.icon,
      );
    } else if (widget.icon != null) {
      return widget.icon;
    } else {
      return _emptyWidget;
    }
  }

  Widget? _getTitleText() {
    return widget.titleText ??
        Text(
          widget.title ?? '',
          style: TextStyle(
              fontSize: widget.titleSize ?? 16.0,
              color: widget.titleColor ?? Colors.white,
              fontWeight: FontWeight.bold),
        );
  }

  Text _getDefaultNotificationText() {
    return Text(
      widget.message ?? '',
      style: TextStyle(
          fontSize: widget.messageSize ?? 14.0,
          color: widget.messageColor ?? Colors.white),
    );
  }

  Widget? _getMainActionButton() {
    if (widget.mainButton != null) {
      return widget.mainButton;
    } else {
      return null;
    }
  }
}

enum ToastMessageBarPosition { top, bottom }

enum ToastMessageBarStyle { floating, grounded }

enum ToastMessageBarDismissDirection { horizontal, vertical }

enum ToastMessageBarStatus { showing, dismissed, isAppearing, isHiding }
