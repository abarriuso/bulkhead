param([switch]$LlamaCpp)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
try { $Host.UI.RawUI.WindowTitle = "bulkhead" } catch { }
$Moderna = [bool]$env:WT_SESSION
$Profiles = if ($LlamaCpp) { @("--profile", "llamacpp") } else { @() }
$utf8 = New-Object Text.UTF8Encoding $false

# Debe coincidir con LABEL bulkhead.version del Dockerfile.
$VersionImagen = "7"
# Cada proyecto es el proyecto de Compose "bulkhead-<nombre>"; "general" es "bulkhead".
$Prefijo = "bulkhead"
$NombreValido = '^[a-z][a-z0-9-]{0,29}$'

# docker.exe deja la consola en modo "entrada VT" al salir y Read-Host empieza a
# recibir secuencias de escape (teclas, cambios de foco) como si fueran texto.
# Por eso docker no lee de la consola salvo cuando hace falta ($null | docker ...
# o -RedirectStandardInput) y antes de cada lectura se restaura el modo original.
$ModoEntrada = $null
try {
    Add-Type -Namespace Win32 -Name Consola -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@
    $m = [uint32]0
    if ([Win32.Consola]::GetConsoleMode([Win32.Consola]::GetStdHandle(-10), [ref]$m)) { $ModoEntrada = $m }
} catch { }

function Leer($texto) {
    if ($null -ne $ModoEntrada) {
        try { [void][Win32.Consola]::SetConsoleMode([Win32.Consola]::GetStdHandle(-10), $ModoEntrada) } catch { }
    }
    try { $Host.UI.RawUI.FlushInputBuffer() } catch { }
    return Read-Host $texto
}

# docker sin tocar la consola: sin entrada y sin mensajes de error.
function Dock {
    $null | & docker @args 2> $null
}

function Ok($m)    { Write-Host "   OK  " -ForegroundColor Black -BackgroundColor Green -NoNewline; Write-Host "  $m" }
function Aviso($m) { Write-Host "   !!  " -ForegroundColor Black -BackgroundColor Yellow -NoNewline; Write-Host "  $m" -ForegroundColor Yellow }
function Fallo($m) { Write-Host "  ERROR" -ForegroundColor White -BackgroundColor Red -NoNewline; Write-Host "  $m" -ForegroundColor Red }
function Paso($m)  { Write-Host ""; Write-Host "   $m" -ForegroundColor White }
function Nota($m)  { Write-Host "         $m" -ForegroundColor DarkGray }
function Seccion($m) { Write-Host ""; Write-Host "   $m" -ForegroundColor DarkCyan }

function Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   bulkhead                                               " -ForegroundColor White -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   Agentes de IA en un entorno aislado para cada uno de   " -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  │" -ForegroundColor DarkCyan -NoNewline
    Write-Host "   tus proyectos, protegido por un cortafuegos.           " -ForegroundColor DarkGray -NoNewline
    Write-Host "│" -ForegroundColor DarkCyan
    Write-Host "  └──────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
}

function Girar($i) {
    $f = if ($Moderna) { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" } else { "|", "/", "-", "\" }
    return $f[$i % $f.Count]
}

function Limpiar { Write-Host ("`r" + (" " * 78) + "`r") -NoNewline }

function LMStudioActivo {
    try {
        Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop "http://localhost:1234/v1/models" | Out-Null
        return $true
    } catch { return $false }
}

# Ejecuta docker con un indicador de progreso. Con -Silencioso no informa de los fallos.
function Esperar($texto, [string[]]$argumentos, [switch]$Silencioso) {
    $log = Join-Path $env:TEMP "bulkhead.log"
    $err = "$log.err"
    $vacio = "$log.in"
    Set-Content $vacio "" -NoNewline
    $p = Start-Process docker -ArgumentList $argumentos -NoNewWindow -PassThru `
        -RedirectStandardInput $vacio -RedirectStandardOutput $log -RedirectStandardError $err
    $null = $p.Handle
    $reloj = [Diagnostics.Stopwatch]::StartNew()
    $i = 0
    while (-not $p.HasExited) {
        Write-Host ("`r   {0}    {1}  {2:mm\:ss}" -f (Girar $i), $texto, $reloj.Elapsed) -ForegroundColor Cyan -NoNewline
        Start-Sleep -Milliseconds 120
        $i++
    }
    $p.WaitForExit()
    Limpiar
    if ($p.ExitCode -ne 0) {
        if (-not $Silencioso) {
            Fallo $texto
            Nota "Últimas líneas del registro:"
            Get-Content $log, $err -ErrorAction SilentlyContinue | Select-Object -Last 25 | ForEach-Object { Nota "  $_" }
        }
        return $false
    }
    Ok ("{0}  ({1:mm\:ss})" -f $texto, $reloj.Elapsed)
    return $true
}

