import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../toast_message_bar.dart';

class ToastMessageBarRoute<T> extends OverlayRoute<T> {
  final ToastMessageBar toastMessageBar;
  final Builder _builder;
  final Completer<T> _transitionCompleter = Completer<T>();
  final ToastMessageBarStatusCallback? _onStatusChanged;

  Animation<double>? _filterBlurAnimation;
  Animation<Color?>? _filterColorAnimation;
  Alignment? _initialAlignment;
  Alignment? _endAlignment;
  bool _wasDismissedBySwipe = false;
  Timer? _timer;
  T? _result;
  ToastMessageBarStatus? currentStatus;

  ToastMessageBarRoute({
    required this.toastMessageBar,
    RouteSettings? settings,
  })  : _builder = Builder(builder: (BuildContext innerContext) {
          return GestureDetector(
            onTap: toastMessageBar.onTap != null
                ? () => toastMessageBar.onTap!(toastMessageBar)
                : null,
            child: toastMessageBar,
          );
        }),
        _onStatusChanged = toastMessageBar.onStatusChanged,
        super(settings: settings) {
    _configureAlignment(toastMessageBar.toastMessageBarPosition);
  }

  void _configureAlignment(ToastMessageBarPosition toastMessageBarPosition) {
    switch (toastMessageBar.toastMessageBarPosition) {
      case ToastMessageBarPosition.top:
        {
          _initialAlignment = const Alignment(-1.0, -2.0);
          _endAlignment = toastMessageBar.endOffset != null
              ? const Alignment(-1.0, -1.0) +
                  Alignment(toastMessageBar.endOffset!.dx,
                      toastMessageBar.endOffset!.dy)
              : const Alignment(-1.0, -1.0);
          break;
        }
      case ToastMessageBarPosition.bottom:
        {
          _initialAlignment = const Alignment(-1.0, 2.0);
          _endAlignment = toastMessageBar.endOffset != null
              ? const Alignment(-1.0, 1.0) +
                  Alignment(toastMessageBar.endOffset!.dx,
                      toastMessageBar.endOffset!.dy)
              : const Alignment(-1.0, 1.0);
          break;
        }
    }
  }

  Future<T> get completed => _transitionCompleter.future;
  bool get opaque => false;

  @override
  Future<RoutePopDisposition> willPop() {
    if (!toastMessageBar.isDismissible) {
      return Future.value(RoutePopDisposition.doNotPop);
    }

    return Future.value(RoutePopDisposition.pop);
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    final overlays = <OverlayEntry>[];

    if (toastMessageBar.blockBackgroundInteraction) {
      overlays.add(
        OverlayEntry(
            builder: (BuildContext context) {
              return Listener(
                onPointerDown: toastMessageBar.isDismissible
                    ? (_) => toastMessageBar.dismiss()
                    : null,
                child: _createBackgroundOverlay(),
              );
            },
            maintainState: false,
            opaque: opaque),
      );
    }

    overlays.add(
      OverlayEntry(
          builder: (BuildContext context) {
            final Widget annotatedChild = Semantics(
              focused: false,
              container: true,
              explicitChildNodes: true,
              child: AlignTransition(
                alignment: _animation!,
                child: toastMessageBar.isDismissible
                    ? _getDismissibletoastMessageBar(_builder)
                    : _gettoastMessageBar(),
              ),
            );
            return annotatedChild;
          },
          maintainState: false,
          opaque: opaque),
    );

    return overlays;
  }

