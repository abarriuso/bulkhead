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
git clone https://github.com/abarriuso/bulkhead.git
cd bulkhead
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
     W  Open WebUI              Chat con tu modelo local en el navegador
     A  Actualizar              Últimas versiones de Claude Code y OpenCode
     P  Apagar todo             Apaga todos los proyectos. No se pierde nada
     0  Salir                   Los proyectos encendidos siguen funcionando
```

- **Abrir un proyecto:** escribir su número. Si estaba apagado, se enciende en unos segundos.
- **Nuevo proyecto (N):** pide un nombre (minúsculas, números y guiones) y, opcionalmente, la dirección de un repositorio. Cada proyecto tiene sus propias sesiones: Claude Code pide iniciar sesión la primera vez y GitHub se conecta en cada uno, con un token para sus repositorios. Si el repositorio es privado y GitHub no está conectado, ofrece conectarlo. Un proyecto vacío empieza con git y un `CLAUDE.md` de plantilla para los agentes.
- **Borrar (B):** borra el contenedor, los archivos y las sesiones del proyecto. Antes avisa si hay cambios sin guardar o sin subir a GitHub, y pide escribir el nombre otra vez.

**Puertos:** dentro de cada proyecto los servidores de desarrollo usan siempre 3000, 5173 y 8080. En Windows, cada proyecto los publica en puertos distintos para que puedan funcionar a la vez: el primer proyecto en 3001, 5174 y 8081, el segundo en 3002, 5175 y 8082, etc. El menú del proyecto muestra sus direcciones.

**Proyecto `general`:** es el proyecto por defecto (`docker compose up` sin más, o VS Code con `.devcontainer/devcontainer.json`). Usa los puertos de siempre: 3000, 5173 y 8080. Si usabas una versión anterior a bulkhead, tus archivos siguen en el volumen de Docker `entorno-ia_workspace`, pero no aparecen en el menú.

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
| 6 Conectar GitHub | Conecta GitHub en este proyecto con un token que creas en GitHub solo para sus repositorios. Necesario para repositorios privados y para subir cambios. Los agentes del proyecto pueden usar esa conexión: por eso no se ofrece un inicio de sesión con acceso a todos tus repositorios |
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

Las sesiones de Claude Code, OpenCode y GitHub se conservan entre reinicios. Son de cada proyecto: al crear otro, Claude Code vuelve a pedir iniciar sesión y GitHub se conecta de nuevo.

Los agentes leen el archivo `CLAUDE.md` del proyecto al empezar: rellénalo (o pídeles que lo hagan con `/init`). Además conocen las reglas del entorno (puertos, cortafuegos, sin `sudo`) sin que haya que explicárselas. Más consejos en [Cómo trabajar con agentes](GUIA-AGENTES.md).

## 7. Uso diario

Con Docker Desktop abierto: ejecutar `iniciar.cmd` y elegir el proyecto. Si el entorno ya está preparado, tarda segundos.

Sin el menú, desde la carpeta del repositorio:

```powershell
docker exec -it -u node bulkhead-web-workspace-1 ia     # menú del proyecto "web"
docker exec -it -u node bulkhead-web-workspace-1 bash   # terminal del proyecto "web"
```

Los contenedores se llaman `bulkhead-<proyecto>-workspace-1` y aparecen agrupados en Docker Desktop (*Containers*), donde también se pueden ver sus registros, encender y apagar.

**Servidores de desarrollo:** arrancarlos escuchando en `0.0.0.0` y en el puerto 3000, 5173 u 8080. Abrirlos en Windows con la dirección que muestra el menú del proyecto. Ejemplo:

```bash
npm run dev -- --host 0.0.0.0 --port 5173     # en el proyecto 1 se abre en http://localhost:5174
```

**VS Code:** la opción 5 abre el proyecto conectado a su contenedor, con el usuario `node` en `/workspace`. La terminal integrada ya está dentro: `ia` abre el menú. El archivo `.devcontainer/devcontainer.json` del repositorio abre el proyecto `general`.

## 8. Modelo local

Un modelo local corre en tu tarjeta gráfica: es gratis y tus instrucciones no salen del PC, aunque rinde bastante menos que Claude. Tiene dos partes:

1. **Un servidor que lo carga:** LM Studio (en Windows) o llama.cpp (en Docker). Uno de los dos.
2. **Una forma de usarlo**, o las dos a la vez:
   - **OpenCode** (opción **3** del proyecto): agente que trabaja en los archivos del proyecto, como Claude Code.
   - **Open WebUI** (opción **W** de la pantalla principal): chat en el navegador, sin agente.

### LM Studio

1. Descargar un modelo en *Discover* (ver tabla de modelos).
2. Cargarlo con contexto 32768 y *GPU offload* al máximo.
3. *Developer → Start Server* (puerto 1234).
4. Arrancar con `.\iniciar.cmd` y usar OpenCode u Open WebUI.

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

### Open WebUI: chat en el navegador

Para cuando solo quieres hablar con el modelo, sin agente: preguntas, textos, resúmenes o documentos que subas tú. No ve los archivos de tus proyectos.

1. Tener el modelo local en marcha (LM Studio o llama.cpp).
2. `iniciar.cmd` → **W**. Se abre en el navegador en http://localhost:3100.
3. La primera vez descarga Open WebUI (varios GB) y pide crear una cuenta. La cuenta y los chats se guardan solo en este PC, en el volumen `bulkhead_openwebui`.

Viene configurado para no salir a internet por su cuenta: no descarga modelos, no comprueba versiones, no envía telemetría y no comparte chats. Lo que **no** tiene es el cortafuegos de los proyectos: va en su propia red de Docker, que solo llega al modelo local y no a los proyectos, pero esa red sí tiene salida a internet.

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
| `ANTHROPIC_API_KEY` | Clave de API de Anthropic, para la opción 7, Claude Code con API. Los agentes no pueden leerla (ver [Seguridad](#10-seguridad)). Se toma siempre de `.env`, no de las variables de Windows. La línea tiene que existir aunque esté vacía |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Identidad de git dentro de los proyectos |
| `FIREWALL` | `on` (por defecto) u `off` |
| `FIREWALL_ALLOW` | Dominios extra permitidos, separados por comas (`*.ejemplo.com` para sus subdominios). Una IP o un rango se permiten directamente, sin pasar por el proxy |
| `WORKSPACE_MEMORY` | Memoria máxima de cada proyecto (por defecto `4g`) |
| `WORKSPACE_CPUS` | Núcleos máximos de cada proyecto (por defecto `2`) |
| `IMAGEN` | Imagen del entorno. Por defecto, la versión publicada por este repositorio que corresponde a esta copia |

Los cambios se aplican al volver a abrir el proyecto desde `iniciar.cmd`. Solo estas variables llegan a los proyectos: si añades otras a `.env`, los agentes no las verán.

## 10. Seguridad

| Medida | Efecto |
|---|---|
| Un contenedor por proyecto | Cada agente solo ve los archivos de su proyecto, no los demás ni el disco de Windows |
| Cortafuegos de salida por dominio | Los agentes no tienen salida directa a internet ni DNS: solo pueden hablar con un proxy (Squid, con otro usuario) que únicamente conecta con los dominios permitidos. Comprueba el nombre que va dentro de la conexión cifrada, no solo la dirección, y en PyPI descifra para comprobar también la web pedida. El resto se rechaza |
| Arranque seguro | Si el cortafuegos no se aplica, el contenedor no arranca |
| Usuario sin privilegios | Claude Code y OpenCode se ejecutan como `node`, sin permisos de administrador |
| Contenedor endurecido | Sin capacidades de Linux salvo las mínimas, sin escalada de privilegios, con límites de memoria, CPU y procesos |
| Puertos locales | Los servidores de desarrollo solo son accesibles desde el propio PC |
| Sin acceso entre proyectos ni al PC | Un proyecto no puede conectarse a otro. Del PC, o de llama.cpp, solo alcanza la dirección y el puerto de `LOCAL_URL` (el modelo local) |
| Sin DNS para los agentes | Los nombres los resuelve el proxy. Ni el DNS de Docker ni el puerto 53 se pueden usar como túnel hacia fuera |
| Carpeta personal por proyecto | Sesiones, configuración de los agentes, carpetas de confianza de Claude y VS Code son de cada proyecto. Lo que un agente deje ahí no afecta a otros proyectos; no se copia nada de un proyecto a otro |
| Clave de API protegida | `ANTHROPIC_API_KEY` llega como secreto que solo puede leer root, y es el proxy quien la añade a las peticiones de la opción 7 (Claude Code con API). Claude Code recibe una clave de relleno: ni sus comandos ni ningún otro programa del proyecto pueden leer la de verdad. Sí pueden usarla mientras el proyecto tenga clave configurada, enviando peticiones a la API de Anthropic a tu cargo |
| Políticas de los agentes | Claude Code y OpenCode traen una configuración gestionada que los repositorios clonados no pueden cambiar. Claude Code: solo se ejecutan los hooks del entorno y las reglas de permisos de la política (un `.claude/settings.json` del repositorio no puede autorizar comandos; por lo mismo, «no volver a preguntar» no se guarda para siempre), no se usan servidores MCP, su herramienta de lectura no abre `.env` ni credenciales y los comandos que ejecuta no heredan claves. OpenCode: solo usa el modelo local, no comparte conversaciones, pide permiso antes de editar o ejecutar comandos, no lee `.env`, e ignora la configuración, los agentes y los plugins que traiga el repositorio (sí lee su `AGENTS.md` y su `CLAUDE.md`). Estas reglas no impiden que un comando aprobado lea un archivo: lo que de verdad protege los secretos es que el usuario de los agentes no pueda abrirlos |

| Imagen publicada con atestación | La imagen se descarga por versión, no como `latest`, y la CI publica una atestación firmada de que se construyó aquí. Para comprobarla: `gh attestation verify oci://ghcr.io/abarriuso/bulkhead:7 --owner abarriuso` |