function Esperar-Tecla($titulo, $detalle) {
    Write-Host ""
    Aviso $titulo
    foreach ($linea in @($detalle)) { Nota $linea }
    Write-Host ""
    $r = Leer "   Pulsa Enter para continuar"
    if ($null -eq $r) { exit 0 }
}

function Opcion($n, $titulo, $desc) {
    Write-Host "     $n  " -ForegroundColor Cyan -NoNewline
    Write-Host $titulo.PadRight(24) -NoNewline
    Write-Host $desc -ForegroundColor DarkGray
}

# ─── Proyectos ────────────────────────────────────────────────────────────────

function NombreCompose($p) { if ($p -eq "general") { return $Prefijo } else { return "$Prefijo-$p" } }
function Contenedor($p) { return "$(NombreCompose $p)-workspace-1" }

function NombreDeProyecto($compose) {
    if ($compose -eq $Prefijo) { return "general" }
    if ($compose -like "$Prefijo-*") { return $compose.Substring($Prefijo.Length + 1) }
    return $null
}

# Lista de proyectos a partir de Docker: cada proyecto es un volumen de código
# "<proyecto>_workspace". Del contenedor (si existe) salen el estado y los puertos.
function Proyectos {
    $contenedores = @{}
    $ids = @(Dock ps -aq --filter "label=com.docker.compose.service=workspace")
    if ($ids.Count -gt 0) {
        $json = (Dock inspect @ids) -join "`n"
        if ($json) {
            foreach ($c in @($json | ConvertFrom-Json)) {
                $p = NombreDeProyecto $c.Config.Labels.'com.docker.compose.project'
                if (-not $p) { continue }
                $desp = $null
                $b = $c.HostConfig.PortBindings.'3000/tcp'
                if ($b) { $desp = [int]$b[0].HostPort - 3000 }
                $contenedores[$p] = @{ Encendido = [bool]$c.State.Running; Desplazamiento = $desp }
            }
        }
    }
    $lista = @()
    foreach ($v in @(Dock volume ls -q --filter "label=com.docker.compose.volume=workspace")) {
        if ($v -notmatch "^$Prefijo(-(?<n>[a-z][a-z0-9-]*))?_workspace$") { continue }
        $n = if ($Matches.n) { $Matches.n } else { "general" }
        $c = $contenedores[$n]
        $lista += [pscustomobject]@{
            Nombre         = $n
            Encendido      = [bool]($c -and $c.Encendido)
            Desplazamiento = $(if ($c) { $c.Desplazamiento } else { $null })
        }
    }
    return @($lista | Sort-Object Nombre)
}

# Puertos del proyecto: los que ya tenga su contenedor o, si no, el primer hueco libre.
# El proyecto n usa 3000+n, 5173+n y 8080+n; "general" usa los puertos originales.
function Desplazamiento($p) {
    $lista = @(Proyectos)
    $actual = @($lista | Where-Object { $_.Nombre -eq $p -and $null -ne $_.Desplazamiento })
    if ($actual.Count -gt 0) { return $actual[0].Desplazamiento }
    if ($p -eq "general") { return 0 }
    $usados = @($lista | Where-Object { $null -ne $_.Desplazamiento } | ForEach-Object { $_.Desplazamiento })
    $n = 1
    while ($usados -contains $n) { $n++ }
    return $n
}

function Puertos($n) { return @((3000 + $n), (5173 + $n), (8080 + $n)) }

