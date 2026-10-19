/// 计算器引擎。
///
/// 纯 Dart 实现，不依赖 Flutter，因此可以直接用 `flutter test` 做单元测试。
/// UI 层的所有交互最终都归结为对本类若干方法的调用。
library;

/// 一次二元运算。
enum Operation {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Operation(this.symbol);

  /// 显示在界面上的符号。
  final String symbol;
}

/// 除数为零时抛出。UI 会把它转换成「错误」状态。
class DivisionByZeroException implements Exception {
  const DivisionByZeroException();

  @override
  String toString() => '不能除以零';
}

/// 计算器的全部状态与运算逻辑。
///
/// 状态机由四个字段描述：
/// - [_entry] 当前显示的数值（纯文本，不含千分位）
/// - [_entering] 用户是否正在输入新数字
/// - [_accumulator] 待运算的左操作数
/// - [_pending] 待完成的运算
class Calculator {
  /// 输入的数字最多几位。
  static const int maxDigits = 12;

  String _entry = '0';
  double? _accumulator;
  Operation? _pending;
  bool _entering = false;
  bool _justEvaluated = false;
  bool _hasError = false;

  /// 最近一次参与运算的右操作数，用于「连按等号」。
  double? _lastOperand;
  /// 连按等号时重复使用的运算。
  Operation? _repeatOperation;
  double? _repeatOperand;

  /// 屏幕上应当显示的文本。
  String get display => _hasError ? '错误' : _format(_entry);

  /// 清除键的当前文案：正在输入数字时是 `C`（只清当前项），否则是 `AC`（全部重置）。
  String get clearLabel => (_entering && _entry != '0') ? 'C' : 'AC';

  /// 等待完成的运算，用于在显示屏上方做提示。
  Operation? get pendingOperation => _pending;

  /// 是否处于错误状态。
  bool get hasError => _hasError;

  /// 输入一个数字键（0-9）。
  void inputDigit(String digit) {
    _recoverFromError();
    if (_justEvaluated) {
      // 等号之后直接输入数字 = 开始一次全新的计算
      _reset();
    }
    if (!_entering) {
      _entry = digit;
      _entering = true;
      return;
    }
    if (_entry == '0') {
      _entry = digit;
      return;
    }
    if (_entry == '-0') {
      _entry = '-$digit';
      return;
    }
    if (_digitCount(_entry) >= maxDigits) return;
    final candidate = '$_entry$digit';
    final parsed = double.tryParse(candidate);
    if (parsed == null || parsed.isInfinite) return; // 超出可表示范围，忽略这次输入
    _entry = candidate;
  }

  /// 输入小数点。
  void inputDecimalPoint() {
    _recoverFromError();
    if (_justEvaluated) {
      _reset();
      _entry = '0.';
      _entering = true;
      return;
    }
    if (!_entering) {
      _entry = '0.';
      _entering = true;
      return;
    }
    if (_entry.contains('.')) return;
    _entry = '$_entry.';
  }

  /// 正负号切换。
  void toggleSign() {
    _recoverFromError();
    if (_entry == '0') return;
    if (_entry.startsWith('-')) {
      _entry = _entry.substring(1);
    } else {
      _entry = '-$_entry';
    }
    // 没有在输入新数字时，屏幕显示的是中间结果，需要同步改掉累加器。
    if (!_entering && _accumulator != null) {
      _accumulator = _value;
    }
  }

  /// 百分比。
  ///
  /// 存在加/减的待完成运算时，按 iOS 的行为取「累加器 × 当前值 ÷ 100」。
  void percent() {
    _recoverFromError();
    final current = _value;
    final double result;
    if (_pending != null &&
        (_pending == Operation.add || _pending == Operation.subtract)) {
      result = (_accumulator ?? 0) * current / 100;
    } else {
      result = current / 100;
    }
    _entry = _plain(result);
    _entering = true;
    _justEvaluated = false;
  }

