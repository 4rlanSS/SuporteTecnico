@echo off
:: Define a pagina de codigo para UTF-8 para exibir acentos corretamente
chcp 65001 >nul
title Ferramentas de Suporte Tecnico
color 0A
setlocal enabledelayedexpansion

:: =============================================================================
:: VERIFICACAO DE PRIVILEGIOS DE ADMINISTRADOR
:: =============================================================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    cls
    echo.
    echo  =======================================================================
    echo   [ERRO] Este script precisa de privilegios de administrador.
    echo.
    echo   Por favor, clique com o botao direito no arquivo e selecione
    echo   "Executar como administrador".
    echo  =======================================================================
    echo.
    pause
    exit
)

:MENU
cls
echo =======================================================================
echo.
echo                 FERRAMENTAS DE SUPORTE TECNICO
echo.
echo =======================================================================
echo  1 - Limpeza Rapida de Cache + Liberar RAM
echo  2 - Limpeza Profunda (Avancada) + Liberar RAM
echo  3 - Informacoes completas da rede
echo  4 - Flush DNS (Limpar cache de DNS)
echo  5 - Pingar um Servidor/IP
echo  6 - Resetar configuracoes de rede (TCP/IP e Winsock)
echo  7 - Resetar rotas de rede
echo  8 - Corrigir fila de impressao travada
echo  9 - Reiniciar Spooler de Impressao
echo 10 - Verificar e corrigir arquivos do sistema (SFC)
echo 11 - Mostrar processos com maior uso de CPU e Memoria
echo 12 - Reiniciar Computador
echo  0 - Sair
echo =======================================================================
set /p opcao="Escolha uma opcao: "

if "%opcao%"=="1" goto LIMPEZARAPIDA
if "%opcao%"=="2" goto LIMPEZAPROFUNDA
if "%opcao%"=="3" goto INFONET
if "%opcao%"=="4" goto FLUSHDNS
if "%opcao%"=="5" goto PINGSRV
if "%opcao%"=="6" goto RESETNET
if "%opcao%"=="7" goto RESETROTAS
if "%opcao%"=="8" goto ERROSIMPRESSORA
if "%opcao%"=="9" goto SPOOLER
if "%opcao%"=="10" goto AJUSTARPC
if "%opcao%"=="11" goto PROCESSOS
if "%opcao%"=="12" goto REINICIAR
if "%opcao%"=="0" exit

echo Opcao invalida.
pause
goto MENU

:: =============================================================================
:: FUNCOES DE APOIO
:: =============================================================================

:ProgressBar
setlocal
:: Argumentos: %1=current, %2=total, %3=message
set "current=%~1"
set "total=%~2"
set "message=%~3"
set /a "percent=current * 100 / total"
set /a "bar_len=current * 40 / total"
set "bar="
for /l %%i in (1,1,%bar_len%) do set "bar=!bar!█"
set "padding="
for /l %%i in (%bar_len%,1,39) do set "padding=!padding! "
for /f %%a in ('copy /z "%~f0" nul') do set "cr=%%a"
<nul set /p "=.!cr!%message% [!bar!!padding!] !percent!%%"
endlocal
goto :eof

:COLETARINFO_INICIAL
for /f %%a in ('powershell -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory"') do set "FreeMemBeforeKB=%%a"
for /f %%a in ('powershell -Command "(Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace"') do set "FreeDiskBeforeB=%%a"
goto :eof

:COLETARINFO_FINAL
for /f %%a in ('powershell -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory"') do set "FreeMemAfterKB=%%a"
for /f %%a in ('powershell -Command "(Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace"') do set "FreeDiskAfterB=%%a"
goto :eof

:RELATORIO
cls
echo =======================================================================
echo.
echo                         RELATORIO FINAL DA LIMPEZA
echo.
echo =======================================================================
set /a "MemoriaAntesMB=FreeMemBeforeKB / 1024"
set /a "MemoriaDepoisMB=FreeMemAfterKB / 1024"
set /a "MemoriaLiberadaMB=MemoriaDepoisMB - MemoriaAntesMB"
set "DiscoAntesB_str=%FreeDiskBeforeB%"
set "DiscoDepoisB_str=%FreeDiskAfterB%"
set /a "DiscoAntesMB=%DiscoAntesB_str:~0,-6%"
set /a "DiscoDepoisMB=%DiscoDepoisB_str:~0,-6%"
set /a "DiscoLiberadoMB=%DiscoDepoisMB% - %DiscoAntesMB%"
echo  Memoria RAM Livre (Antes):  %MemoriaAntesMB% MB
echo  Memoria RAM Livre (Depois): %MemoriaDepoisMB% MB
echo  --------------------------------------------------
echo  Memoria RAM Liberada:       %MemoriaLiberadaMB% MB
echo.
echo  Espaco em Disco (Antes):    %DiscoAntesMB% MB
echo  Espaco em Disco (Depois):   %DiscoDepoisMB% MB
echo  --------------------------------------------------
echo  Espaco em Disco Liberado:   %DiscoLiberadoMB% MB
echo =======================================================================
pause
goto MENU