function Encender($p) {
    $pu = Puertos (Desplazamiento $p)
    $env:PROYECTO = $p
    $env:PUERTO_3000 = "$($pu[0])"
    $env:PUERTO_5173 = "$($pu[1])"
    $env:PUERTO_8080 = "$($pu[2])"
    $ok = Esperar "Encendiendo el proyecto $p" @("compose", "-p", (NombreCompose $p), "up", "-d", "--wait", "workspace")
    if (-not $ok) {
        Write-Host ""
        Nota "Causas habituales: un puerto ocupado ($($pu -join ', ')) o un problema del cortafuegos."
        Nota "Registro completo: docker logs $(Contenedor $p)"
    }
    return $ok
}

function Abrir($p, $titulo, [string[]]$comando) {
    $exec = @("exec", "-it", "-u", "node", "-w", "/workspace", (Contenedor $p)) + $comando
    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        & wt.exe -w 0 new-tab --title "$titulo ($p)" -d $PSScriptRoot docker @exec
        Ok "$titulo abierto en una pestaña nueva de esta ventana"
    } else {
        Start-Process docker -ArgumentList $exec -WorkingDirectory $PSScriptRoot
        Ok "$titulo abierto en una ventana nueva"
        Nota "Con Windows Terminal se abriría como pestaña: https://aka.ms/terminal"
    }
    Start-Sleep -Seconds 2
}

# Comando interactivo en esta misma ventana (iniciar sesión, clonar...).
function Aqui($p, [string[]]$comando) {
    & docker exec -it -u node -w /workspace (Contenedor $p) @comando
    return ($LASTEXITCODE -eq 0)
}

function AbrirVSCode($p) {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Esperar-Tecla "VS Code no está instalado" @(
            "Instálalo desde https://code.visualstudio.com (deja marcada la opción 'Agregar a PATH')",
            "y vuelve a elegir esta opción.")
        return
    }
    $c = Contenedor $p
    # VS Code se conecta al contenedor ya encendido. Esta configuración hace que
    # entre como el usuario node y abra /workspace.
    $config = '{ "workspaceFolder": "/workspace", "remoteUser": "node" }'
    $base = Join-Path $env:APPDATA "Code\User\globalStorage\ms-vscode-remote.remote-containers"
    $imagen = Dock inspect --format "{{.Config.Image}}" $c
    foreach ($par in @(@("imageConfigs", $imagen), @("nameConfigs", $c))) {
        if (-not $par[1]) { continue }
        $dir = Join-Path $base $par[0]
        New-Item -ItemType Directory -Force $dir | Out-Null
        [IO.File]::WriteAllText((Join-Path $dir ([uri]::EscapeDataString($par[1]).ToLower() + ".json")), $config, $utf8)
    }
    Paso "Abriendo VS Code..."
    Nota "La primera vez instala la extensión Dev Containers y tarda un poco más."
    & code --install-extension ms-vscode-remote.remote-containers *> $null
    $hex = -join ([Text.Encoding]::UTF8.GetBytes($c) | ForEach-Object { $_.ToString("x2") })
    & code --folder-uri "vscode-remote://attached-container+$hex/workspace"
    Ok "VS Code abierto en el proyecto $p"
    Start-Sleep -Seconds 2
}