  /// 按下运算符。
  void setOperation(Operation operation) {
    _recoverFromError();
    if (_justEvaluated) {
      // 等号之后接着按运算符：以刚才的结果为左操作数，开始新的一轮
      _accumulator = _value;
      _pending = operation;
      _entering = false;
      _justEvaluated = false;
      _lastOperand = null;
      _repeatOperation = null;
      _repeatOperand = null;
      return;
    }
    if (_pending != null && _entering) {
      // 连续运算：先把前一步算完
      _lastOperand = _value;
      _accumulator = _apply(_accumulator!, _pending!, _lastOperand!);
      _entry = _plain(_accumulator!);
      _pending = operation;
      _entering = false;
      return;
    }
    if (_pending == operation) {
      // 连按同一个运算符只做替换，不重复计算
      return;
    }
    _accumulator = _value;
    _pending = operation;
    _entering = false;
  }

  /// 按下等号。连续按会重复上一步运算（iOS 行为）。
  void equals() {
    _recoverFromError();
    if (_pending != null) {
      final operand = _entering ? _value : (_lastOperand ?? 0);
      _accumulator = _apply(_accumulator!, _pending!, operand);
      _repeatOperation = _pending;
      _repeatOperand = operand;
      _entry = _plain(_accumulator!);
      _pending = null;
      _lastOperand = null;
      _entering = false;
      _justEvaluated = true;
      return;
    }
    if (_justEvaluated && _repeatOperation != null) {
      _accumulator =
          _apply(_accumulator!, _repeatOperation!, _repeatOperand ?? 0);
      _entry = _plain(_accumulator!);
      _justEvaluated = true;
    }
  }

  /// 清除键。
  void clear() {
    if (!_hasError && clearLabel == 'C') {
      // 只清掉当前正在输入的数字，保留待完成的运算
      _entry = '0';
      _entering = false;
      return;
    }
    _reset();
  }

  // ---------------------------------------------------------------- 内部实现

  double get _value => double.tryParse(_entry) ?? 0;

  int _digitCount(String s) =>
      s.replaceAll('-', '').replaceAll('.', '').length;

  double _apply(double a, Operation operation, double b) {
    if (operation == Operation.divide && b == 0) {
      _hasError = true;
      _entry = '0';
      _pending = null;
      _entering = false;
      _justEvaluated = false;
      throw const DivisionByZeroException();
    }
    return switch (operation) {
      Operation.add => a + b,
      Operation.subtract => a - b,
      Operation.multiply => a * b,
      Operation.divide => a / b,
    };
  }

  /// 出错后按任意键都从零开始。
  void _recoverFromError() {
    if (_hasError) _reset();
  }

  void _reset() {
    _entry = '0';
    _accumulator = null;
    _pending = null;
    _entering = false;
    _justEvaluated = false;
    _hasError = false;
    _lastOperand = null;
    _repeatOperation = null;
    _repeatOperand = null;
  }

  /// 数值转成不带千分位的纯文本。
  static String _plain(double v) {
    if (v == 0) return '0';
    if (v.isNaN || v.isInfinite) return '错误';
    final abs = v.abs();
    if (abs >= 1e12 || abs < 1e-9) return _exponential(v);
    var s = v.toStringAsPrecision(12);
    if (s.contains('e') || s.contains('E')) return _exponential(v);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// 指数形式，例如 1.234568e+15。
  static String _exponential(double v) {
    final s = v.toStringAsExponential(6);
    final index = s.indexOf('e');
    if (index < 0) return s;
    var mantissa = s.substring(0, index);
    final exponent = s.substring(index);
    if (mantissa.contains('.')) {
      mantissa =
          mantissa.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return '$mantissa$exponent';
  }

  /// 在纯文本上加千分位分隔符。
  static String _format(String raw) {
    if (raw == '错误') return raw;
    if (raw.contains('e') || raw.contains('E')) return raw;
    final negative = raw.startsWith('-');
    final body = negative ? raw.substring(1) : raw;
    final dot = body.indexOf('.');
    final intPart = dot >= 0 ? body.substring(0, dot) : body;
    final fraction = dot >= 0 ? body.substring(dot + 1) : null;
    final grouped = intPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final out = fraction == null ? grouped : '$grouped.$fraction';
    return negative ? '-$out' : out;
  }
}