:: =============================================================================
:: OPCAO 1: LIMPEZA RAPIDA
:: =============================================================================
:LIMPEZARAPIDA
cls
call :COLETARINFO_INICIAL
echo =======================================================================
echo.
echo                 INICIANDO LIMPEZA RAPIDA...
echo.
echo =======================================================================
echo.
echo [1/4] Limpando arquivos temporarios do Windows...
del /s /q /f C:\Windows\Temp\*.* >nul 2>&1
echo [2/4] Limpando arquivos temporarios do usuario (%%temp%%)...
del /s /q /f %temp%\*.* >nul 2>&1
echo [3/4] Limpando cache de prefetch...
del /s /q /f C:\Windows\Prefetch\*.* >nul 2>&1
echo [4/4] Liberando memoria RAM...
PowerShell -Command "Clear-Host; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul 2>&1
call :COLETARINFO_FINAL
call :RELATORIO

:: =============================================================================
:: OPCAO 2: LIMPEZA PROFUNDA (OTIMIZADA)
:: =============================================================================
:LIMPEZAPROFUNDA
cls
call :COLETARINFO_INICIAL
echo =======================================================================
echo.
echo      INICIANDO LIMPEZA PROFUNDA OTIMIZADA...
echo.
echo =======================================================================
echo.
set "total_steps=10"
set "step=0"

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Esvaziando a Lixeira..."
PowerShell.exe -NoProfile -Command "Clear-RecycleBin -Confirm:$false" >nul 2>&1

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Limpando Temp do Sistema..."
del /s /q /f C:\Windows\Temp\*.* >nul 2>&1
del /s /q /f C:\Windows\Prefetch\*.* >nul 2>&1
del /s /q /f C:\Windows\Logs\*.log >nul 2>&1
del /s /q /f C:\Windows\SoftwareDistribution\Download\*.* >nul 2>&1

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Encerrando Processos..."
taskkill /F /IM "msedge.exe" >nul 2>&1
taskkill /F /IM "chrome.exe" >nul 2>&1
taskkill /F /IM "firefox.exe" >nul 2>&1
taskkill /F /IM "brave.exe" >nul 2>&1
taskkill /F /IM "vivaldi.exe" >nul 2>&1
taskkill /F /IM "onedrive.exe" >nul 2>&1

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Limpando Caches de Usuarios..."
for /d %%U in (C:\Users\*) do (
    if exist "%%U\AppData\Local" (
        del /s /q /f "%%U\AppData\Local\Temp\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\Microsoft\Edge\User Data\Default\Cache" del /s /q /f "%%U\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\Google\Chrome\User Data\Default\Cache" del /s /q /f "%%U\AppData\Local\Google\Chrome\User Data\Default\Cache\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache" del /s /q /f "%%U\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\Vivaldi\User Data\Default\Cache" del /s /q /f "%%U\AppData\Local\Vivaldi\User Data\Default\Cache\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\Mozilla\Firefox\Profiles" rd /s /q "%%U\AppData\Local\Mozilla\Firefox\Profiles" >nul 2>&1
        if exist "%%U\AppData\Local\Spotify\Data" del /s /q /f "%%U\AppData\Local\Spotify\Data\*.*" >nul 2>&1
        if exist "%%U\AppData\Roaming\Adobe\Common\Media Cache Files" del /s /q /f "%%U\AppData\Roaming\Adobe\Common\Media Cache Files\*.*" >nul 2>&1
        if exist "%%U\AppData\Local\CrashDumps" del /s /q /f "%%U\AppData\Local\CrashDumps\*.*" >nul 2>&1
    )
)

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Limpeza de Componentes (DISM)..."
echo.
echo.
echo    ATENCAO: Este passo pode demorar MUITO tempo. A barra de progresso
echo    da propria ferramenta DISM sera exibida abaixo. Por favor, aguarde.
echo.
dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
echo.

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Liberando Memoria RAM..."
PowerShell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul 2>&1

set /a step+=1
call :ProgressBar %step% %total_steps% "Fase %step%/%total_steps%: Finalizando..."
timeout /t 1 >nul

echo.
echo.
echo Limpeza profunda concluida. Gerando relatorio...
timeout /t 2 >nul
call :COLETARINFO_FINAL
call :RELATORIO