function MenuProyecto($p) {
    if (-not (Encender $p)) { Esperar-Tecla "No se pudo encender el proyecto $p" "Revisa los mensajes de arriba."; return }
    $pu = Puertos (Desplazamiento $p)
    $c = Contenedor $p
    while ($true) {
        Banner
        Write-Host ""
        Write-Host "   Comprobando el estado..." -ForegroundColor DarkGray -NoNewline
        $estado = (Dock exec -u node $c ia --estado) -split "\|"
        Limpiar
        $modelo = if ($estado.Count -ge 1 -and $estado[0]) { $estado[0] } else { "desconocido" }
        $api    = if ($estado.Count -ge 2 -and $estado[1]) { $estado[1] } else { "desconocido" }
        $gh     = if ($estado.Count -ge 3 -and $estado[2]) { $estado[2] } else { "" }
        $hayModelo = $modelo -notin @("sin servidor", "sin modelo cargado", "desconocido")
        $hayApi = $api -eq "configurada"

        Write-Host "   PROYECTO  " -ForegroundColor DarkCyan -NoNewline
        Write-Host $p -ForegroundColor White
        Write-Host ""
        Write-Host "   Navegador       " -ForegroundColor DarkGray -NoNewline
        Write-Host ("http://localhost:{0}   :{1}   :{2}" -f $pu[0], $pu[1], $pu[2])
        Nota "        (dentro del proyecto son los puertos 3000, 5173 y 8080)"
        Write-Host "   GitHub          " -ForegroundColor DarkGray -NoNewline
        if ($gh) { Write-Host "conectado como $gh" -ForegroundColor Green } else { Write-Host "sin conectar (opción 6)" -ForegroundColor DarkGray }
        Write-Host "   Modelo local    " -ForegroundColor DarkGray -NoNewline
        Write-Host $modelo -ForegroundColor $(if ($hayModelo) { "Green" } else { "DarkGray" })
        Write-Host "   API Anthropic   " -ForegroundColor DarkGray -NoNewline
        Write-Host $api -ForegroundColor $(if ($hayApi) { "Green" } else { "DarkGray" })

        Seccion "TRABAJAR CON IA"
        Opcion 1 "Claude Code"          "Con tu cuenta de Claude (Pro, Max o Team)"
        Opcion 2 "Claude Code autónomo" "No pide permiso. Solo con proyectos y repositorios de confianza"
        Opcion 3 "OpenCode local"       "Con tu modelo de LM Studio o llama.cpp. Gratis; el modelo corre en tu PC"
        Seccion "HERRAMIENTAS"
        Opcion 4 "Terminal"             "Línea de comandos del proyecto: git, gh, npm, python..."
        Opcion 5 "VS Code"              "Abre el proyecto en el editor"
        Opcion 6 "Conectar GitHub"      "Para descargar repositorios privados y subir cambios"
        Seccion "AVANZADO"
        Opcion 7 "Claude Code con API"  "Pago por uso. Necesita ANTHROPIC_API_KEY en .env"
        Opcion 8 "Modelos locales"      "Lista los modelos de LM Studio o llama.cpp"
        Write-Host ""
        Opcion 0 "Volver a proyectos"   "El proyecto sigue encendido"
        Write-Host ""
        Nota "Cada herramienta se abre en una pestaña nueva y este menú sigue aquí."
        Write-Host ""
        $op = Leer "   Elige una opción y pulsa Enter"
        if ($null -eq $op) { exit 0 }

        switch ($op.Trim()) {
            ""  { }
            "1" { Abrir $p "Claude Code" @("ia", "claude") }
            "2" { Abrir $p "Claude Code autónomo" @("ia", "auto") }
            "3" {
                if ($hayModelo) { Abrir $p "OpenCode local" @("ia", "local") }
                elseif ($LlamaCpp) { Esperar-Tecla "El modelo local aún no está listo" "llama.cpp puede estar descargando el modelo. Míralo con: docker compose logs -f llamacpp" }
                else { Esperar-Tecla "No hay modelo local" "Abre LM Studio, carga un modelo y pulsa Developer -> Start Server." }
            }
            "4" { Abrir $p "Terminal" @("bash") }
            "5" { AbrirVSCode $p }
            "6" {
                Write-Host ""
                [void](Aqui $p @("ia", "github"))
                Leer "   Pulsa Enter para volver al menú" | Out-Null
            }
            "7" {
                if ($hayApi) { Abrir $p "Claude Code (API)" @("ia", "claude-api") }
                else { Esperar-Tecla "Falta la clave de API" "Añade ANTHROPIC_API_KEY=tu-clave en el archivo .env de esta carpeta y vuelve a ejecutar iniciar.cmd." }
            }
            "8" {
                Paso "Modelos disponibles"
                Dock exec -u node $c ia modelos | ForEach-Object { Nota $_ }
                Write-Host ""
                Leer "   Pulsa Enter para volver al menú" | Out-Null
            }
            "0" { return }
            default { Esperar-Tecla "Opción no válida: '$op'" "Escribe un número del 0 al 8 y pulsa Enter." }
        }
    }
}

