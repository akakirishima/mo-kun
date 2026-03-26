import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/models/diary_book.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_cover_page.dart';
import 'package:gdgoc_2026_prototype/features/diary/presentation/widgets/diary_day_page.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

const _pageFrameCornerRadius = 10.0;
const _pageBackdropCornerRadius = 8.0;
const _pageSpineCornerRadius = 4.0;
const _horizontalDragSlop = 12.0;
const _pageTurnThreshold = 0.33;
const _pageTurnFlingVelocity = 850.0;
const _fullTurnDuration = Duration(milliseconds: 420);
const _snapBackDuration = Duration(milliseconds: 220);
const _coverTeaserInitialDelay = Duration(milliseconds: 900);
const _coverTeaserForwardDuration = Duration(milliseconds: 700);
const _coverTeaserReverseDuration = Duration(milliseconds: 550);
const _coverTeaserRepeatDelay = Duration(milliseconds: 3200);
const _coverTeaserMaxProgress = 0.25;

enum _ViewportPhase {
  idle,
  capturing,
  animating,
  chainedAnimating,
  teaserCapturing,
  teasing,
}

enum _DiaryTurnDirection { next, previous }

class DiaryBookViewport extends StatefulWidget {
  const DiaryBookViewport({
    super.key,
    required this.book,
    required this.currentPageIndex,
    required this.onPageChanged,
    required this.onOpenSelector,
    required this.onOpenEntryForDay,
    required this.onShowPreviousMonth,
    required this.onShowNextMonth,
    required this.dayPageBottomClearance,
    this.enableCoverTurnTeaser = true,
    this.isVisible = true,
  });

  final DiaryMonthBook book;
  final int currentPageIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenSelector;
  final ValueChanged<int> onOpenEntryForDay;
  final VoidCallback onShowPreviousMonth;
  final VoidCallback onShowNextMonth;
  final double dayPageBottomClearance;
  final bool enableCoverTurnTeaser;
  final bool isVisible;

  @override
  State<DiaryBookViewport> createState() => _DiaryBookViewportState();
}

