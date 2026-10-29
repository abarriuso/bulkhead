# Instalación

1. [Requisitos](#requisitos)
2. [Instalación sencilla](#instalación-sencilla)
3. [Instalación avanzada](#instalación-avanzada)

## Requisitos

### Para usar Claude (lo básico)

| | Mínimo | Recomendado |
|---|---|---|
| Sistema | Windows 10 de 64 bits versión 22H2, o Windows 11 versión 23H2 o posterior (Home o Pro) | Windows 11 |
| Memoria RAM | 8 GB | 16 GB |
| Espacio libre en disco | 15 GB | 30 GB |
| Procesador | Con virtualización (casi todos desde 2015) | — |
| Internet | Necesario | — |
| Cuenta | Claude **Pro, Max o Team**, o una clave de API de Anthropic | No hace falta con un modelo local |

El plan gratuito de Claude no incluye Claude Code. Sin cuenta de pago se puede usar un modelo local, con OpenCode u Open WebUI (ver más abajo).

Docker Desktop es gratuito para uso personal, educativo y empresas de menos de 250 empleados y menos de 10 millones de dólares de facturación anual. Por encima, necesita licencia de pago.

**Cómo saber la versión de Windows:** tecla Windows + R → escribir `winver` → Enter.

**Cómo saber la RAM:** Configuración → Sistema → Información → *RAM instalada*.

**Cómo saber si la virtualización está activada:** Administrador de tareas (Ctrl + Mayús + Esc) → *Rendimiento* → *CPU* → **Virtualización: Habilitada**. Si pone *Deshabilitada*, hay que activarla en la BIOS: es el único paso que puede necesitar ayuda técnica.

### Para usar un modelo local (opcional)

| | Mínimo | Recomendado |
|---|---|---|
| Tarjeta gráfica | NVIDIA con 6 GB de memoria | NVIDIA con 12 GB o más |
| Memoria RAM | 16 GB | 32 GB |
| Espacio libre adicional | 10 GB | 30 GB |

Sin tarjeta NVIDIA se puede usar todo lo demás con normalidad.

## Instalación sencilla

Sin comandos. Tiempo total: unos 20 minutos.

### Paso 1. Instalar Docker Desktop

1. Entrar en https://www.docker.com/products/docker-desktop/ y pulsar **Download for Windows**.
2. Abrir el archivo descargado y pulsar *OK* hasta terminar.
3. **Reiniciar el ordenador.**
4. Abrir **Docker Desktop** desde el menú Inicio y aceptar los términos. No hace falta crear cuenta: se puede pulsar *Skip*.
5. Si pide instalar o actualizar **WSL**, pulsar el botón que aparece y reiniciar si lo pide.
6. Esperar a que abajo a la izquierda aparezca **Engine running** en verde.

### Paso 2. Descargar el programa

1. Entrar en https://github.com/abarriuso/bulkhead
2. Botón verde **Code** → **Download ZIP**.
3. Clic derecho en el ZIP descargado → **Extraer todo** → **Extraer**.

### Paso 3. Arrancar

1. Abrir la carpeta extraída.
2. **Doble clic en `iniciar.cmd`.**
3. Si aparece *"Windows protegió su PC"*: **Más información** → **Ejecutar de todas formas**.
4. Esperar a que aparezca el menú. La primera vez descarga el entorno (cerca de 1 GB) y tarda unos minutos.

### Paso 4. Crear el primer proyecto

1. En el menú, escribir **N** y pulsar Enter.
2. Escribir un nombre corto, por ejemplo `prueba`.
3. Pulsar Enter para empezar un proyecto vacío (o pegar la dirección de un repositorio de GitHub).

Cada proyecto tiene su propio contenedor, con sus archivos separados de los demás.

### Paso 5. Iniciar sesión en Claude

1. En el menú del proyecto, escribir **1** (Claude Code) y pulsar Enter. Se abre en una pestaña nueva.
2. Aparece un enlace: copiarlo, abrirlo en el navegador e iniciar sesión con la cuenta de Claude.
3. Copiar el código que muestra la web y pegarlo en la ventana negra (clic derecho para pegar).

Cada proyecto tiene su propia sesión: en cada proyecto nuevo, Claude Code pedirá iniciar sesión la primera vez.

**¿Sin cuenta de pago de Claude?** Con una tarjeta gráfica NVIDIA puedes usar un modelo local: ver [Modelo local con LM Studio](#modelo-local-con-lm-studio).

### Las siguientes veces

1. Abrir **Docker Desktop** y esperar a *Engine running*.
2. **Doble clic en `iniciar.cmd`** y elegir el proyecto por su número.

Para aprender a trabajar con los agentes: [Cómo trabajar con agentes](GUIA-AGENTES.md).

## Instalación avanzada

### Instalar con comandos

En PowerShell como administrador:

```powershell
wsl --install
winget install -e --id Docker.DockerDesktop
winget install -e --id Git.Git
```

Reiniciar, abrir Docker Desktop y esperar a *Engine running*. Después, en PowerShell normal:

```powershell
cd $HOME\Documents
git clone https://github.com/abarriuso/bulkhead.git
cd bulkhead
.\iniciar.cmd
```

Con Git se puede actualizar más adelante con `git pull`.

### Configuración opcional

Editar el fichero `.env` de la carpeta (se crea en el primer arranque) y volver a ejecutar `iniciar.cmd`:

| Variable | Para qué |
|---|---|
| `ANTHROPIC_API_KEY` | Usar Claude Code con clave de API (opción 7) |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git dentro del contenedor |

Resto de variables: [manual de uso](MANUAL.md#9-configuración).

### Modelo local con LM Studio

1. Actualizar el driver de NVIDIA: https://www.nvidia.com/Download/index.aspx
2. Instalar LM Studio 0.4.1 o superior: https://lmstudio.ai (o `winget install -e --id ElementLabs.LMStudio`).
3. *Discover* → descargar un modelo ([modelos recomendados](MANUAL.md#modelos-recomendados)).
4. Cargarlo con contexto **32768** y *GPU offload* al máximo.
5. *Developer* → **Start Server**.
6. Doble clic en `iniciar.cmd`. Para un agente en el proyecto, opción **3** (OpenCode local); para un chat en el navegador, opción **W** (Open WebUI) de la pantalla principal.

### Modelo local con llama.cpp (sin LM Studio)

1. Actualizar el driver de NVIDIA y reiniciar Docker Desktop.
2. Comprobar que Docker ve la tarjeta gráfica:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
3. Elegir el modelo en `.env` (`LLAMACPP_HF_REPO`, ver [modelos recomendados](MANUAL.md#modelos-recomendados)).
4. Arrancar:
   ```powershell
   .\iniciar.cmd -LlamaCpp
   ```
5. El primer arranque descarga el modelo. Ver el progreso con `docker compose logs -f llamacpp`. En el menú del proyecto, opción **3**.

### Problemas de instalación

| Problema | Solución |
|---|---|
| Docker Desktop no arranca o habla de virtualización | Activar la virtualización en la BIOS (*Intel VT-x* o *AMD-V / SVM*) |
| Docker Desktop pide WSL | `wsl --update` en PowerShell como administrador y reiniciar |
| `access denied` al usar Docker | `net localgroup docker-users "$env:USERNAME" /add` como administrador y cerrar sesión |
| `failed to connect to the docker API` | Abrir Docker Desktop y esperar a *Engine running* |

Más problemas: [manual de uso](MANUAL.md#12-solución-de-problemas).