function NuevoProyecto {
    Banner
    Paso "NUEVO PROYECTO"
    Nota "Cada proyecto tiene su propio contenedor: sus archivos, sus puertos, sus"
    Nota "sesiones y su historial de git. Los agentes de un proyecto no ven los de otro."
    Write-Host ""
    Nota "Nombre corto en minúsculas, sin espacios ni tildes. Ejemplos: web, tienda, mi-app"
    $nombre = Leer "   Nombre (Enter para cancelar)"
    if ($null -eq $nombre) { exit 0 }
    $nombre = $nombre.Trim().ToLower()
    if (-not $nombre) { return }
    if ($nombre -notmatch $NombreValido -or $nombre -eq "general") {
        Esperar-Tecla "Nombre no válido: '$nombre'" "Usa letras minúsculas, números y guiones, empezando por una letra (máximo 30)."
        return
    }
    if (@(Proyectos | Where-Object { $_.Nombre -eq $nombre }).Count -gt 0) {
        Esperar-Tecla "Ya existe un proyecto llamado '$nombre'" "Elige otro nombre."
        return
    }

    Write-Host ""
    Nota "¿Partes de un repositorio que ya existe? Pega su dirección"
    Nota "(por ejemplo https://github.com/usuario/repo) o pulsa Enter para empezar de cero."
    $url = Leer "   Repositorio"
    if ($null -eq $url) { exit 0 }
    $url = $url.Trim()
    Write-Host ""

    if (-not (Encender $nombre)) { Esperar-Tecla "No se pudo crear el proyecto" "Revisa los mensajes de arriba."; return }

    # Cada proyecto tiene su carpeta personal y sus sesiones, y su propia conexión con GitHub.
    if (-not (Aqui $nombre @("ia", "preparar", $url)) -and $url) {
        Write-Host ""
        $r = Leer "   ¿Conectar tu cuenta de GitHub y volver a intentarlo? (S/n)"
        if ($null -eq $r) { exit 0 }
        if ($r.Trim() -notmatch '^[nN]') {
            Write-Host ""
            if (Aqui $nombre @("ia", "github", "--de-nuevo")) { [void](Aqui $nombre @("ia", "preparar", $url)) }
        }
    }
    Write-Host ""
    Leer "   Pulsa Enter para abrir el proyecto" | Out-Null
    MenuProyecto $nombre
}

function BorrarProyecto($lista) {
    Banner
    Paso "BORRAR UN PROYECTO"
    Nota "Se borran el contenedor, todos los archivos del proyecto y sus sesiones."
    Nota "No se puede deshacer."
    Nota "Lo que esté subido a GitHub no se pierde."
    Write-Host ""
    $p = Leer "   Nombre del proyecto (Enter para cancelar)"
    if ($null -eq $p) { exit 0 }
    $p = $p.Trim().ToLower()
    if (-not $p) { return }
    if (@($lista | Where-Object { $_.Nombre -eq $p }).Count -eq 0) { Esperar-Tecla "No hay ningún proyecto llamado '$p'" ""; return }

    Write-Host ""
    if (Encender $p) {
        $pendiente = @(Dock exec -u node (Contenedor $p) ia pendiente)
        if ($pendiente.Count -gt 0) {
            Write-Host ""
            Aviso "Este proyecto tiene trabajo que se perdería:"
            foreach ($l in $pendiente) { Nota "- $l" }
            Nota "Para guardarlo, pídele a Claude Code: 'sube todos los cambios a GitHub'."
        }
    }
    Write-Host ""
    $conf = Leer "   Para confirmar, escribe otra vez el nombre del proyecto"
    if ($null -eq $conf) { exit 0 }
    if ($conf.Trim().ToLower() -ne $p) { Esperar-Tecla "Cancelado" "No se ha borrado nada."; return }

    # Nunca "docker compose down -v": borraría también las sesiones y los modelos compartidos.
    Dock rm -f (Contenedor $p) | Out-Null
    Dock volume rm "$(NombreCompose $p)_workspace" | Out-Null
    Dock volume rm "$(NombreCompose $p)_home" | Out-Null
    Ok "Proyecto $p borrado"
    Start-Sleep -Seconds 2
}

function ContenedoresEncendidos {
    return @(Dock ps --format "{{.ID}} {{.Names}}" | Where-Object { $_ -match " $Prefijo(-[a-z0-9-]+)?-(workspace|llamacpp|openwebui)-\d+$" } | ForEach-Object { ($_ -split " ")[0] })
}