Destinos permitidos por defecto: Anthropic y Claude, GitHub, npm, PyPI, VS Code y el modelo local. La lista completa está en [scripts/firewall.sh](scripts/firewall.sh). Las conexiones del proxy quedan en `/var/log/bulkhead-proxy/conexiones.log` dentro del proyecto; las bloqueadas llevan `DENIED`.

**Lo que no cubre:**

- **Instrucciones ocultas (*prompt injection*).** Un README, un issue o una web pueden contener instrucciones para el agente. El cortafuegos limita adónde puede enviar datos, pero GitHub (los repositorios de tu token), npm (que acepta paquetes de cualquiera) y la API de Anthropic están permitidos. Por eso el modo autónomo es solo para proyectos de confianza.
- **Dentro de un mismo proyecto,** un agente engañado puede dejar en su configuración algo que se ejecute la próxima vez que abras ese proyecto, o cambiar sus credenciales. Si sospechas de un proyecto, bórralo, créalo de nuevo desde GitHub y no copies nada de él.
- **El token de GitHub** (opción 6) lo pueden usar los agentes del proyecto: un agente engañado podría subir datos o borrar ramas en los repositorios que le diste. Elige solo los del proyecto y protege la rama principal en GitHub (*Settings → Rules → Rulesets*: bloquear *force push* y borrado).
- **VS Code conectado a un proyecto** es un puente hacia Windows: no lo uses con repositorios de los que no te fíes ni a la vez que el modo autónomo.
- **El proxy es tan fiable como la lista.** Si añades un dominio a `FIREWALL_ALLOW`, todo lo que se pueda subir a ese sitio es una vía de salida. Y si está detrás de una CDN que sirve otras webs con la cabecera Host (como Fastly), el proxy no lo descifra: añade solo lo que necesites.
- **Programas que no usan proxy** no tienen salida a internet. Casi todos lo usan solos (`HTTPS_PROXY`); los que no, fallan con un error de conexión.
- **Servidores MCP desactivados.** Por seguridad, Claude Code no carga ningún servidor MCP, tampoco los que añadas tú. OpenCode tampoco usa los que traiga un repositorio.
- **LM Studio, llama.cpp y Open WebUI** no pasan por el cortafuegos de los proyectos.

