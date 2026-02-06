#!/bin/bash

# 最新iOSランタイムの無印iPhoneシミュレータを取得する
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
  # iPhoneだけ取り出し（順序は保持）
  ($devs | map(select(.name | startswith("iPhone")))) as $iphones
  |
  # 無印 iPhone（"iPhone (" で始まる）を優先。無ければ最初のiPhone。
  (
    ($iphones | map(select(.name | startswith("iPhone ("))) | first)
    // ($iphones | first)
  ) as $pick
  |
  "\($pick.name)\t\($pick.udid)"
'