# Open WebUI: chat con el modelo local en el navegador. Uno para todos los proyectos.
function AbrirOpenWebUI {
    Banner
    Paso "OPEN WEBUI"
    Nota "Chat con tu modelo local en el navegador. No es un agente: no ve tus proyectos."
    Nota "La primera vez descarga Open WebUI (varios GB) y pide crear una cuenta, que se"
    Nota "guarda solo en este PC."
    Write-Host ""
    $ok = Esperar "Encendiendo Open WebUI" (@("compose") + $Profiles + @("--profile", "openwebui", "up", "-d", "--wait", "openwebui"))
    if (-not $ok) {
        Esperar-Tecla "No se pudo encender Open WebUI" @("Causa habitual: el puerto 3100 está ocupado por otro programa.", "Registro completo: docker compose logs openwebui")
        return
    }
    Start-Process "http://localhost:3100"
    Ok "Abierto en el navegador: http://localhost:3100"
    if (-not $LlamaCpp -and -not (LMStudioActivo)) { Aviso "LM Studio no responde: Open WebUI no verá ningún modelo hasta que lo arranques" }
    Start-Sleep -Seconds 3
}

function PararTodo {
    $ids = ContenedoresEncendidos
    Write-Host ""
    if ($ids.Count -gt 0) { [void](Esperar "Apagando $($ids.Count) contenedor(es)" (@("stop") + $ids)) }
    Ok "Todo apagado. Para volver, ejecuta iniciar.cmd"
    Start-Sleep -Seconds 3
}

# ─── Imagen ───────────────────────────────────────────────────────────────────

function Imagen {
    $i = @(Dock compose config --images | Where-Object { $_ -notmatch "llama" })
    if ($i.Count -gt 0) { return $i[0] }
    return "ghcr.io/abarriuso/bulkhead:$VersionImagen"
}

function VersionDe($imagen) {
    $v = Dock image inspect --format '{{index .Config.Labels `bulkhead.version`}}' $imagen
    if ($LASTEXITCODE -ne 0) { return $null }
    return "$v".Trim()
}

# Descarga la imagen publicada; si no se puede (o es de otra versión), la construye aquí.
function PrepararImagen([switch]$Actualizar) {
    $img = Imagen
    if (-not $Actualizar -and (VersionDe $img) -eq $VersionImagen) { Ok "Imagen del entorno lista"; return $true }
    Nota "Descarga Claude Code, OpenCode y las herramientas (cerca de 1 GB la primera vez)."
    $descargada = Esperar "Descargando el entorno" @("compose", "pull", "workspace") -Silencioso
    # Al actualizar, la imagen que ya había no vale: hay que haberla descargado.
    if (($descargada -or -not $Actualizar) -and (VersionDe $img) -eq $VersionImagen) { Ok "Imagen del entorno lista"; return $true }
    Nota "No hay una versión publicada compatible: se construye en este PC (5-10 minutos)."
    $build = @("compose", "build", "--pull", "workspace")
    if ($Actualizar) { $build = @("compose", "build", "--pull", "--no-cache", "workspace") }
    return (Esperar "Construyendo el entorno" $build)
}

function Actualizar {
    Banner
    Paso "ACTUALIZAR EL ENTORNO"
    Nota "Descarga las últimas versiones de Claude Code, OpenCode y las herramientas."
    Nota "Tus proyectos y sesiones no se tocan."
    Write-Host ""
    if (-not (PrepararImagen -Actualizar)) { Esperar-Tecla "No se pudo actualizar" "Revisa los mensajes de arriba."; return }
    if ($LlamaCpp) { [void](Esperar "Actualizando llama.cpp" @("compose", "--profile", "llamacpp", "pull", "llamacpp")) }
    foreach ($pr in @(Proyectos | Where-Object { $_.Encendido })) { [void](Encender $pr.Nombre) }
    Esperar-Tecla "Entorno actualizado" "Las herramientas que ya estaban abiertas usan la versión anterior hasta que las cierres."
}

