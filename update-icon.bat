@echo off
echo Copiando icone...
if not exist "D:\flutter-app\assets" mkdir "D:\flutter-app\assets"
copy /Y "C:\Users\sergi\Downloads\sqs103b.png" "D:\flutter-app\assets\icon.png"

echo Instalando dependencias...
call D:\downloads11-11-2025\flutter_windows_3.38.3-stable\flutter\bin\flutter pub get

echo Gerando icones...
call D:\downloads11-11-2025\flutter_windows_3.38.3-stable\flutter\bin\flutter pub run flutter_launcher_icons

echo Pronto! Icone atualizado.
pause
