# 计算器 (ios_calculator)

一个用 Flutter 写的 iOS 计算器，界面照着 iOS 自带计算器做（黑色背景、右侧一列橙色运算符）。

- 四则运算 `+ − × ÷`
- `AC / C` 清除、`+/−` 正负号、`%` 百分比
- 连续运算**不按运算符优先级**，从左往右算（与 iOS 计算器一致）
- 连按等号会重复上一步运算
- 大数字自动加千分位，超大数字自动转科学计数法
- 除以零显示「错误」，按任意键即可复位

## 代码结构

| 文件 | 作用 |
| --- | --- |
| `lib/calculator.dart` | 计算引擎，纯 Dart，不依赖 Flutter，可直接单测 |
| `lib/calculator_page.dart` | 界面与交互 |
| `lib/main.dart` | 入口 |
| `test/calculator_test.dart` | 引擎的单元测试 |

引擎与界面是分开的：所有运算规则都在 `Calculator` 里，UI 只负责把按键映射成方法调用并刷新界面。

## 构建

推送到 `master` 会自动触发 GitHub Actions，产出**未签名**的 `.ipa`：

```
.github/workflows/ios-build.yml
  ├─ flutter create  生成 iOS 工程（仓库里不带 ios/ 目录）
  ├─ flutter test    跑单元测试，不通过就不往下走
  ├─ flutter build ios --release --no-codesign
  ├─ 打包成 ios-calculator-unsigned.ipa
  ├─ 校验包结构（防止「构建绿了但包是坏的」）
  └─ 上传为 Actions artifact
```

跑完在 Actions 页面下载 `ios-calculator-unsigned-ipa` 里的 `.ipa` 即可。

## 装到自己的 iPhone

`.ipa` 是未签名的，用免费 Apple ID 重新签名后即可安装：

- **Sideloadly**（https://sideloadly.io ，最快上手）：拖入 ipa，填 Apple ID，点 Start。需要 USB 连接。
- **AltStore Classic**（https://altstore.io ，自动续签）：电脑常跑 AltServer，同一 Wi-Fi 下手机自动续签，不用每周重装。

装完在手机上还要做两件事：

1. 设置 → 通用 → VPN与设备管理 → 找到你的 Apple ID → **信任**
2. 设置 → 隐私与安全性 → **开发者模式** → 开启 → 重启后再点一次「启用」

> 「开发者模式」这一项在触发之前是隐藏的，必须先点一次装好的 app，系统弹提示后它才会出现在设置里。

免费 Apple ID 的限制：签名 **7 天**过期、最多 **3 个 app** 同时活跃、每 7 天最多 10 个 App ID。建议用小号。

## 说明

- 仓库是 **public**，GitHub Actions 对公开仓库免费不限 macOS 分钟。
- `codemagic.yaml` 是早期用 Codemagic 构建时留下的备份，目前不会自动触发。