function MenuProyectos {
    while ($true) {
        Banner
        $lista = @(Proyectos)
        Seccion "TUS PROYECTOS"
        if ($lista.Count -eq 0) {
            Nota "Todavía no tienes ninguno. Crea el primero con la opción N."
        }
        for ($i = 0; $i -lt $lista.Count; $i++) {
            $pr = $lista[$i]
            Write-Host "     $($i + 1)  " -ForegroundColor Cyan -NoNewline
            Write-Host $pr.Nombre.PadRight(24) -NoNewline
            if ($pr.Encendido) {
                Write-Host "encendido" -ForegroundColor Green -NoNewline
                if ($null -ne $pr.Desplazamiento) { Write-Host ("   http://localhost:{0}" -f (Puertos $pr.Desplazamiento)[0]) -ForegroundColor DarkGray } else { Write-Host "" }
            } else {
                Write-Host "apagado" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
        Opcion "N" "Nuevo proyecto"       "Vacío o a partir de un repositorio de GitHub"
        Opcion "B" "Borrar un proyecto"   "Avisa si hay cambios sin subir a GitHub"
        Opcion "W" "Open WebUI"           "Chat con tu modelo local en el navegador"
        Opcion "A" "Actualizar"           "Últimas versiones de Claude Code y OpenCode"
        Opcion "P" "Apagar todo"          "Apaga todos los proyectos. No se pierde nada"
        Opcion "0" "Salir"                "Los proyectos encendidos siguen funcionando"
        Write-Host ""
        $op = Leer "   Elige un proyecto (número) o una opción (letra) y pulsa Enter"
        if ($null -eq $op) { return }
        $op = $op.Trim()
        $num = 0
        if ([int]::TryParse($op, [ref]$num) -and $num -ge 1 -and $num -le $lista.Count) {
            MenuProyecto $lista[$num - 1].Nombre
            continue
        }
        switch ($op.ToUpper()) {
            ""  { }
            "N" { NuevoProyecto }
            "B" { if ($lista.Count -gt 0) { BorrarProyecto $lista } else { Esperar-Tecla "No hay proyectos que borrar" "" } }
            "W" { AbrirOpenWebUI }
            "A" { Actualizar }
            "P" { PararTodo; return }
            "0" {
                Write-Host ""
                Nota "Los proyectos encendidos siguen funcionando. Para volver, ejecuta iniciar.cmd"
                return
            }
            default { Esperar-Tecla "Opción no válida: '$op'" "Escribe el número de un proyecto o una de las letras y pulsa Enter." }
        }
    }
}

# ─── Arranque ─────────────────────────────────────────────────────────────────

Banner

Paso "1/4  Comprobando la instalación"
if (-not (Test-Path (Join-Path $PSScriptRoot "docker-compose.yml"))) {
    Fallo "Faltan archivos junto a este script"
    Nota "Parece que lo has abierto desde dentro del ZIP sin extraerlo."
    Nota "Clic derecho en el ZIP -> Extraer todo, y ejecuta iniciar.cmd desde la carpeta extraída."
    exit 1
}
Ok "Archivos del proyecto"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fallo "Docker no está instalado (o esta terminal no lo encuentra)"
    Nota "Instálalo desde https://www.docker.com/products/docker-desktop/"
    Nota "Si acabas de instalarlo, reinicia el ordenador y vuelve a ejecutar iniciar.cmd."
    exit 1
}
Ok "Docker instalado"

Paso "2/4  Comprobando Docker Desktop"
$osType = $null | docker info --format "{{.OSType}}" 2> $null
if ($LASTEXITCODE -ne 0) {
    # Instalación para todos los usuarios o solo para el actual.
    $exe = @((Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"),
             (Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\Docker Desktop.exe")) |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) {
        Nota "Docker Desktop no está abierto. Abriéndolo..."
        Nota "La primera vez puede tardar un par de minutos."
        Start-Process $exe
        $reloj = [Diagnostics.Stopwatch]::StartNew()
        $i = 0
        do {
            Write-Host ("`r   {0}    Esperando a Docker Desktop  {1:mm\:ss}" -f (Girar $i), $reloj.Elapsed) -ForegroundColor Cyan -NoNewline
            Start-Sleep -Seconds 2
            $i++
            $osType = $null | docker info --format "{{.OSType}}" 2> $null
        } while ($LASTEXITCODE -ne 0 -and $reloj.Elapsed.TotalSeconds -lt 240)
        Limpiar
    }
    if ($LASTEXITCODE -ne 0) {
        Fallo "Docker Desktop no responde"
        Nota "Ábrelo desde el menú Inicio y espera a que abajo a la izquierda ponga 'Engine running'."
        Nota "Si muestra un error de virtualización o de WSL, consulta INSTALACION.md (Problemas de instalación)."
        exit 1
    }
}
if ($osType -ne "linux") {
    Fallo "Docker está en modo 'contenedores de Windows'"
    Nota "Clic derecho en el icono de Docker (junto al reloj) -> 'Switch to Linux containers'."
    exit 1
}
Ok "Docker Desktop en marcha"

Paso "3/4  Preparando la configuración"
$envPath = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envPath)) {
    Copy-Item (Join-Path $PSScriptRoot ".env.example") $envPath -ErrorAction Stop
    Ok "Archivo de configuración creado (.env)"
    Nota "Ahí puedes poner tu clave de API, tu nombre para git y más. Ver MANUAL.md."
} else {
    Ok "Archivo de configuración (.env)"
}

# LOCAL_URL: LM Studio o llama.cpp según cómo se arranque. Un valor puesto a mano en .env
# (por ejemplo Ollama: http://host.docker.internal:11434) se respeta.
$envText = [IO.File]::ReadAllText($envPath, $utf8) -replace "`r`n", "`n"
$urlActual = ""
if ($envText -match "(?m)^LOCAL_URL=(.*)$") { $urlActual = $Matches[1].Trim() }
$urlPorDefecto = @("", "http://host.docker.internal:1234", "http://llamacpp:8080", "http://llamacpp:8090")
$url = if ($LlamaCpp) { "http://llamacpp:8090" } elseif ($urlPorDefecto -contains $urlActual) { "http://host.docker.internal:1234" } else { $urlActual }
if ($envText -match "(?m)^LOCAL_URL=") {
    $envText = $envText -replace "(?m)^LOCAL_URL=.*$", "LOCAL_URL=$url"
} else {
    if ($envText.Length -gt 0 -and -not $envText.EndsWith("`n")) { $envText += "`n" }
    $envText += "LOCAL_URL=$url`n"
}
# docker-compose.yml entrega la clave como secreto y Compose exige que la variable exista.
if ($envText -notmatch "(?m)^[ \t]*(export[ \t]+)?ANTHROPIC_API_KEY[ \t]*[=:]") {
    if ($envText.Length -gt 0 -and -not $envText.EndsWith("`n")) { $envText += "`n" }
    $envText += "ANTHROPIC_API_KEY=`n"
}
[IO.File]::WriteAllText($envPath, $envText, $utf8)

# La clave solo se toma de .env, no de una variable ANTHROPIC_API_KEY de Windows.
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
# Compose no recrea un contenedor si solo cambia un secreto: una huella de la clave en
# una etiqueta hace que el proyecto se recree cuando se añade o cambia la clave.
$clave = "$(@(Dock compose config --environment) | Where-Object { $_ -like 'ANTHROPIC_API_KEY=*' } | Select-Object -First 1)"
$clave = $clave -replace "^ANTHROPIC_API_KEY=", ""
$env:CLAVE_HUELLA = ""
if ($clave) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $env:CLAVE_HUELLA = (-join ($sha.ComputeHash($utf8.GetBytes($clave)) | ForEach-Object { $_.ToString("x2") })).Substring(0, 16)
}

