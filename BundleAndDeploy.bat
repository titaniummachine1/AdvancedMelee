@echo off

node bundle.js
move /Y "AdvancedMelee.lua" "%localappdata%"
exit