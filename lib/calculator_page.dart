import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator.dart';

/// 计算器界面。
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final Calculator _calculator = Calculator();

  // iOS 计算器的经典配色
  static const Color _numberBackground = Color(0xFF333333);
  static const Color _functionBackground = Color(0xFFA5A5A5);
  static const Color _operatorBackground = Color(0xFFFF9F0A);
  static const Color _numberForeground = Color(0xFFFFFFFF);
  static const Color _functionForeground = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildDisplay(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    final pending = _calculator.pendingOperation;
    return Expanded(
      flex: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (pending != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  pending.symbol,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _calculator.display,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Expanded(
      flex: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        child: Column(
          children: [
            _row([
              _function(_calculator.clearLabel, () => _safe(_calculator.clear)),
              _function('+/−', () => _safe(_calculator.toggleSign)),
              _function('%', () => _safe(_calculator.percent)),
              _operator('÷',
                  () => _safe(() => _calculator.setOperation(Operation.divide))),
            ]),
            _row([
              _number('7', () => _digit('7')),
              _number('8', () => _digit('8')),
              _number('9', () => _digit('9')),
              _operator('×',
                  () => _safe(() => _calculator.setOperation(Operation.multiply))),
            ]),
            _row([
              _number('4', () => _digit('4')),
              _number('5', () => _digit('5')),
              _number('6', () => _digit('6')),
              _operator('−',
                  () => _safe(() => _calculator.setOperation(Operation.subtract))),
            ]),
            _row([
              _number('1', () => _digit('1')),
              _number('2', () => _digit('2')),
              _number('3', () => _digit('3')),
              _operator('+',
                  () => _safe(() => _calculator.setOperation(Operation.add))),
            ]),
            _row([
              _number('0', () => _digit('0'), flex: 2),
              _number('.', () => _safe(_calculator.inputDecimalPoint)),
              _operator('=', () => _safe(_calculator.equals)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _number(String label, VoidCallback onTap, {int flex = 1}) {
    return _Key(
      label: label,
      onTap: onTap,
      background: _numberBackground,
      foreground: _numberForeground,
      flex: flex,
    );
  }

  Widget _function(String label, VoidCallback onTap) {
    return _Key(
      label: label,
      onTap: onTap,
      background: _functionBackground,
      foreground: _functionForeground,
      fontSize: 32,
    );
  }

  Widget _operator(String label, VoidCallback onTap) {
    return _Key(
      label: label,
      onTap: onTap,
      background: _operatorBackground,
      foreground: _numberForeground,
      fontSize: 38,
    );
  }

  void _digit(String digit) => _safe(() => _calculator.inputDigit(digit));

  /// 统一包一层：除以零时引擎会抛异常，但界面要正常切成「错误」状态而不是崩掉。
  void _safe(VoidCallback action) {
    try {
      action();
    } on DivisionByZeroException {
      // 引擎内部已经设置了错误状态，这里只需要刷新界面
    }
    setState(() {});
  }
}

/// 单个按键，带按压缩放反馈与触感反馈。
class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.fontSize = 34,
    this.flex = 1,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final double fontSize;
  final int flex;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              decoration: BoxDecoration(
                color: widget.background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.foreground,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
