@echo off
rem Passe a imagem de origem como parametro para substituir o icone:
rem   update-icon.bat C:\caminho\para\nova-imagem.png
rem Sem parametro, apenas regera os icones a partir de assets\icon.png
if not "%~1"=="" (
    echo Copiando icone...
    copy /Y "%~1" "assets\icon.png"
)

echo Instalando dependencias...
call C:\flutter_windows_3.38.3-stable\flutter\bin\flutter pub get

echo Gerando icones...
call C:\flutter_windows_3.38.3-stable\flutter\bin\flutter pub run flutter_launcher_icons

echo Pronto! Icone atualizado.
pause
