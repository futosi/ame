@echo off
chcp 65001 >nul
rem 世田谷区 雨予報シミュレーター: ブラウザで開く(データは開いた時点で自動取得)
cd /d "%~dp0"
start "" "%~dp0index.html"
