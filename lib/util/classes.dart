// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:after_layout/after_layout.dart';

/// Wrapper for stateful functionality to provide onInit calls in stateles widget
class StatefulWrapper extends StatefulWidget {
  final Function? onInit;
  final Function? didUpdateWidget;
  final Function? deactivate;
  final Function? dispose;
  final Function? afterFirstLayout;
  final Widget child;
  const StatefulWrapper(
      {this.onInit,
      this.afterFirstLayout,
      required this.child,
      this.didUpdateWidget,
      this.deactivate,
      this.dispose});
  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<StatefulWrapper> with AfterLayoutMixin<StatefulWrapper> {
  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit!();
    }
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (widget.afterFirstLayout != null) {
      widget.afterFirstLayout!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    if (widget.didUpdateWidget != null) {
      widget.didUpdateWidget!(oldWidget);
    }
    super.didUpdateWidget(oldWidget as StatefulWrapper);
  }

  @override
  void deactivate() {
    if (widget.deactivate != null) {
      widget.deactivate!();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose!();
    }
    super.dispose();
  }
}
