# Manual de uso

1. [Requisitos](#1-requisitos)
2. [Instalación](#2-instalación)
3. [Arranque](#3-arranque)
4. [Proyectos](#4-proyectos)
5. [Menú del proyecto](#5-menú-del-proyecto)
6. [Primer uso](#6-primer-uso)
7. [Uso diario](#7-uso-diario)
8. [Modelo local](#8-modelo-local)
9. [Configuración](#9-configuración)
10. [Seguridad](#10-seguridad)
11. [Actualizar, parar y borrar](#11-actualizar-parar-y-borrar)
12. [Solución de problemas](#12-solución-de-problemas)

## 1. Requisitos

| Requisito | Notas |
|---|---|
| Windows 10 22H2 o Windows 11 23H2 (Home o Pro) | Con la virtualización activada en la BIOS. Detalle en [INSTALACION.md](INSTALACION.md#requisitos) |
| Docker Desktop | Con *Use WSL 2 based engine* activado (viene así por defecto) |
| Cuenta de Claude (Pro, Max o Team) o clave de API | Para Claude Code. OpenCode con modelo local funciona sin ellas |
| GPU NVIDIA con driver actualizado | Solo para el modelo local |
| LM Studio 0.4.1 o superior | Solo si el modelo local se sirve con LM Studio |
| VS Code | Opcional, para la opción *VS Code* del menú |

No hace falta instalar Git, Node.js, Python ni ninguna herramienta más: están dentro del entorno.

## 2. Instalación

Instalación completa desde cero: [INSTALACION.md](INSTALACION.md).

Con Git:

```powershell
git clone https://github.com/abarriuso/claude-code-local-llm-docker.git
cd claude-code-local-llm-docker
```

Sin Git: en GitHub, *Code → Download ZIP*, y descomprimir.

## 3. Arranque

1. Abrir Docker Desktop y esperar a *Engine running*.
2. Ejecutar `iniciar.cmd` (doble clic o desde la terminal):

```powershell
.\iniciar.cmd              # modelo local en LM Studio, o sin modelo local
.\iniciar.cmd -LlamaCpp    # modelo local en llama.cpp (Docker)
```

El script comprueba la instalación, abre Docker Desktop si está cerrado, crea `.env` si no existe y prepara el entorno: descarga la imagen ya construida o, si no puede, la construye en el PC (5-10 minutos la primera vez). Después muestra los proyectos.

## 4. Proyectos

Cada proyecto vive en **su propio contenedor**, con sus archivos, su historial de git, sus puertos y su **carpeta personal**: las sesiones de Claude, OpenCode y GitHub, la configuración de los agentes y VS Code. Un agente que trabaja en un proyecto no puede ver ni tocar los demás, ni dejar en su configuración algo que afecte a otro.

Lo que comparten todos los proyectos:

- La imagen (Claude Code, OpenCode y las herramientas): se descarga una sola vez.
- Los modelos de llama.cpp.

La pantalla principal de `iniciar.cmd`:

```
   TUS PROYECTOS
     1  tienda                  apagado
     2  web                     encendido   http://localhost:3001

     N  Nuevo proyecto          Vacío o a partir de un repositorio de GitHub
     B  Borrar un proyecto      Avisa si hay cambios sin subir a GitHub
     A  Actualizar              Últimas versiones de Claude Code y OpenCode
     P  Apagar todo             Apaga todos los proyectos. No se pierde nada
     0  Salir                   Los proyectos encendidos siguen funcionando
```

- **Abrir un proyecto:** escribir su número. Si estaba apagado, se enciende en unos segundos.
- **Nuevo proyecto (N):** pide un nombre (minúsculas, números y guiones) y, opcionalmente, la dirección de un repositorio. Después ofrece **copiar de otro proyecto** su conexión con GitHub (el proyecto nuevo tendrá acceso a los mismos repositorios). Copia solo de proyectos de confianza. El inicio de sesión de Claude no se copia: Claude Code lo pide la primera vez en cada proyecto. Si el repositorio es privado y GitHub no está conectado, ofrece conectarlo. Un proyecto vacío empieza con git y un `CLAUDE.md` de plantilla para los agentes.
- **Borrar (B):** borra el contenedor, los archivos y las sesiones del proyecto. Antes avisa si hay cambios sin guardar o sin subir a GitHub, y pide escribir el nombre otra vez.

**Puertos:** dentro de cada proyecto los servidores de desarrollo usan siempre 3000, 5173 y 8080. En Windows, cada proyecto los publica en puertos distintos para que puedan funcionar a la vez: el primer proyecto en 3001, 5174 y 8081, el segundo en 3002, 5175 y 8082, etc. El menú del proyecto muestra sus direcciones.

**Proyecto `general`:** si usabas una versión anterior de este repositorio, tus archivos de `/workspace` aparecen como el proyecto `general`, con los puertos de siempre (3000, 5173, 8080).

## 5. Menú del proyecto

Las herramientas se abren en una **pestaña nueva** de Windows Terminal (o en una ventana nueva si no está instalado) y el menú sigue disponible, así se pueden usar varias a la vez.

| Opción | Qué abre |
|---|---|
| **Trabajar con IA** | |
| 1 Claude Code | Claude Code con tu cuenta de Claude. Pide permiso antes de cada cambio o comando |
| 2 Claude Code autónomo | Claude Code sin pedir permiso (`--dangerously-skip-permissions`). Más rápido, pero úsalo solo con proyectos y repositorios de confianza: el aislamiento protege tu PC, no impide que unas instrucciones ocultas en un archivo o una web engañen al agente. No funciona con `FIREWALL=off`. Revisa los cambios al final con git |
| 3 OpenCode local | OpenCode con el modelo de LM Studio o llama.cpp. Gratis; el modelo corre en tu PC. Como Claude Code, pide permiso antes de editar o ejecutar comandos |
| **Herramientas** | |
| 4 Terminal | Línea de comandos del proyecto (git, gh, npm, python…) |
| 5 VS Code | Abre el proyecto en VS Code, conectado al contenedor. Instala sola la extensión *Dev Containers* |
| 6 Conectar GitHub | Conecta GitHub en este proyecto. Necesario para repositorios privados y para subir cambios. **Rápido:** un código de un solo uso, con acceso a todos tus repositorios. **Limitado:** un token que creas en GitHub solo para el repositorio del proyecto; recomendado con el modo autónomo o con repositorios ajenos |
| **Avanzado** | |
| 7 Claude Code con API | Claude Code pagando por uso con `ANTHROPIC_API_KEY` |
| 8 Modelos locales | Lista los modelos disponibles en LM Studio o llama.cpp |
| 0 Volver | Vuelve a la lista de proyectos. El proyecto sigue encendido |

Dentro del proyecto (en la terminal o en VS Code) existe el mismo menú en modo texto: `ia`. También se puede usar con nombres:

```bash
ia claude        # Claude Code
ia auto          # Claude Code autónomo
ia local         # OpenCode con el modelo local
ia github        # conectar GitHub
ia claude -c     # los argumentos extra pasan a la herramienta (aquí: continuar la última conversación)
ia -h            # ayuda
```

## 6. Primer uso

1. `iniciar.cmd` → **N** → nombre del proyecto → Enter (vacío) o la dirección de un repositorio.
2. En el menú del proyecto, **1** (Claude Code). La primera vez muestra una URL de inicio de sesión: abrirla en el navegador de Windows, iniciar sesión y pegar el código.
3. Para subir el trabajo a GitHub: opción **6** (Conectar GitHub), una vez en cada proyecto.

Las sesiones de Claude Code, OpenCode y GitHub se conservan entre reinicios. Son de cada proyecto: al crear otro, Claude Code vuelve a pedir iniciar sesión, y el menú ofrece copiar la conexión con GitHub.

Los agentes leen el archivo `CLAUDE.md` del proyecto al empezar: rellénalo (o pídeles que lo hagan con `/init`). Además conocen las reglas del entorno (puertos, cortafuegos, sin `sudo`) sin que haya que explicárselas. Más consejos en [Cómo trabajar con agentes](GUIA-AGENTES.md).

## 7. Uso diario

Con Docker Desktop abierto: ejecutar `iniciar.cmd` y elegir el proyecto. Si el entorno ya está preparado, tarda segundos.

Sin el menú, desde la carpeta del repositorio:

```powershell
docker exec -it -u node entorno-ia-web-workspace-1 ia     # menú del proyecto "web"
docker exec -it -u node entorno-ia-web-workspace-1 bash   # terminal del proyecto "web"
```

Los contenedores se llaman `entorno-ia-<proyecto>-workspace-1` y aparecen agrupados en Docker Desktop (*Containers*), donde también se pueden ver sus registros, encender y apagar.

**Servidores de desarrollo:** arrancarlos escuchando en `0.0.0.0` y en el puerto 3000, 5173 u 8080. Abrirlos en Windows con la dirección que muestra el menú del proyecto. Ejemplo:

```bash
npm run dev -- --host 0.0.0.0 --port 5173     # en el proyecto 1 se abre en http://localhost:5174
```

**VS Code:** la opción 5 abre el proyecto conectado a su contenedor, con el usuario `node` en `/workspace`. La terminal integrada ya está dentro: `ia` abre el menú. El archivo `.devcontainer/devcontainer.json` del repositorio abre el proyecto `general`.

## 8. Modelo local

### LM Studio

1. Descargar un modelo en *Discover* (ver tabla de modelos).
2. Cargarlo con contexto 32768 y *GPU offload* al máximo.
3. *Developer → Start Server* (puerto 1234).
4. Arrancar con `.\iniciar.cmd` y usar la opción **3** del proyecto.

### llama.cpp

1. Comprobar que Docker ve la GPU:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
2. Elegir el modelo en `.env` (`LLAMACPP_HF_REPO`).
3. Arrancar con `.\iniciar.cmd -LlamaCpp`. Un único llama.cpp sirve a todos los proyectos. El primer arranque descarga el modelo:
   ```powershell
   docker compose logs -f llamacpp
   ```

### Ollama u otro servidor

Cualquier servidor compatible con la API de OpenAI que corra en Windows. Por ejemplo, Ollama: en `.env`, `LOCAL_URL=http://host.docker.internal:11434`. `iniciar.cmd` respeta ese valor (salvo con `-LlamaCpp`) y el cortafuegos abre solo ese puerto del PC.

### Modelos recomendados

| GPU | RAM | `LLAMACPP_HF_REPO` | Notas |
|---|---|---|---|
| 6–8 GB | 16 GB | `unsloth/Qwen3.5-9B-GGUF:Q4_K_M` | Entero en la GPU |
| 8–16 GB | 32 GB | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M` | `LLAMACPP_CPU_MOE=true` |
| 24 GB o más | — | `unsloth/Qwen3.6-27B-GGUF:Q4_K_M` | Entero en la GPU |

En LM Studio, buscar el mismo modelo en *Discover*. Para modelos MoE en GPUs pequeñas, activar la opción de mantener los expertos en la CPU.

## 9. Configuración

Fichero `.env` en la carpeta del repositorio. Vale para todos los proyectos:

| Variable | Descripción |
|---|---|
| `LOCAL_URL` | Servidor del modelo local. `iniciar.cmd` pone el de LM Studio o el de llama.cpp, salvo que escribas otro (ver [Ollama u otro servidor](#ollama-u-otro-servidor)). Es el único puerto del PC al que llegan los proyectos |
| `LOCAL_MODEL` | Modelo local a usar. Vacío = el primero disponible |
| `LLAMACPP_HF_REPO` | Modelo GGUF de Hugging Face (`usuario/repo:cuantización`) |
| `LLAMACPP_CTX` | Tamaño de contexto (recomendado 32768) |
| `LLAMACPP_CPU_MOE` | `true` para mantener los expertos MoE en la RAM |
| `ANTHROPIC_API_KEY` | Clave de API de Anthropic. Solo la recibe la opción 7, Claude Code con API (ver [Seguridad](#10-seguridad)). Se toma siempre de `.env`, no de las variables de Windows. La línea tiene que existir aunque esté vacía |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git dentro de los proyectos |
| `FIREWALL` | `on` (por defecto) u `off` |
| `FIREWALL_ALLOW` | Dominios, IPs o rangos extra permitidos, separados por comas |
| `WORKSPACE_MEMORY` | Memoria máxima de cada proyecto (por defecto `4g`) |
| `WORKSPACE_CPUS` | Núcleos máximos de cada proyecto (por defecto `2`) |
| `IMAGEN` | Imagen del entorno. Por defecto, la publicada por este repositorio |

Los cambios se aplican al volver a abrir el proyecto desde `iniciar.cmd`. Solo estas variables llegan a los proyectos: si añades otras a `.env`, los agentes no las verán.

## 10. Seguridad

| Medida | Efecto |
|---|---|
| Un contenedor por proyecto | Cada agente solo ve los archivos de su proyecto, no los demás ni el disco de Windows |
| Cortafuegos de salida | El contenedor solo puede conectarse a los destinos permitidos. El resto se rechaza |
| Arranque seguro | Si el cortafuegos no se aplica, el contenedor no arranca |
| Usuario sin privilegios | Claude Code y OpenCode se ejecutan como `node`, sin permisos de administrador |
| Contenedor endurecido | Sin capacidades de Linux salvo las mínimas, sin escalada de privilegios, con límites de memoria, CPU y procesos |
| Puertos locales | Los servidores de desarrollo solo son accesibles desde el propio PC |
| Sin acceso entre proyectos ni al PC | Un proyecto no puede conectarse a otro. Del PC solo alcanza el puerto de `LOCAL_URL` (el modelo local) |
| Puerto 53 cerrado | Los nombres se resuelven con el DNS de Docker; no se puede usar el puerto 53 como túnel hacia fuera |
| Carpeta personal por proyecto | Sesiones, configuración de los agentes, carpetas de confianza de Claude y VS Code son de cada proyecto. Lo que un agente deje ahí no afecta a otros proyectos; al crear uno nuevo solo se copia, si lo pides, la conexión con GitHub |
| Clave de API protegida | `ANTHROPIC_API_KEY` llega como secreto que solo puede leer root. Solo la recibe la opción 7 (Claude Code con API). Ni la terminal, ni VS Code, ni el resto de opciones la tienen. Mientras la 7 está abierta, otro programa del mismo proyecto podría leerla |
| Políticas de los agentes | Claude Code y OpenCode traen una configuración gestionada que los repositorios clonados no pueden cambiar. Claude Code: solo se ejecutan los hooks del entorno, no se usan servidores MCP y no lee archivos `.env` ni credenciales. OpenCode: pide permiso antes de editar o ejecutar comandos, no lee `.env`, e ignora la configuración, los agentes y los plugins que traiga el repositorio (sí lee su `AGENTS.md` y su `CLAUDE.md`) |

Destinos permitidos por defecto: Anthropic y Claude, GitHub, npm, PyPI, OpenCode, VS Code y el modelo local. La lista completa está en [scripts/firewall.sh](scripts/firewall.sh).

**Lo que no cubre:**

- **Instrucciones ocultas (*prompt injection*).** Un README, un issue o una web pueden contener instrucciones para el agente. El cortafuegos limita adónde puede enviar datos, pero GitHub, npm y la API de Anthropic están permitidos. Por eso el modo autónomo es solo para proyectos de confianza.
- **Dentro de un mismo proyecto,** un agente engañado puede dejar en su configuración algo que se ejecute la próxima vez que abras ese proyecto, o cambiar sus credenciales. Si sospechas de un proyecto, bórralo, créalo de nuevo desde GitHub y no copies nada de él.
- **El token de GitHub** del modo rápido (opción 6) da acceso a todos tus repositorios: un agente engañado podría usarlo en cualquiera. El modo limitado reduce el daño a los repositorios que elijas. En cualquier caso, protege la rama principal en GitHub (*Settings → Rules → Rulesets*: bloquear *force push* y borrado).
- **VS Code conectado a un proyecto** es un puente hacia Windows: no lo uses con repositorios de los que no te fíes ni a la vez que el modo autónomo.
- **Consultas DNS.** El DNS de Docker resuelve cualquier nombre, así que un agente engañado podría filtrar datos pequeños escondidos en nombres de dominio.
- **Servidores MCP desactivados.** Por seguridad, Claude Code no carga ningún servidor MCP, tampoco los que añadas tú. OpenCode tampoco usa los que traiga un repositorio.

Para permitir otros destinos (por ejemplo, la API de un proyecto o un CDN de paquetes):

```
FIREWALL_ALLOW=api.miproyecto.com,cdn.jsdelivr.net
```

Y aplicar abriendo el proyecto de nuevo desde `iniciar.cmd`. Las direcciones se resuelven al arrancar: si un servicio cambia de IP y deja de conectar, apagar y volver a abrir el proyecto.

## 11. Actualizar, parar y borrar

| Tarea | Cómo |
|---|---|
| Actualizar Claude Code, OpenCode y las herramientas | `iniciar.cmd` → **A** |
| Actualizar este repositorio | `git pull` (o descargar el ZIP de nuevo) y ejecutar `iniciar.cmd`. Los proyectos se conservan |
| Apagar todos los proyectos | `iniciar.cmd` → **P** |
| Borrar un proyecto | `iniciar.cmd` → **B** |
| Actualizar llama.cpp | `docker compose --profile llamacpp pull` |

Los archivos de cada proyecto viven en un volumen de Docker (`entorno-ia-<proyecto>_workspace`): súbelos a GitHub para tenerlos a salvo.

**Borrar todo** (proyectos, sesiones y modelos), desde la carpeta del repositorio:

```powershell
docker ps -aq --filter "name=entorno-ia" | ForEach-Object { docker rm -f $_ }
docker volume ls -q --filter "name=entorno-ia" | ForEach-Object { docker volume rm $_ }
```

No uses `docker compose down -v` con el proyecto de un nombre (`-p entorno-ia-…`): intentaría borrar también los modelos compartidos. Para borrar un proyecto, usa la opción **B**.

## 12. Solución de problemas

| Problema | Solución |
|---|---|
| `failed to connect to the docker API` | Abrir Docker Desktop y esperar a *Engine running* |
| Docker en modo contenedores de Windows | Icono de Docker → *Switch to Linux containers* |
| `running scripts is disabled` | Usar `iniciar.cmd` en lugar de `iniciar.ps1` |
| `port is already allocated` | Otro programa usa el puerto que muestra el error: cerrarlo |
| Sin servidor de modelos (LM Studio) | *Developer → Start Server*. Si persiste, activar *Serve on Local Network* |
| Sin servidor de modelos (llama.cpp) | El modelo aún se está descargando: `docker compose logs -f llamacpp` |
| `could not select device driver "nvidia"` | Actualizar el driver NVIDIA y Docker Desktop |
| Memoria insuficiente en llama.cpp | Bajar `LLAMACPP_CTX`, activar `LLAMACPP_CPU_MOE` o usar una cuantización menor |
| El modelo local no usa herramientas o se corta | Subir el contexto a 32768 o usar un modelo mayor |
| No se puede clonar un repositorio | Si es privado: opción 6 (Conectar GitHub). Si no es de GitHub: añadir su dominio a `FIREWALL_ALLOW` |
| Un proyecto no enciende (`unhealthy`) | Ver el motivo con `docker logs entorno-ia-<proyecto>-workspace-1` |
| Una herramienta no conecta (`Connection refused`, `EHOSTUNREACH`) | El cortafuegos bloquea ese destino: añadirlo a `FIREWALL_ALLOW` |
| VS Code no termina de abrir el proyecto | Añadir a `FIREWALL_ALLOW` el dominio que aparezca en el registro de *Dev Containers* |
| VS Code se abre como `root` o fuera de `/workspace` | Cerrar VS Code y volver a usar la opción 5 del menú |
| La construcción de la imagen falla | Comprobar la conexión y ejecutar `docker compose build --no-cache workspace` |
| `environment variable "ANTHROPIC_API_KEY" required by secret … is not set` | Falta la línea `ANTHROPIC_API_KEY=` en `.env` (puede ir vacía). `iniciar.cmd` la añade sola; al usar `docker compose` o VS Code directamente, ejecutar antes `iniciar.cmd` una vez |
| Aviso `mode is not supported outside Swarm mode` | Es inofensivo: Compose sí aplica ese permiso al secreto de la clave, y el contenedor lo comprueba al arrancar |
| `con el cortafuegos activo no se resuelven nombres` | Actualizar Docker Desktop (hace falta Docker Engine 26 o posterior). Si en *Settings → Docker Engine* hay un `"dns"` propio, probar a quitarlo |
| Un repositorio trae configuración de OpenCode (`opencode.json`, `.opencode/`) y no se aplica | Es a propósito: podría saltarse los permisos o ejecutar código al abrirse. Sus `AGENTS.md` y `CLAUDE.md` sí se leen |
| La opción 7 dice que la clave solo se entrega a las opciones que la usan | Se ha abierto `ia claude-api` desde la terminal. Abrirla desde el menú de `iniciar.cmd` |
