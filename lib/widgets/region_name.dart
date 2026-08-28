import 'package:flutter/material.dart';

import '../app_deps.dart';

/// Resolves a 시군구 code to its display name once per code (the Future is
/// cached in state so parent rebuilds do not restart the lookup).
class RegionName extends StatefulWidget {
  const RegionName({super.key, required this.code, required this.builder});

  final String code;
  final Widget Function(BuildContext context, String name) builder;

  @override
  State<RegionName> createState() => _RegionNameState();
}

class _RegionNameState extends State<RegionName> {
  Future<String>? _future;
  String? _forCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensure();
  }

  @override
  void didUpdateWidget(RegionName oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensure();
  }

  void _ensure() {
    if (_forCode == widget.code) return;
    _forCode = widget.code;
    _future = AppDeps.of(context).regions.nameOf(widget.code);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) => widget.builder(context, snap.data ?? ''),
    );
  }
}
