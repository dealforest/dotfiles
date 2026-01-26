---
name: ios-simulator-photo-library-opener
description: 起動中のiOSシミュレータの写真ライブラリをFinderで開く。シミュレータの写真を確認したい時に使用。
---

# iOS シミュレータの写真ライブラリを開く

## 前提条件

- iOS シミュレータが起動していること

## 実行

```bash
UDID=$(xcrun simctl list devices booted -j | jq -r '.devices[][] | select(.state == "Booted") | .udid')
open ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Media/DCIM/100APPLE/
```

## 複数シミュレータ起動時

最初に見つかったシミュレータの写真ライブラリを開く。特定のシミュレータを開きたい場合は UDID を直接指定。