:: =============================================================================
:: OPCAO 3: INFORMACOES DE REDE
:: =============================================================================
:INFONET
cls
echo =======================================================================
echo.
echo                 INFORMACOES COMPLETAS DE REDE
echo.
echo =======================================================================
ipconfig /all | more
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 4: FLUSH DNS
:: =============================================================================
:FLUSHDNS
cls
echo Limpando o cache de resolucao de DNS...
ipconfig /flushdns
echo.
echo Cache de DNS limpo com sucesso.
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 5: PINGAR SERVIDOR
:: =============================================================================
:PINGSRV
cls
echo =======================================================================
echo.
echo                       TESTE DE PING (CONECTIVIDADE)
echo.
echo =======================================================================
set /p server="Digite o endereco do servidor (ex: google.com ou 8.8.8.8): "
cls
echo Pingando %server%...
echo.
ping %server%
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 6: RESETAR CONFIGURACOES DE REDE
:: =============================================================================
:RESETNET
cls
echo =======================================================================
echo.
echo        ATENCAO: Isso ira resetar as configuracoes de rede do Windows.
echo        Pode ser necessario reiniciar o computador.
echo.
echo =======================================================================
set /p "confirm=Tem certeza que deseja continuar? (S/N): "
if /i not "%confirm%"=="S" goto MENU

echo.
echo [1/4] Redefinindo o catalogo Winsock...
netsh winsock reset
echo.
echo [2/4] Redefinindo o stack TCP/IP...
netsh int ip reset
echo.
echo [3/4] Liberando o endereco IP atual...
ipconfig /release
echo.
echo [4/4] Renovando o endereco IP...
ipconfig /renew
echo.
echo As configuracoes de rede foram redefinidas.
echo E recomendado reiniciar o computador para aplicar todas as alteracoes.
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 7: RESETAR ROTAS DE REDE
:: =============================================================================
:RESETROTAS
cls
echo =======================================================================
echo.
echo        ATENCAO: Isso ira limpar todas as rotas de rede (estaticas e
echo        persistentes). As rotas padrao serao recriadas.
echo.
echo =======================================================================
set /p "confirm=Tem certeza que deseja continuar? (S/N): "
if /i not "%confirm%"=="S" goto MENU
echo.
echo Limpando a tabela de roteamento...
route /f
echo.
echo Rotas limpas com sucesso. Pode ser necessario reiniciar o computador.
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 8: CORRIGIR FILA DE IMPRESSAO
:: =============================================================================
:ERROSIMPRESSORA
cls
echo =======================================================================
echo.
echo      Esta operacao tentara corrigir problemas na fila de impressao
echo      parando o servico e limpando os trabalhos pendentes.
echo.
echo =======================================================================
echo.
echo [1/3] Parando o servico de Spooler de Impressao...
net stop spooler
echo.
echo [2/3] Limpando a pasta da fila de impressao...
del /q /f /s "%systemroot%\System32\spool\PRINTERS\*.*"
echo.
echo [3/3] Iniciando o servico de Spooler de Impressao...
net start spooler
echo.
echo Fila de impressao limpa com sucesso!
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 9: REINICIAR SPOOLER DE IMPRESSAO
:: =============================================================================
:SPOOLER
cls
echo Reiniciando o servico de Spooler de Impressao...
echo.
echo Parando o servico...
net stop spooler
echo.
echo Iniciando o servico...
net start spooler
echo.
echo Servico reiniciado com sucesso!
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 10: VERIFICAR E CORRIGIR ARQUIVOS DO SISTEMA
:: =============================================================================
:AJUSTARPC
cls
echo =======================================================================
echo.
echo      VERIFICADOR DE ARQUIVOS DO SISTEMA (SFC)
echo.
echo      Esta ferramenta verifica a integridade de todos os arquivos
echo      protegidos do sistema e repara os arquivos com problemas.
echo      Este processo pode levar bastante tempo.
echo.
echo =======================================================================
echo.
set /p "confirm=Deseja iniciar a verificacao agora? (S/N): "
if /i not "%confirm%"=="S" goto MENU

cls
echo Iniciando a verificacao... Por favor, aguarde.
sfc /scannow
echo.
echo Verificacao concluida. Verifique os resultados acima.
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 11: MOSTRAR PROCESSOS ATIVOS (CPU E MEMORIA)
:: =============================================================================
:PROCESSOS
cls
echo =======================================================================
echo.
echo        Top 15 Processos por Uso de CPU e Memoria
echo.
echo =======================================================================
echo.
PowerShell -NoProfile -Command "Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 15 -Property ProcessName, Id, @{Name='CPU(s)';Expression={[math]::Round($_.CPU,2)}}, @{Name='Memoria(MB)';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} | Format-Table -AutoSize"
echo.
pause
goto MENU

:: =============================================================================
:: OPCAO 12: REINICIAR COMPUTADOR
:: =============================================================================
:REINICIAR
cls
echo =======================================================================
echo.
echo        ATENCAO: O computador sera reiniciado.
echo        Salve todos os seus trabalhos antes de continuar.
echo.
echo =======================================================================
set /p "confirm=Deseja reiniciar o computador agora? (S/N): "
if /i not "%confirm%"=="S" goto MENU

shutdown /r /t 10 /c "O computador sera reiniciado em 10 segundos a pedido do script de suporte."
cls
echo O computador sera reiniciado em 10 segundos...
echo Para cancelar, execute 'shutdown /a' em outra janela de comando.
timeout /t 11 >nul
goto MENU