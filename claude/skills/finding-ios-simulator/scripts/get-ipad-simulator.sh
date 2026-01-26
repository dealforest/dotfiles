#!/bin/bash

# 最新iOSランタイムの無印iPadシミュレータを取得する
# 出力: 名前<TAB>UDID

xcrun simctl list -j devices runtimes \
| jq -r '
  # 最新の利用可能 iOS runtime identifier
  (.runtimes
    | map(select(.isAvailable==true and .platform=="iOS"))
    | sort_by(.version | split(".") | map(tonumber))
    | last
    | .identifier) as $rt
  |
  # その runtime の devices 配列（availableなもの）
  (.devices[$rt] | map(select(.isAvailable==true))) as $devs
  |
  # iPadだけ取り出し（順序は保持）
  ($devs | map(select(.name | startswith("iPad")))) as $ipads
  |
  # 無印 iPad（"iPad (" で始まる）を優先。無ければ最初のiPad。
  (
    ($ipads | map(select(.name | startswith("iPad ("))) | first)
    // ($ipads | first)
  ) as $pick
  |
  "\($pick.name)\t\($pick.udid)"
'
