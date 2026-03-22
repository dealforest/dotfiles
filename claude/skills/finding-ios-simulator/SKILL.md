---
name: finding-ios-simulator
description: 最新iOSランタイムの無印iPhoneシミュレータ名を取得する。「シミュレータ名を取得」「シミュレータを特定」「iPhone/iPadシミュレータ」「どのシミュレータを使う」と言及された時に使用。
context: fork
allowed-tools: Bash(scripts/*:*)
---

# iPhoneシミュレータの取得

最新iOSランタイムの無印iPhoneシミュレータを取得する。

## 実行

### iPhone
```bash
scripts/get-iphone-simulator.sh | cut -f1
```

### iPad
```bash
scripts/get-ipad-simulator.sh | cut -f1
```

## 出力例

```
iPhone (A16)
```
