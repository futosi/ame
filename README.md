# 世田谷区 雨予報シミュレーター

世田谷区の「今日・明日の1時間ごとの天気」と「雨雲レーダー」を1画面で見るツール。

**公開URL: https://futosi.github.io/ame/** （スマホ可。ホーム画面に追加すると「世田谷の雨」で入る）

## 使い方

- **スマホ / 他のPC** — https://futosi.github.io/ame/ を開くだけ
- **手元のPC** — `雨予報を開く.bat` をダブルクリック（または `index.html` を直接開く）

いずれも開いた時点で最新データを自動取得します。インストール・APIキーは不要です。

## 公開の仕組み

`main` ブランチのルートを GitHub Pages がそのまま配信しているだけ（ビルドなし）。
更新したいときは push すれば1分ほどで反映されます。

```
git add -A && git commit -m "..." && git push
```

データはすべて閲覧者のブラウザから直接APIを叩いて取るので、サーバー側の定期実行は無し。
つまり[kinri-tracker](https://github.com/futosi/kinri-tracker)と違い GitHub Actions は要りません。

## 中身

- **傘の判定** — 今日この後に降る時間帯と、明日の雨をひとことで表示
- **1時間ごとの天気**（今日 / 明日タブ） — 天気アイコン・降水確率のバー・雨量(mm/h)・気温。現在時刻のコマが中央に来る
- **雨雲レーダー** — 1時間前（実況）〜15時間後まで、計33コマ。スライダーと再生ボタンで動かせる
  - コマの刻みは先に行くほど粗い：**5分**（-1h〜+1h）→ **1時間**（+2〜+6h）→ **3時間**（+9, +12, +15h）
  - 目盛りはコマ番号が等間隔＝時間は不等間隔なので、`renderTicks()` が実位置に置いている

## データ源

| 用途 | 提供元 | 備考 |
|---|---|---|
| 天気・気温・降水確率 | [Open-Meteo](https://open-meteo.com/) | APIキー不要。世田谷区役所 35.6464°N, 139.6531°E |
| 雨雲レーダー（〜+1h） | 気象庁 高解像度降水ナウキャスト (hrpns) | `nowc/targetTimes_N1.json`=実況 / `N2.json`=予測。5分刻み |
| 雨雲レーダー（+2〜+15h） | 気象庁 降水短時間予報 (rasrf) | `rasrf/targetTimes.json`。1時間刻み。≤6hは1kmメッシュ、それ以降は5kmメッシュなので粗く見えるのは仕様 |
| 地図タイル | 国土地理院 (pale) | |
| 区界 | uedayou.net/loa（国土数値情報ベース） | `vendor/setagaya-boundary.js` に同梱済み |

タイル/JSONの時刻はすべて **UTC**。表示は+9hしてJSTにしている。

Open-Meteo・気象庁とも `Access-Control-Allow-Origin: *` を返すため、`file://` で開いても取得できる。
区界だけは `fetch` だと file:// でCORSに阻まれるので、`<script>` で読める JS 形式で同梱している。

### 降水短時間予報(rasrf)のハマりどころ

`rasrf/targetTimes.json` は「近い予報ほど新しい basetime」を指すように、`:30` の basetime で +1〜+6h、
`:00` の basetime で +7〜+15h を案内してくる。**が、`:30` の basetime は解析(lead 0)のタイルしか実在せず、
予測タイルは全ズームで404になる**（時間をおいても出てこない＝生成ラグではない）。

一方 **`:00` の毎時 basetime は +1〜+15h を全部持っている**（複数の basetime で検証済み）。
なので `farFrames()` は targetTimes の案内どおりには組まず、「最新の `:00` basetime から +k時間」で
自前に validtime を組み立てている。

雨の無いタイルは404が返るが、Leaflet が空欄として扱うので実害なし。

## 構成

```
index.html                       本体（これ単体＋vendorで動く）
雨予報を開く.bat                  起動用
vendor/leaflet.js, leaflet.css   地図ライブラリ (1.9.4)
vendor/setagaya-boundary.js      世田谷区の行政界
```

プレビュー用に `Workspace/.claude/launch.json` に `ame`（port 8123）を追加済み。