Con el entorno conectado a internet, mejor no tratar datos sensibles: el cortafuegos limita adónde se conecta el agente, pero no impide que envíe datos a los destinos permitidos.

Para permitir otros destinos (por ejemplo, la API de un proyecto o un CDN de paquetes):

```
FIREWALL_ALLOW=api.miproyecto.com,cdn.jsdelivr.net
```

Y aplicar abriendo el proyecto de nuevo desde `iniciar.cmd`. Si llama.cpp se recrea y cambia de dirección, apagar y volver a abrir el proyecto.

## 11. Actualizar, parar y borrar

| Tarea | Cómo |
|---|---|
| Actualizar Claude Code, OpenCode y las herramientas | `iniciar.cmd` → **A** |
| Actualizar este repositorio | `git pull` (o descargar el ZIP de nuevo) y ejecutar `iniciar.cmd`. Los proyectos se conservan |
| Apagar todos los proyectos | `iniciar.cmd` → **P** |
| Borrar un proyecto | `iniciar.cmd` → **B** |
| Actualizar llama.cpp | `docker compose --profile llamacpp pull` |

Los archivos de cada proyecto viven en un volumen de Docker (`bulkhead-<proyecto>_workspace`): súbelos a GitHub para tenerlos a salvo.

**Borrar todo** (proyectos, sesiones y modelos), desde la carpeta del repositorio:

