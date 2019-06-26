# asp3_gr_peach_vscode
TOPPERS/ASP3カーネルとアプリをVisual Studio Codeで開発可能にするための環境です．  

下記リポジトリを大いに参考にしました．ここで深く感謝いたします．  
[Azure IoT Hub with TOPPERS/ASP3](https://github.com/h7ga40/azure_iot_hub_peach)

## ターゲット

* マイコンボード：[GR-PEACH](https://www.core.co.jp/product/m2m/gr-peach/index.html)
* [TOPPERS/ASP3カーネル GR-PEACH簡易パッケージ 3.2.0 (リリース日：2017-07-21)](http://toppers.jp/asp3-e-download.html)
* ホストPC環境 （詳細な環境構築の手順はそれぞれのQiita記事をご参照ください）
  * [Windows 10 Professional](https://qiita.com/takasehideki/items/59e3d179d462142a8633)
* 開発ツール
  * IDE：[Visual Studio Code](https://code.visualstudio.com) (1.35.1で確認済み)
  * クロスコンパイラ：[arm-none-eabi Version 6-2017-q2-update](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads/6-2017-q2-update)
  * デバッガ：[OpenOCD 0.10.0-12-20190422](https://github.com/gnu-mcu-eclipse/openocd/releases/tag/v0.10.0-12-20190422)

## オリジナルからの変更点

[TOPPERS/ASP3カーネル GR-PEACH簡易パッケージ](http://toppers.jp/asp3-e-download.html)からの変更点を列挙します

* [Makefile.target](./asp3/target/gr_peach_gcc/Makefile.target) 21行目: 実行形態をRAM実行に変更（EXECUTE_ON = ROM）
* [apps/sample1/Makefile](./apps/sample1/Makefile) 74行名: オブジェクトファイル名の拡張子を elf に変更（OBJEXT = elf）

## 使用方法

下記のQiita記事をご参照ください

* [VSCodeでTOPPERSアプリをビルド＆実行する](https://qiita.com/takasehideki/items/fa0a1a6567a22f469515)

現在の問題として，デバッグ対象のアプリ指定の煩雑さがあります．
アプリ指定を変更する際には，[apps/.vscode/launch.json](apps/.vscode/launch.json)の記述を変更（sample1をディレクトリ名に全置換）する必要があります．
エレガントな良い方法をご存知でしたら教えてください^^;

## ライセンス等

[TOPPERSライセンス](http://toppers.jp/license.html)に従います．  
[オリジナルのREADME.txt](./asp3/README.txt)も参考にしてください．
