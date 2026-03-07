@echo off
RMDIR /S /Q app
RMDIR /S /Q node_modules
RMDIR /S /Q .expo
DEL /F /Q package.json
DEL /F /Q package-lock.json
DEL /F /Q app.json
DEL /F /Q tsconfig.json
DEL /F /Q eslint.config.js
DEL /F /Q expo-env.d.ts
DEL /F /Q .eslintcache