```powershell
docker ps -aq --filter "name=bulkhead" | ForEach-Object { docker rm -f $_ }
docker volume ls -q --filter "name=bulkhead" | ForEach-Object { docker volume rm $_ }
```

No uses `docker compose down -v` con el proyecto de un nombre (`-p bulkhead-…`): intentaría borrar también los modelos compartidos. Para borrar un proyecto, usa la opción **B**.

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
| Un proyecto no enciende (`unhealthy`) | Ver el motivo con `docker logs bulkhead-<proyecto>-workspace-1` |
| Una herramienta no conecta (`403`, `Connection refused`, `EHOSTUNREACH`, `Could not resolve host`) | El cortafuegos bloquea ese destino: buscar `DENIED` en `/var/log/bulkhead-proxy/conexiones.log` y añadir el dominio a `FIREWALL_ALLOW`. Si el programa no usa `HTTPS_PROXY`, no puede salir |
| `pip` o Python dan un error de certificado | Usar el Python del sistema o un `venv` normal: confían en el certificado del proxy mediante `PIP_CERT` y `SSL_CERT_FILE`. Un programa con su propia lista de certificados necesita que se la indiques |
| VS Code no termina de abrir el proyecto | Añadir a `FIREWALL_ALLOW` el dominio que aparezca en el registro de *Dev Containers* |
| VS Code se abre como `root` o fuera de `/workspace` | Cerrar VS Code y volver a usar la opción 5 del menú |
| La construcción de la imagen falla | Comprobar la conexión y ejecutar `docker compose build --no-cache workspace` |
| `environment variable "ANTHROPIC_API_KEY" required by secret … is not set` | Falta la línea `ANTHROPIC_API_KEY=` en `.env` (puede ir vacía). `iniciar.cmd` la añade sola; al usar `docker compose` o VS Code directamente, ejecutar antes `iniciar.cmd` una vez |
| Aviso `mode is not supported outside Swarm mode` | Es inofensivo: Compose sí aplica ese permiso al secreto de la clave, y el contenedor lo comprueba al arrancar |
| `con el cortafuegos activo no se resuelven nombres` | Actualizar Docker Desktop (hace falta Docker Engine 26 o posterior). Si en *Settings → Docker Engine* hay un `"dns"` propio, probar a quitarlo |
| Un repositorio trae configuración de OpenCode (`opencode.json`, `.opencode/`) y no se aplica | Es a propósito: podría saltarse los permisos o ejecutar código al abrirse. Sus `AGENTS.md` y `CLAUDE.md` sí se leen |
