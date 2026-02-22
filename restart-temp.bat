@echo off
cd /d "C:\WorkSpace\agent\nanoclaw"
"C:\Program Files\nodejs\node.exe" dist/index.js >> "C:\WorkSpace\agent\nanoclaw\logs\nanoclaw-2026-02-22T08-50-05.log" 2>&1
exit