class _DiaryBookViewportState extends State<DiaryBookViewport>
    with TickerProviderStateMixin {
  final GlobalKey _currentCaptureKey = GlobalKey(
    debugLabel: 'diary-current-page-capture',
  );
  final GlobalKey _targetCaptureKey = GlobalKey(
    debugLabel: 'diary-target-page-capture',
  );

  late final AnimationController _turnController;
  late final AnimationController _teaserController;
  late int _displayedPageIndex;

  _ViewportPhase _phase = _ViewportPhase.idle;
  _DiaryTurnDirection? _turnDirection;
  int? _stepTargetIndex;
  int? _queuedNavigationTarget;

  double _viewportWidth = 1.0;
  double _dragExtent = 0.0;
  double _crossDragExtent = 0.0;
  double _dragProgress = 0.0;
  bool _gestureTracking = false;
  bool _gestureAccepted = false;
  bool _releasePending = false;
  double _releaseVelocity = 0.0;
  bool _commitTurn = false;
  bool _notifyParentOnCommit = false;
  int _captureGeneration = 0;
  int _teaserGeneration = 0;
  double _viewportHeight = 0.0;
  Size? _teaserCaptureSize;
  Timer? _teaserTimer;

  ui.Image? _currentImage;
  ui.Image? _targetImage;
  ui.Image? _teaserCurrentImage;
  ui.Image? _teaserTargetImage;

  String get _monthNumber {
    final match = RegExp(r'(\d+)月').firstMatch(widget.book.monthLabel);
    return match?.group(1) ?? '3';
  }

  @override
  void initState() {
    super.initState();
    _displayedPageIndex = _clampPageIndex(widget.currentPageIndex);
    _turnController = AnimationController(
      vsync: this,
      duration: _fullTurnDuration,
    )..addStatusListener(_handleTurnStatus);
    _teaserController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isVisible) {
        _maybeScheduleCoverTeaser(initial: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DiaryBookViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetPageIndex = _clampPageIndex(widget.currentPageIndex);
    final monthChanged =
        widget.book.calendar.monthStart != oldWidget.book.calendar.monthStart;
    final pageCountChanged = widget.book.pageCount != oldWidget.book.pageCount;
    final bookChanged = widget.book != oldWidget.book;
    final becameVisible = !oldWidget.isVisible && widget.isVisible;
    final becameHidden = oldWidget.isVisible && !widget.isVisible;

    if (becameHidden) {
      _cancelCoverTeaser();
    }

    if (monthChanged || pageCountChanged) {
      _invalidateTeaserImages();
      _resetToPage(targetPageIndex);
      return;
    }

    if (bookChanged) {
      _invalidateTeaserImages();
    }

    if (becameVisible) {
      _cancelCoverTeaser();
      _maybeScheduleCoverTeaser(initial: true);
    }

    if (targetPageIndex == _displayedPageIndex &&
        _queuedNavigationTarget == null &&
        !_isTurning &&
        !_isTeasing) {
      _maybeScheduleCoverTeaser(initial: bookChanged);
      return;
    }

    if (targetPageIndex != oldWidget.currentPageIndex) {
      _queueExternalNavigation(targetPageIndex);
    }
  }

  @override
  void dispose() {
    _teaserTimer?.cancel();
    _turnController
      ..removeStatusListener(_handleTurnStatus)
      ..dispose();
    _teaserController.dispose();
    _disposeCapturedImages();
    _disposeTeaserImages();
    super.dispose();
  }

  bool get _isTurning =>
      _phase == _ViewportPhase.capturing ||
      _phase == _ViewportPhase.animating ||
      _phase == _ViewportPhase.chainedAnimating;

  bool get _isTeasing =>
      _phase == _ViewportPhase.teaserCapturing ||
      _phase == _ViewportPhase.teasing;

  bool get _canRunCoverTeaser =>
      widget.enableCoverTurnTeaser &&
      widget.isVisible &&
      _displayedPageIndex == 0 &&
      widget.book.pageCount > 1 &&
      _queuedNavigationTarget == null &&
      !_gestureTracking &&
      !_gestureAccepted &&
      !_isTurning &&
      !_isTeasing;

  int _clampPageIndex(int index) {
    return index.clamp(0, widget.book.pageCount - 1).toInt();
  }

  int? _adjacentIndexFor(int baseIndex, _DiaryTurnDirection direction) {
    final candidate = switch (direction) {
      _DiaryTurnDirection.next => baseIndex + 1,
      _DiaryTurnDirection.previous => baseIndex - 1,
    };
    if (candidate < 0 || candidate >= widget.book.pageCount) {
      return null;
    }
    return candidate;
  }

  void _handleOpenSelector() {
    _cancelCoverTeaser();
    widget.onOpenSelector();
  }

  void _handleOpenEntryForDay(int dayNumber) {
    _cancelCoverTeaser();
    widget.onOpenEntryForDay(dayNumber);
  }

  void _handleShowPreviousMonth() {
    _cancelCoverTeaser(invalidateImages: true);
    widget.onShowPreviousMonth();
  }

  void _handleShowNextMonth() {
    _cancelCoverTeaser(invalidateImages: true);
    widget.onShowNextMonth();
  }

  Widget _buildPageChild(int index) {
    final entry = widget.book.entryAt(index);
    if (entry == null) {
      return DiaryCoverPage(
        book: widget.book,
        onSelectorTap: _handleOpenSelector,
        onDayTap: _handleOpenEntryForDay,
        onPreviousMonthTap: _handleShowPreviousMonth,
        onNextMonthTap: _handleShowNextMonth,
      );
    }
    return DiaryDayPage(
      entry: entry,
      monthNumber: _monthNumber,
      dateLabel: '$_monthNumber月${entry.dayNumber}日',
      onDateTap: widget.onOpenSelector,
      bottomClearance: widget.dayPageBottomClearance,
    );
  }

  Widget _buildPageFrame(
    BuildContext context,
    Widget child, {
    bool withShadow = true,
  }) {
    final palette = AppearanceScope.paletteOf(context).diary;
    const borderRadius = BorderRadius.all(
      Radius.circular(_pageFrameCornerRadius),
    );

    final clippedChild = ClipRRect(borderRadius: borderRadius, child: child);
    if (!withShadow) {
      return clippedChild;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: palette.pageShadow.withValues(alpha: 0.16),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: clippedChild,
    );
  }

  Widget _buildCapturePage({
    required BuildContext context,
    required GlobalKey repaintKey,
    required int index,
  }) {
    return RepaintBoundary(
      key: repaintKey,
      child: _buildPageFrame(
        context,
        _buildPageChild(index),
        withShadow: false,
      ),
    );
  }

  PageTurnStyle _pageTurnStyle(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    return PageTurnStyle(
      backgroundColor: palette.paperFill,
      shadowColor: palette.pageShadow,
      shadowOpacity: 0.64,
      shadowBlurRadius: 20,
      segments: 110,
      curlIntensity: 1.0,
    );
  }

  void _disposeTeaserImages() {
    _teaserCurrentImage?.dispose();
    _teaserTargetImage?.dispose();
    _teaserCurrentImage = null;
    _teaserTargetImage = null;
  }

  void _invalidateTeaserImages() {
    _teaserGeneration += 1;
    _teaserCaptureSize = null;
    _disposeTeaserImages();
  }

  void _cancelCoverTeaser({bool invalidateImages = false}) {
    _teaserTimer?.cancel();
    _teaserTimer = null;
    _teaserGeneration += 1;
    _teaserController
      ..stop()
      ..value = 0.0;
    if (invalidateImages) {
      _teaserCaptureSize = null;
      _disposeTeaserImages();
    }
    if (_isTeasing && mounted) {
      setState(() {
        _phase = _ViewportPhase.idle;
      });
    }
  }

  void _maybeScheduleCoverTeaser({required bool initial}) {
    if (!_canRunCoverTeaser || !mounted || _teaserTimer != null) {
      return;
    }

    _teaserTimer = Timer(
      initial ? _coverTeaserInitialDelay : _coverTeaserRepeatDelay,
      () {
        _teaserTimer = null;
        _startCoverTeaser();
      },
    );
  }

  Future<void> _startCoverTeaser() async {
    if (!_canRunCoverTeaser || !mounted) {
      return;
    }

    final firstEntryIndex = _adjacentIndexFor(0, _DiaryTurnDirection.next);
    if (firstEntryIndex == null) {
      return;
    }

    final captureSize = Size(_viewportWidth, _viewportHeight);
    final hasReusableImages =
        _teaserCurrentImage != null &&
        _teaserTargetImage != null &&
        _teaserCaptureSize == captureSize;

    final teaserGeneration = _teaserGeneration + 1;
    _teaserGeneration = teaserGeneration;
    _teaserController.value = 0.0;

    if (!hasReusableImages) {
      setState(() {
        _phase = _ViewportPhase.teaserCapturing;
      });
      await _captureTeaserImages(
        teaserGeneration: teaserGeneration,
        stepTargetIndex: firstEntryIndex,
        captureSize: captureSize,
      );
      return;
    }

    await _runCoverTeaserAnimation(teaserGeneration);
  }

  Future<void> _captureTeaserImages({
    required int teaserGeneration,
    required int stepTargetIndex,
    required Size captureSize,
  }) async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted || teaserGeneration != _teaserGeneration) {
      return;
    }

    final currentBoundary =
        _currentCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final targetBoundary =
        _targetCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (currentBoundary == null || targetBoundary == null) {
      _handleTeaserCaptureFailure(teaserGeneration);
      return;
    }

    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final currentImage = await currentBoundary.toImage(pixelRatio: pixelRatio);
    final targetImage = await targetBoundary.toImage(pixelRatio: pixelRatio);

    if (!mounted || teaserGeneration != _teaserGeneration) {
      currentImage.dispose();
      targetImage.dispose();
      return;
    }

    _disposeTeaserImages();
    _teaserCurrentImage = currentImage;
    _teaserTargetImage = targetImage;
    _teaserCaptureSize = captureSize;

    if (!mounted ||
        teaserGeneration != _teaserGeneration ||
        _displayedPageIndex != 0 ||
        stepTargetIndex != 1) {
      return;
    }

    await _runCoverTeaserAnimation(teaserGeneration);
  }

  Future<void> _runCoverTeaserAnimation(int teaserGeneration) async {
    if (!mounted ||
        teaserGeneration != _teaserGeneration ||
        _displayedPageIndex != 0 ||
        _teaserCurrentImage == null ||
        _teaserTargetImage == null) {
      return;
    }

    setState(() {
      _phase = _ViewportPhase.teasing;
    });

    try {
      await _teaserController.animateTo(
        _coverTeaserMaxProgress,
        duration: _coverTeaserForwardDuration,
        curve: Curves.easeOutCubic,
      );
      if (!mounted || teaserGeneration != _teaserGeneration) {
        return;
      }
      await _teaserController.animateBack(
        0.0,
        duration: _coverTeaserReverseDuration,
        curve: Curves.easeOutQuad,
      );
    } on TickerCanceled {
      return;
    }

    if (!mounted || teaserGeneration != _teaserGeneration) {
      return;
    }

    setState(() {
      _phase = _ViewportPhase.idle;
    });
    _maybeScheduleCoverTeaser(initial: false);
  }

  void _handleTeaserCaptureFailure(int teaserGeneration) {
    if (!mounted || teaserGeneration != _teaserGeneration) {
      return;
    }
    setState(() {
      _phase = _ViewportPhase.idle;
    });
    _maybeScheduleCoverTeaser(initial: false);
  }

  void _disposeCapturedImages() {
    _currentImage?.dispose();
    _targetImage?.dispose();
    _currentImage = null;
    _targetImage = null;
  }

  void _clearTurnState({bool clearQueuedNavigation = false}) {
    _captureGeneration += 1;
    _turnDirection = null;
    _stepTargetIndex = null;
    _dragExtent = 0.0;
    _crossDragExtent = 0.0;
    _dragProgress = 0.0;
    _gestureTracking = false;
    _gestureAccepted = false;
    _releasePending = false;
    _releaseVelocity = 0.0;
    _commitTurn = false;
    _notifyParentOnCommit = false;
    _turnController
      ..stop()
      ..value = 0.0;
    _disposeCapturedImages();
    if (clearQueuedNavigation) {
      _queuedNavigationTarget = null;
    }
  }

  void _resetToPage(int pageIndex) {
    _cancelCoverTeaser(invalidateImages: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _displayedPageIndex = pageIndex;
      _phase = _ViewportPhase.idle;
      _clearTurnState(clearQueuedNavigation: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeScheduleCoverTeaser(initial: true);
      }
    });
  }

  void _queueExternalNavigation(int targetPageIndex) {
    _cancelCoverTeaser();
    final clampedTarget = _clampPageIndex(targetPageIndex);
    if (clampedTarget == _displayedPageIndex && !_isTurning) {
      if (_queuedNavigationTarget != null) {
        setState(() {
          _queuedNavigationTarget = null;
        });
      }
      return;
    }

    setState(() {
      _queuedNavigationTarget = clampedTarget;
    });
    if (!_isTurning) {
      _startNextQueuedTurn();
    }
  }

  void _startNextQueuedTurn() {
    final targetPageIndex = _queuedNavigationTarget;
    if (targetPageIndex == null || targetPageIndex == _displayedPageIndex) {
      setState(() {
        _phase = _ViewportPhase.idle;
        _queuedNavigationTarget = null;
      });
      return;
    }

    final direction = targetPageIndex > _displayedPageIndex
        ? _DiaryTurnDirection.next
        : _DiaryTurnDirection.previous;
    final stepTargetIndex = _adjacentIndexFor(_displayedPageIndex, direction);
    if (stepTargetIndex == null) {
      _resetToPage(_displayedPageIndex);
      return;
    }

    _prepareTurn(
      direction: direction,
      stepTargetIndex: stepTargetIndex,
      notifyParentOnCommit: false,
      queuedTarget: targetPageIndex,
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _cancelCoverTeaser();
    if (_isTurning) {
      return;
    }
    _gestureTracking = true;
    _gestureAccepted = false;
    _dragExtent = 0.0;
    _crossDragExtent = 0.0;
    _dragProgress = 0.0;
    _releasePending = false;
    _releaseVelocity = 0.0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_gestureTracking) {
      return;
    }

    _dragExtent += details.delta.dx;
    _crossDragExtent += details.delta.dy;

    if (!_gestureAccepted) {
      if (_dragExtent.abs() <= _horizontalDragSlop &&
          _crossDragExtent.abs() <= _horizontalDragSlop) {
        return;
      }
      if (_dragExtent.abs() <= _crossDragExtent.abs()) {
        _clearTurnState(clearQueuedNavigation: false);
        setState(() {
          _phase = _ViewportPhase.idle;
        });
        return;
      }

      final direction = _dragExtent < 0
          ? _DiaryTurnDirection.next
          : _DiaryTurnDirection.previous;
      final stepTargetIndex = _adjacentIndexFor(_displayedPageIndex, direction);
      if (stepTargetIndex == null) {
        _clearTurnState(clearQueuedNavigation: false);
        setState(() {
          _phase = _ViewportPhase.idle;
        });
        return;
      }

      _gestureAccepted = true;
      _prepareTurn(
        direction: direction,
        stepTargetIndex: stepTargetIndex,
        notifyParentOnCommit: true,
      );
    }

    if (_turnDirection == null) {
      return;
    }

    _dragProgress = _directionalProgress();
    if (_phase == _ViewportPhase.animating &&
        !_turnController.isAnimating &&
        _currentImage != null &&
        _targetImage != null) {
      _turnController.value = _dragProgress;
      setState(() {});
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!_gestureTracking) {
      return;
    }
    _gestureTracking = false;

    if (!_gestureAccepted) {
      _clearTurnState(clearQueuedNavigation: false);
      setState(() {
        _phase = _ViewportPhase.idle;
      });
      return;
    }

    _releasePending = true;
    _releaseVelocity = details.primaryVelocity ?? 0.0;
    if (_phase == _ViewportPhase.animating &&
        !_turnController.isAnimating &&
        _currentImage != null &&
        _targetImage != null) {
      _settleGestureTurn();
    }
  }

  void _handleHorizontalDragCancel() {
    if (!_gestureTracking && !_gestureAccepted) {
      return;
    }
    _gestureTracking = false;

    if (!_gestureAccepted) {
      _clearTurnState(clearQueuedNavigation: false);
      setState(() {
        _phase = _ViewportPhase.idle;
      });
      return;
    }

    _releasePending = true;
    _releaseVelocity = 0.0;
    if (_phase == _ViewportPhase.animating &&
        !_turnController.isAnimating &&
        _currentImage != null &&
        _targetImage != null) {
      _settleGestureTurn();
    }
  }

  double _directionalProgress() {
    final direction = _turnDirection;
    if (direction == null || _viewportWidth <= 0) {
      return 0.0;
    }

    final directionalExtent = switch (direction) {
      _DiaryTurnDirection.next => math.max(-_dragExtent, 0.0),
      _DiaryTurnDirection.previous => math.max(_dragExtent, 0.0),
    };
    return (directionalExtent / _viewportWidth).clamp(0.0, 1.0);
  }

  void _prepareTurn({
    required _DiaryTurnDirection direction,
    required int stepTargetIndex,
    required bool notifyParentOnCommit,
    int? queuedTarget,
  }) {
    if (!mounted) {
      return;
    }

    _turnController
      ..stop()
      ..value = 0.0;
    _disposeCapturedImages();
    final captureGeneration = _captureGeneration + 1;
    _captureGeneration = captureGeneration;

    setState(() {
      _turnDirection = direction;
      _stepTargetIndex = stepTargetIndex;
      _notifyParentOnCommit = notifyParentOnCommit;
      _queuedNavigationTarget = queuedTarget ?? _queuedNavigationTarget;
      _commitTurn = false;
      _phase = _ViewportPhase.capturing;
    });

    _captureTurnImages(captureGeneration);
  }

  Future<void> _captureTurnImages(int captureGeneration) async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted || captureGeneration != _captureGeneration) {
      return;
    }

    final currentBoundary =
        _currentCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final targetBoundary =
        _targetCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (currentBoundary == null || targetBoundary == null) {
      _handleCaptureFailure();
      return;
    }

    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final currentImage = await currentBoundary.toImage(pixelRatio: pixelRatio);
    final targetImage = await targetBoundary.toImage(pixelRatio: pixelRatio);

    if (!mounted || captureGeneration != _captureGeneration) {
      currentImage.dispose();
      targetImage.dispose();
      return;
    }

    _disposeCapturedImages();
    _currentImage = currentImage;
    _targetImage = targetImage;

    final chainedAnimation =
        _queuedNavigationTarget != null &&
        _queuedNavigationTarget != _stepTargetIndex &&
        !_notifyParentOnCommit;

    setState(() {
      _phase = chainedAnimation
          ? _ViewportPhase.chainedAnimating
          : _ViewportPhase.animating;
    });

    if (_gestureAccepted) {
      _turnController.value = _dragProgress;
      if (_releasePending) {
        _settleGestureTurn();
      }
      return;
    }

    _runProgrammaticTurn();
  }

  void _handleCaptureFailure() {
    if (!mounted) {
      return;
    }

    final fallbackPage = _notifyParentOnCommit
        ? _displayedPageIndex
        : (_queuedNavigationTarget ?? _displayedPageIndex);
    setState(() {
      _displayedPageIndex = _clampPageIndex(fallbackPage);
      _phase = _ViewportPhase.idle;
      _clearTurnState(clearQueuedNavigation: !_notifyParentOnCommit);
    });
  }

  void _runProgrammaticTurn() {
    _commitTurn = true;
    _turnController.animateTo(
      1.0,
      duration: _fullTurnDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _settleGestureTurn() {
    _releasePending = false;
    final direction = _turnDirection;
    if (direction == null) {
      return;
    }

    final velocity = _releaseVelocity;
    final shouldCommit =
        _dragProgress >= _pageTurnThreshold ||
        (direction == _DiaryTurnDirection.next &&
            velocity <= -_pageTurnFlingVelocity) ||
        (direction == _DiaryTurnDirection.previous &&
            velocity >= _pageTurnFlingVelocity);

    final remaining = shouldCommit ? 1.0 - _dragProgress : _dragProgress;
    final baseDuration = shouldCommit ? _fullTurnDuration : _snapBackDuration;
    final duration = Duration(
      milliseconds: (baseDuration.inMilliseconds * remaining.clamp(0.2, 1.0))
          .round(),
    );

    _commitTurn = shouldCommit;
    if (shouldCommit) {
      _turnController.animateTo(
        1.0,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
      return;
    }

    _turnController.animateBack(
      0.0,
      duration: duration,
      curve: Curves.easeOutQuad,
    );
  }

  void _handleTurnStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _commitTurn) {
      _finalizeCommittedTurn();
      return;
    }
    if (status == AnimationStatus.dismissed && !_commitTurn) {
      _cancelTurn();
    }
  }

  void _finalizeCommittedTurn() {
    final committedPageIndex = _stepTargetIndex;
    if (committedPageIndex == null) {
      _cancelTurn();
      return;
    }

    final shouldNotifyParent = _notifyParentOnCommit;
    setState(() {
      _displayedPageIndex = committedPageIndex;
      _phase = _ViewportPhase.idle;
      _clearTurnState(clearQueuedNavigation: false);
    });

    if (shouldNotifyParent) {
      widget.onPageChanged(committedPageIndex);
    }

    if (_queuedNavigationTarget != null &&
        _queuedNavigationTarget != committedPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startNextQueuedTurn();
        }
      });
      return;
    }

    if (_queuedNavigationTarget == committedPageIndex) {
      setState(() {
        _queuedNavigationTarget = null;
      });
    }

    _maybeScheduleCoverTeaser(initial: true);
  }

  void _cancelTurn() {
    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _ViewportPhase.idle;
      _clearTurnState(clearQueuedNavigation: false);
    });
    _maybeScheduleCoverTeaser(initial: true);
  }

  Widget _buildAnimatingScene(BuildContext context) {
    final direction = _turnDirection;
    final stepTargetIndex = _stepTargetIndex;
    final currentImage = _currentImage;
    final targetImage = _targetImage;

    if (direction == null ||
        stepTargetIndex == null ||
        currentImage == null ||
        targetImage == null) {
      return _buildPageFrame(context, _buildPageChild(_displayedPageIndex));
    }

    final animatedImage = direction == _DiaryTurnDirection.next
        ? currentImage
        : targetImage;
    final animatedDirection = direction == _DiaryTurnDirection.next
        ? PageTurnDirection.forward
        : PageTurnDirection.backward;
    final baseLayer = direction == _DiaryTurnDirection.next
        ? _buildPageFrame(context, _buildPageChild(stepTargetIndex))
        : _buildPageFrame(context, _buildPageChild(_displayedPageIndex));

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: baseLayer),
        Positioned.fill(
          child: IgnorePointer(
            child: PageTurnAnimation(
              image: animatedImage,
              animation: _turnController,
              direction: animatedDirection,
              edge: PageTurnEdge.left,
              style: _pageTurnStyle(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeaserAnimatingScene(BuildContext context) {
    final currentImage = _teaserCurrentImage;
    final targetImage = _teaserTargetImage;
    if (currentImage == null || targetImage == null) {
      return _buildPageFrame(context, _buildPageChild(_displayedPageIndex));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: _buildPageFrame(context, _buildPageChild(1))),
        Positioned.fill(
          child: IgnorePointer(
            child: PageTurnAnimation(
              key: const ValueKey<String>('diary-cover-turn-teaser'),
              image: currentImage,
              animation: _teaserController,
              direction: PageTurnDirection.forward,
              edge: PageTurnEdge.left,
              style: _pageTurnStyle(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewportContent(BuildContext context) {
    switch (_phase) {
      case _ViewportPhase.idle:
        return _buildPageFrame(context, _buildPageChild(_displayedPageIndex));
      case _ViewportPhase.capturing:
        final stepTargetIndex = _stepTargetIndex;
        if (stepTargetIndex == null) {
          return _buildPageFrame(context, _buildPageChild(_displayedPageIndex));
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _buildCapturePage(
                context: context,
                repaintKey: _targetCaptureKey,
                index: stepTargetIndex,
              ),
            ),
            Positioned.fill(
              child: _buildCapturePage(
                context: context,
                repaintKey: _currentCaptureKey,
                index: _displayedPageIndex,
              ),
            ),
          ],
        );
      case _ViewportPhase.animating:
      case _ViewportPhase.chainedAnimating:
        return _buildAnimatingScene(context);
      case _ViewportPhase.teaserCapturing:
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _buildCapturePage(
                context: context,
                repaintKey: _targetCaptureKey,
                index: 1,
              ),
            ),
            Positioned.fill(
              child: _buildCapturePage(
                context: context,
                repaintKey: _currentCaptureKey,
                index: 0,
              ),
            ),
          ],
        );
      case _ViewportPhase.teasing:
        return _buildTeaserAnimatingScene(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final monthAccent = diaryMonthAccentColor(
      widget.book.calendar.monthStart.month,
    );
    final spineTint = Color.lerp(palette.paperEdge, monthAccent, 0.22)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportWidth = math.min(constraints.maxWidth, 640.0);
        _viewportHeight = constraints.maxHeight;

        return Center(
          child: SizedBox(
            key: const ValueKey<String>('diary-book-viewport'),
            width: _viewportWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _PageStackBackdrop(monthAccent: monthAccent),
                ),
                Positioned(
                  top: 6,
                  bottom: 6,
                  left: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _pageSpineCornerRadius,
                      ),
                      color: spineTint.withValues(alpha: 0.22),
                      border: Border.all(
                        color: spineTint.withValues(alpha: 0.36),
                        width: 1.4,
                      ),
                    ),
                    child: const SizedBox(width: 12),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey<String>('diary-book-page-view'),
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: _handleHorizontalDragStart,
                    onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                    onHorizontalDragCancel: _handleHorizontalDragCancel,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _turnController,
                        _teaserController,
                      ]),
                      builder: (context, child) {
                        return _buildViewportContent(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageStackBackdrop extends StatelessWidget {
  const _PageStackBackdrop({required this.monthAccent});

  final Color monthAccent;

  @override
  Widget build(BuildContext context) {
    final palette = AppearanceScope.paletteOf(context).diary;
    final frontFill = Color.lerp(palette.paperFill, monthAccent, 0.14)!;
    final backFill = Color.lerp(palette.paperFill, monthAccent, 0.09)!;
    final backdropEdge = Color.lerp(palette.paperEdge, monthAccent, 0.18)!;

    return Stack(
      children: [
        Positioned(
          left: 6,
          right: 3,
          top: 6,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: frontFill.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(_pageBackdropCornerRadius),
              border: Border.all(
                color: backdropEdge.withValues(alpha: 0.32),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.pageShadow.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 0,
          top: 12,
          bottom: -1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backFill.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(_pageBackdropCornerRadius),
              border: Border.all(
                color: backdropEdge.withValues(alpha: 0.24),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.pageShadow.withValues(alpha: 0.06),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