if ($LlamaCpp) {
    Ok "Modelo local: llama.cpp (dentro de Docker)"
    if (LMStudioActivo) { Aviso "LM Studio también está abierto y puede quitarle memoria de la GPU a llama.cpp" }
} elseif ($url -ne "http://host.docker.internal:1234") {
    Ok "Modelo local: $url (definido en .env)"
    $null | docker compose --profile llamacpp stop llamacpp *> $null
} else {
    if (LMStudioActivo) { Ok "Modelo local: LM Studio" }
    else { Nota "LM Studio no está abierto: no pasa nada, solo hace falta para OpenCode local y Open WebUI." }
    $null | docker compose --profile llamacpp stop llamacpp *> $null
}

Paso "4/4  Preparando el entorno"
if (-not (PrepararImagen)) {
    Write-Host ""
    Nota "Causas habituales: sin conexión a internet o poco espacio en disco."
    exit 1
}
if ($LlamaCpp) {
    if (-not (Esperar "Arrancando llama.cpp" (@("compose") + $Profiles + @("up", "-d", "llamacpp")))) {
        Nota "Comprueba que Docker ve la tarjeta gráfica NVIDIA (ver MANUAL.md, Modelo local)."
        exit 1
    }
    Nota "llama.cpp descarga el modelo en el primer arranque: docker compose logs -f llamacpp"
}

Start-Sleep -Seconds 1
MenuProyectos