  Widget _createBackgroundOverlay() {
    if (_filterBlurAnimation != null && _filterColorAnimation != null) {
      return AnimatedBuilder(
        animation: _filterBlurAnimation!,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _filterBlurAnimation!.value,
                sigmaY: _filterBlurAnimation!.value),
            child: Container(
              constraints: const BoxConstraints.expand(),
              color: _filterColorAnimation!.value,
            ),
          );
        },
      );
    }

    if (_filterBlurAnimation != null) {
      return AnimatedBuilder(
        animation: _filterBlurAnimation!,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _filterBlurAnimation!.value,
                sigmaY: _filterBlurAnimation!.value),
            child: Container(
              constraints: const BoxConstraints.expand(),
              color: Colors.transparent,
            ),
          );
        },
      );
    }

    if (_filterColorAnimation != null) {
      AnimatedBuilder(
        animation: _filterColorAnimation!,
        builder: (context, child) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: _filterColorAnimation!.value,
          );
        },
      );
    }

    return Container(
      constraints: const BoxConstraints.expand(),
      color: Colors.transparent,
    );
  }

  String dismissibleKeyGen = '';

  Widget _getDismissibletoastMessageBar(Widget child) {
    return Dismissible(
      direction: _getDismissDirection(),
      resizeDuration: null,
      confirmDismiss: (_) {
        if (currentStatus == ToastMessageBarStatus.isAppearing ||
            currentStatus == ToastMessageBarStatus.isHiding) {
          return Future.value(false);
        }
        return Future.value(true);
      },
      key: Key(dismissibleKeyGen),
      onDismissed: (_) {
        dismissibleKeyGen += '1';
        _cancelTimer();
        _wasDismissedBySwipe = true;

        if (isCurrent) {
          navigator!.pop();
        } else {
          navigator!.removeRoute(this);
        }
      },
      child: _gettoastMessageBar(),
    );
  }

  DismissDirection _getDismissDirection() {
    if (toastMessageBar.toastMessageBarDirection ==
        ToastMessageBarDismissDirection.horizontal) {
      return DismissDirection.horizontal;
    } else {
      if (toastMessageBar.toastMessageBarPosition ==
          ToastMessageBarPosition.top) {
        return DismissDirection.up;
      } else {
        return DismissDirection.down;
      }
    }
  }

  Widget _gettoastMessageBar() {
    return Container(
      margin: toastMessageBar.margin,
      child: _builder,
    );
  }

  @override
  bool get finishedWhenPopped =>
      _controller!.status == AnimationStatus.dismissed;

  Animation<Alignment>? get animation => _animation;
  Animation<Alignment>? _animation;

  @protected
  AnimationController? get controller => _controller;
  AnimationController? _controller;

  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(toastMessageBar.animationDuration >= Duration.zero);
    return AnimationController(
      duration: toastMessageBar.animationDuration,
      debugLabel: debugLabel,
      vsync: navigator!,
    );
  }

  Animation<Alignment> createAnimation() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(_controller != null);
    return AlignmentTween(begin: _initialAlignment, end: _endAlignment).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: toastMessageBar.forwardAnimationCurve,
        reverseCurve: toastMessageBar.reverseAnimationCurve,
      ),
    );
  }

  Animation<double>? createBlurFilterAnimation() {
    if (toastMessageBar.routeBlur == null) return null;

    return Tween(begin: 0.0, end: toastMessageBar.routeBlur).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  Animation<Color?>? createColorFilterAnimation() {
    if (toastMessageBar.routeColor == null) return null;

    return ColorTween(
            begin: Colors.transparent, end: toastMessageBar.routeColor)
        .animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        currentStatus = ToastMessageBarStatus.showing;
        if (_onStatusChanged != null) _onStatusChanged!(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = opaque;

        break;
      case AnimationStatus.forward:
        currentStatus = ToastMessageBarStatus.isAppearing;
        if (_onStatusChanged != null) _onStatusChanged!(currentStatus);
        break;
      case AnimationStatus.reverse:
        currentStatus = ToastMessageBarStatus.isHiding;
        if (_onStatusChanged != null) _onStatusChanged!(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        assert(!overlayEntries.first.opaque);

        currentStatus = ToastMessageBarStatus.dismissed;
        if (_onStatusChanged != null) _onStatusChanged!(currentStatus);

        if (!isCurrent) {
          navigator!.finalizeRoute(this);
          if (overlayEntries.isNotEmpty) {
            overlayEntries.clear();
          }
          assert(overlayEntries.isEmpty);
        }
        break;
    }
    changedInternalState();
  }

  @override
  void install() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot install a $runtimeType after disposing it.');
    _controller = createAnimationController();
    assert(_controller != null,
        '$runtimeType.createAnimationController() returned null.');
    _filterBlurAnimation = createBlurFilterAnimation();
    _filterColorAnimation = createColorFilterAnimation();
    _animation = createAnimation();
    assert(_animation != null, '$runtimeType.createAnimation() returned null.');
    super.install();
  }

  @override
  TickerFuture didPush() {
    assert(_controller != null,
        '$runtimeType.didPush called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _animation!.addStatusListener(_handleStatusChanged);
    _configureTimer();
    super.didPush();
    return _controller!.forward();
  }

  @override
  void didReplace(Route<dynamic>? oldRoute) {
    assert(_controller != null,
        '$runtimeType.didReplace called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    if (oldRoute is ToastMessageBarRoute) {
      _controller!.value = oldRoute._controller!.value;
    }
    _animation!.addStatusListener(_handleStatusChanged);
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T? result) {
    assert(_controller != null,
        '$runtimeType.didPop called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');

    _result = result;
    _cancelTimer();

    if (_wasDismissedBySwipe) {
      Timer(const Duration(milliseconds: 200), () {
        _controller!.reset();
      });

      _wasDismissedBySwipe = false;
    } else {
      _controller!.reverse();
    }

    return super.didPop(result);
  }

  void _configureTimer() {
    if (toastMessageBar.duration != null) {
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel();
      }
      _timer = Timer(toastMessageBar.duration!, () {
        if (isCurrent) {
          navigator!.pop();
        } else if (isActive) {
          navigator!.removeRoute(this);
        }
      });
    } else {
      if (_timer != null) {
        _timer!.cancel();
      }
    }
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  bool canTransitionTo(ToastMessageBarRoute<dynamic> nextRoute) => true;

  bool canTransitionFrom(ToastMessageBarRoute<dynamic> previousRoute) => true;

  @override
  void dispose() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot dispose a $runtimeType twice.');
    _controller?.dispose();
    _transitionCompleter.complete(_result);
    super.dispose();
  }

  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

ToastMessageBarRoute showToastMessageBar<T>(
    {required BuildContext context, required ToastMessageBar toastMessageBar}) {
  return ToastMessageBarRoute<T>(
    toastMessageBar: toastMessageBar,
    settings: const RouteSettings(name: toastMessageBarRouteName),
  );
}
