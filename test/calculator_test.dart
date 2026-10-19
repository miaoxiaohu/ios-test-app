import 'package:flutter_test/flutter_test.dart';
import 'package:ios_calculator/calculator.dart';

void main() {
  Calculator newCalculator() => Calculator();

  void type(Calculator c, String digits) {
    for (final d in digits.split('')) {
      if (d == '.') {
        c.inputDecimalPoint();
      } else {
        c.inputDigit(d);
      }
    }
  }

  group('四则运算', () {
    test('12 + 3 = 15', () {
      final c = newCalculator();
      type(c, '12');
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      expect(c.display, '15');
    });

    test('7 × 8 = 56', () {
      final c = newCalculator();
      type(c, '7');
      c.setOperation(Operation.multiply);
      type(c, '8');
      c.equals();
      expect(c.display, '56');
    });

    test('9 − 4 = 5', () {
      final c = newCalculator();
      type(c, '9');
      c.setOperation(Operation.subtract);
      type(c, '4');
      c.equals();
      expect(c.display, '5');
    });

    test('10 ÷ 4 = 2.5', () {
      final c = newCalculator();
      type(c, '10');
      c.setOperation(Operation.divide);
      type(c, '4');
      c.equals();
      expect(c.display, '2.5');
    });

    test('0.1 + 0.2 = 0.3（浮点误差被消化掉）', () {
      final c = newCalculator();
      type(c, '0.1');
      c.setOperation(Operation.add);
      type(c, '0.2');
      c.equals();
      expect(c.display, '0.3');
    });

    test('不按运算符优先级，从左往右算：2 + 3 × 4 = 20', () {
      final c = newCalculator();
      type(c, '2');
      c.setOperation(Operation.add);
      type(c, '3');
      c.setOperation(Operation.multiply);
      type(c, '4');
      c.equals();
      expect(c.display, '20');
    });
  });

  group('除以零', () {
    test('5 ÷ 0 进入错误状态', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.divide);
      type(c, '0');
      expect(() => c.equals(), throwsA(isA<DivisionByZeroException>()));
      expect(c.display, '错误');
      expect(c.hasError, isTrue);
    });

    test('错误状态下按数字键，从零重新开始', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.divide);
      type(c, '0');
      try {
        c.equals();
      } on DivisionByZeroException {
        // 预期内的异常
      }
      c.inputDigit('7');
      expect(c.display, '7');
      expect(c.hasError, isFalse);
    });

    test('错误状态下按清除键也能复位', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.divide);
      type(c, '0');
      try {
        c.equals();
      } on DivisionByZeroException {
        // 预期内的异常
      }
      c.clear();
      expect(c.display, '0');
      expect(c.hasError, isFalse);
    });
  });

  group('显示格式', () {
    test('大数字加千分位', () {
      final c = newCalculator();
      type(c, '1234567');
      c.setOperation(Operation.add);
      type(c, '0');
      c.equals();
      expect(c.display, '1,234,567');
    });

    test('超大数字走科学计数法', () {
      final c = newCalculator();
      type(c, '999999999999');
      c.setOperation(Operation.add);
      type(c, '1');
      c.equals();
      expect(c.display, '1e+12');
    });

    test('小数点不能重复输入', () {
      final c = newCalculator();
      type(c, '1');
      c.inputDecimalPoint();
      type(c, '2');
      c.inputDecimalPoint();
      type(c, '3');
      expect(c.display, '1.23');
    });

    test('输入位数上限为 12', () {
      final c = newCalculator();
      type(c, '123456789012345');
      expect(c.display, '123,456,789,012');
    });
  });

  group('清除键', () {
    test('正在输入时显示 C，只清当前项', () {
      final c = newCalculator();
      type(c, '12');
      expect(c.clearLabel, 'C');
      c.clear();
      expect(c.display, '0');
      expect(c.clearLabel, 'AC');
    });

    test('C 之后仍保留待完成的运算', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.add);
      type(c, '7');
      c.clear();
      c.equals();
      expect(c.display, '5');
    });

    test('空闲时显示 AC，清空全部', () {
      final c = newCalculator();
      type(c, '12');
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      expect(c.display, '15');
      // 等号之后处于空闲状态，清除键变回 AC
      expect(c.clearLabel, 'AC');
      c.clear();
      expect(c.display, '0');
      expect(c.clearLabel, 'AC');
      // AC 之后没有任何待完成的运算，再按等号不会凭空算出结果
      c.equals();
      expect(c.display, '0');
    });
  });

  group('百分比', () {
    test('单独取百分比：50 % = 0.5', () {
      final c = newCalculator();
      type(c, '50');
      c.percent();
      expect(c.display, '0.5');
    });

    test('加法中的百分比：50 + % = 25，再按等号得 75', () {
      final c = newCalculator();
      type(c, '50');
      c.setOperation(Operation.add);
      c.percent();
      expect(c.display, '25');
      c.equals();
      expect(c.display, '75');
    });
  });

  group('正负号', () {
    test('切换正负号', () {
      final c = newCalculator();
      type(c, '5');
      c.toggleSign();
      expect(c.display, '-5');
      c.toggleSign();
      expect(c.display, '5');
    });

    test('0 不受影响', () {
      final c = newCalculator();
      c.toggleSign();
      expect(c.display, '0');
    });
  });

  group('等号', () {
    test('连按等号重复上一步运算：5 + 3 = 8，再按 = 得 11', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      expect(c.display, '8');
      c.equals();
      expect(c.display, '11');
    });

    test('等号之后输入新数字会开始新一轮计算', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      c.inputDigit('2');
      expect(c.display, '2');
      c.equals();
      expect(c.display, '2');
    });

    test('等号之后按运算符，以结果为左操作数', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      expect(c.display, '8');
      c.setOperation(Operation.multiply);
      type(c, '2');
      c.equals();
      expect(c.display, '16');
    });

    test('连按同一个运算符不会重复计算', () {
      final c = newCalculator();
      type(c, '5');
      c.setOperation(Operation.add);
      c.setOperation(Operation.add);
      type(c, '3');
      c.equals();
      expect(c.display, '8');
    });
  });
}
