# User manual

1. [Requirements](#1-requirements)
2. [Installation](#2-installation)
3. [Starting up](#3-starting-up)
4. [Projects](#4-projects)
5. [Project menu](#5-project-menu)
6. [First use](#6-first-use)
7. [Daily use](#7-daily-use)
8. [Local model](#8-local-model)
9. [Configuration](#9-configuration)
10. [Security](#10-security)
11. [Update, stop and delete](#11-update-stop-and-delete)
12. [Troubleshooting](#12-troubleshooting)

The launcher (`iniciar.cmd`) and the `ia` menu are in Spanish. This manual quotes their options as they appear on screen, with what each one does.

## 1. Requirements

| Requirement | Notes |
|---|---|
| Windows 10 22H2 or Windows 11 23H2 (Home or Pro) | With virtualization turned on in the BIOS. Details in [INSTALL.md](INSTALL.md#requirements) |
| Docker Desktop | With *Use WSL 2 based engine* turned on (it is by default) |
| A Claude account (Pro, Max or Team) or an API key | For Claude Code. OpenCode with a local model works without them |
| NVIDIA GPU with an up-to-date driver | Only for the local model |
| LM Studio 0.4.1 or later | Only if the local model is served by LM Studio |
| VS Code | Optional, for the menu's *VS Code* option |

You don't need to install Git, Node.js, Python or any other tool: they are inside the environment.

## 2. Installation

Full installation from scratch: [INSTALL.md](INSTALL.md).

With Git:

```powershell
git clone https://github.com/abarriuso/bulkhead.git
cd bulkhead
```

Without Git: on GitHub, *Code → Download ZIP*, and unzip it.

## 3. Starting up

1. Open Docker Desktop and wait for *Engine running*.
2. Run `iniciar.cmd` (double-click it, or from the terminal):

```powershell
.\iniciar.cmd              # local model in LM Studio, or no local model
.\iniciar.cmd -LlamaCpp    # local model in llama.cpp (Docker)
```

The script checks the installation, opens Docker Desktop if it's closed, creates `.env` if it doesn't exist and prepares the environment: it downloads the ready-built image or, if it can't, builds it on the PC (5–10 minutes the first time). Then it shows the projects.

## 4. Projects

Each project lives in **its own container**, with its files, its git history, its ports and its **home folder**: the Claude, OpenCode and GitHub sessions, the agents' settings and VS Code. An agent working in one project can't see or touch the others, or leave anything in its settings that affects another one.

What all projects share:

- The image (Claude Code, OpenCode and the tools): downloaded only once.
- The llama.cpp models.

The main screen of `iniciar.cmd`:

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

Each project shows as *apagado* (off) or *encendido* (on), with its address. The options: **N** new project, **B** delete a project, **W** Open WebUI ([chat in the browser](#open-webui-chat-in-the-browser)), **A** update Claude Code and OpenCode, **P** shut down all projects (nothing is lost), **0** exit (running projects keep running).

- **Open a project:** type its number. If it was off, it starts in a few seconds.
- **New project (N):** asks for a name (lowercase letters, numbers and hyphens) and, optionally, the address of a repository. Each project has its own sessions: Claude Code asks you to sign in the first time, and GitHub is connected in each one, with a token for its repositories. If the repository is private and GitHub isn't connected, it offers to connect it. An empty project starts with git and a template `CLAUDE.md` for the agents.
- **Delete (B):** deletes the project's container, files and sessions. First it warns you if there are changes not saved or not pushed to GitHub, and asks you to type the name again.

**Ports:** inside each project, development servers always use 3000, 5173 and 8080. On Windows, each project publishes them on different ports so they can run at the same time: the first project on 3001, 5174 and 8081, the second on 3002, 5175 and 8082, and so on. The project menu shows its addresses.

**The `general` project:** the default project (plain `docker compose up`, or VS Code with `.devcontainer/devcontainer.json`). It uses the usual ports: 3000, 5173 and 8080. If you used a version from before bulkhead, your files are still in the `entorno-ia_workspace` Docker volume, but they don't show in the menu.

## 5. Project menu

The tools open in a **new tab** of Windows Terminal (or in a new window if it isn't installed) and the menu stays available, so you can use several at once.

| Option | What it opens |
|---|---|
| ***Trabajar con IA*** (work with AI) | |
| 1 Claude Code | Claude Code with your Claude account. Asks for permission before each change or command |
| 2 *Claude Code autónomo* (autonomous) | Claude Code without asking for permission (`--dangerously-skip-permissions`). Faster, but only use it with projects and repositories you trust: the isolation protects your PC, it doesn't stop instructions hidden in a file or a web page from tricking the agent. Doesn't work with `FIREWALL=off`. Review the changes at the end with git |
| 3 OpenCode local | OpenCode with the LM Studio or llama.cpp model. Free; the model runs on your PC. Like Claude Code, it asks for permission before editing or running commands |
| ***Herramientas*** (tools) | |
| 4 Terminal | The project's command line (git, gh, npm, python…) |
| 5 VS Code | Opens the project in VS Code, connected to the container. Installs the *Dev Containers* extension by itself |
| 6 *Conectar GitHub* (connect GitHub) | Connects GitHub in this project with a token you create on GitHub for its repositories only. Needed for private repositories and to push changes. The project's agents can use that connection: that's why there's no sign-in that gives access to all your repositories |
| ***Avanzado*** (advanced) | |
| 7 *Claude Code con API* (with the API) | Claude Code paid per use with `ANTHROPIC_API_KEY` |
| 8 *Modelos locales* (local models) | Lists the models available in LM Studio or llama.cpp |
| 0 *Volver a proyectos* (back) | Goes back to the project list. The project stays on |

Inside the project (in the terminal or in VS Code) the same menu exists in text mode: `ia`. It can also be used with names:

```bash
ia claude        # Claude Code
ia auto          # autonomous Claude Code
ia local         # OpenCode with the local model
ia github        # connect GitHub
ia claude -c     # extra arguments go to the tool (here: continue the last conversation)
ia -h            # help
```

## 6. First use

1. `iniciar.cmd` → **N** → project name → Enter (empty) or the address of a repository.
2. In the project menu, **1** (Claude Code). The first time, it shows a sign-in URL: open it in the Windows browser, sign in and paste the code.
3. To push your work to GitHub: option **6** (*Conectar GitHub*), once in each project.

The Claude Code, OpenCode and GitHub sessions are kept across restarts. They belong to each project: when you create another one, Claude Code asks you to sign in again and GitHub is connected again.

The agents read the project's `CLAUDE.md` file when they start: fill it in (or ask them to with `/init`). They also know the environment's rules (ports, firewall, no `sudo`) without you having to explain them. More tips in [Working with agents](AGENTS-GUIDE.md).

## 7. Daily use

With Docker Desktop open: run `iniciar.cmd` and choose the project. If the environment is already prepared, it takes seconds.

Without the menu, from the repository folder:

```powershell
docker exec -it -u node bulkhead-web-workspace-1 ia     # menu of the "web" project
docker exec -it -u node bulkhead-web-workspace-1 bash   # terminal of the "web" project
```

The containers are named `bulkhead-<project>-workspace-1` and show up grouped in Docker Desktop (*Containers*), where you can also see their logs and start and stop them.

**Development servers:** start them listening on `0.0.0.0` and on port 3000, 5173 or 8080. Open them on Windows at the address the project menu shows. For example:

```bash
npm run dev -- --host 0.0.0.0 --port 5173     # in project 1 it opens at http://localhost:5174
```

**VS Code:** option 5 opens the project connected to its container, as the `node` user in `/workspace`. The integrated terminal is already inside: `ia` opens the menu. The repository's `.devcontainer/devcontainer.json` file opens the `general` project.

## 8. Local model

A local model runs on your graphics card: it's free and your prompts don't leave the PC, though it does much worse than Claude. It has two parts:

1. **A server that loads it:** LM Studio (on Windows) or llama.cpp (in Docker). One of the two.
2. **A way to use it**, or both at once:
   - **OpenCode** (option **3** of the project): an agent that works on the project's files, like Claude Code.
   - **Open WebUI** (option **W** on the main screen): a chat in the browser, with no agent.

### LM Studio

1. Download a model in *Discover* (see the table of models).
2. Load it with a context of 32768 and *GPU offload* at the maximum.
3. *Developer → Start Server* (port 1234).
4. Start with `.\iniciar.cmd` and use OpenCode or Open WebUI.

### llama.cpp

1. Check that Docker sees the GPU:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
2. Choose the model in `.env` (`LLAMACPP_HF_REPO`).
3. Start with `.\iniciar.cmd -LlamaCpp`. A single llama.cpp serves every project. The first start downloads the model:
   ```powershell
   docker compose logs -f llamacpp
   ```

### Open WebUI: chat in the browser

For when you only want to talk to the model, with no agent: questions, texts, summaries or documents you upload yourself. It can't see your projects' files.

1. Have the local model running (LM Studio or llama.cpp).
2. `iniciar.cmd` → **W**. It opens in the browser at http://localhost:3100.
3. The first time, it downloads Open WebUI (several GB) and asks you to create an account. The account and the chats are stored only on this PC, in the `bulkhead_openwebui` volume.

It comes set up not to go online on its own: it doesn't download models, check for versions, send telemetry or share chats. What it **doesn't** have is the projects' firewall: it runs on its own Docker network, which only reaches the local model and not the projects, but that network does have internet access.

### Ollama or another server

Any OpenAI-compatible API server running on Windows. For example, Ollama: in `.env`, `LOCAL_URL=http://host.docker.internal:11434`. `iniciar.cmd` respects that value (except with `-LlamaCpp`) and the firewall opens only that port of the PC.

### Recommended models

| GPU | RAM | `LLAMACPP_HF_REPO` | Notes |
|---|---|---|---|
| 6–8 GB | 16 GB | `unsloth/Qwen3.5-9B-GGUF:Q4_K_M` | Fully on the GPU |
| 8–16 GB | 32 GB | `unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_M` | `LLAMACPP_CPU_MOE=true` |
| 24 GB or more | — | `unsloth/Qwen3.6-27B-GGUF:Q4_K_M` | Fully on the GPU |

In LM Studio, search for the same model in *Discover*. For MoE models on small GPUs, turn on the option to keep the experts on the CPU.

## 9. Configuration

The `.env` file in the repository folder. It applies to every project:

| Variable | Description |
|---|---|
| `LOCAL_URL` | The local model's server. `iniciar.cmd` sets LM Studio's or llama.cpp's, unless you write another one (see [Ollama or another server](#ollama-or-another-server)). It's the only port of the PC the projects can reach |
| `LOCAL_MODEL` | The local model to use. Empty = the first one available |
| `LLAMACPP_HF_REPO` | GGUF model from Hugging Face (`user/repo:quantization`) |
| `LLAMACPP_CTX` | Context size (32768 recommended) |
| `LLAMACPP_CPU_MOE` | `true` to keep the MoE experts in RAM |
| `ANTHROPIC_API_KEY` | Anthropic API key, for option 7, Claude Code with the API. The agents can't read it (see [Security](#10-security)). It's always taken from `.env`, not from the Windows variables. The line must exist even if it's empty |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Git identity inside the projects |
| `FIREWALL` | `on` (default) or `off` |
| `FIREWALL_ALLOW` | Extra allowed domains, separated by commas (`*.example.com` for its subdomains). An IP or a range is allowed directly, without going through the proxy |
| `WORKSPACE_MEMORY` | Maximum memory for each project (default `4g`) |
| `WORKSPACE_CPUS` | Maximum cores for each project (default `2`) |
| `IMAGEN` | The environment image. By default, the version published by this repository that matches this copy |

Changes apply when you open the project again from `iniciar.cmd`. Only these variables reach the projects: if you add others to `.env`, the agents won't see them.

## 10. Security

| Measure | Effect |
|---|---|
| One container per project | Each agent only sees its own project's files, not the others or the Windows drive |
| Outbound firewall by domain | The agents have no direct internet access and no DNS: they can only talk to a proxy (Squid, running as another user) that only connects to the allowed domains. It checks the name inside the encrypted connection, not just the address, and for PyPI it decrypts to also check the page requested. Everything else is refused |
| Safe start | If the firewall isn't applied, the container doesn't start |
| Unprivileged user | Claude Code and OpenCode run as `node`, without administrator rights |
| Hardened container | No Linux capabilities beyond the minimum, no privilege escalation, with memory, CPU and process limits |
| Local ports | The development servers can only be reached from the PC itself |
| No access between projects or to the PC | A project can't connect to another one. Of the PC, or of llama.cpp, it only reaches the address and port in `LOCAL_URL` (the local model) |
| No DNS for the agents | The proxy resolves the names. Neither Docker's DNS nor port 53 can be used as a tunnel out |
| A home folder per project | Sessions, the agents' settings, and the trusted folders of Claude and VS Code belong to each project. Whatever an agent leaves there doesn't affect other projects; nothing is copied from one project to another |
| Protected API key | `ANTHROPIC_API_KEY` arrives as a secret only root can read, and the proxy adds it to the requests of option 7 (Claude Code with the API). Claude Code gets a placeholder key: neither its commands nor any other program in the project can read the real one. They can use it while the project has a key configured, by sending requests to the Anthropic API at your expense |
| Agent policies | Claude Code and OpenCode come with managed settings that cloned repositories can't change. Claude Code: only the environment's hooks and the policy's permission rules run (a repository's `.claude/settings.json` can't authorise commands; for the same reason, "don't ask again" isn't saved for good), no MCP servers are used, its read tool won't open `.env` or credentials, and the commands it runs don't inherit keys. OpenCode: only uses the local model, doesn't share conversations, asks for permission before editing or running commands, doesn't read `.env`, and ignores the settings, agents and plugins a repository brings (it does read its `AGENTS.md` and `CLAUDE.md`). These rules don't stop an approved command from reading a file: what really protects the secrets is that the agents' user can't open them |
| Image published with an attestation | The image is downloaded by version, not as `latest`, and CI publishes a signed attestation that it was built here. To check it: `gh attestation verify oci://ghcr.io/abarriuso/bulkhead:<version> --owner abarriuso` (the version is in `docker-compose.yml`) |

Destinations allowed by default: Anthropic and Claude, GitHub, npm, PyPI, VS Code and the local model. The full list is in [scripts/firewall.sh](scripts/firewall.sh). The proxy's connections are logged in `/var/log/bulkhead-proxy/conexiones.log` inside the project; the blocked ones are marked `DENIED`.

**What it doesn't cover:**

- **Hidden instructions (*prompt injection*).** A README, an issue or a web page can contain instructions for the agent. The firewall limits where it can send data, but GitHub (the repositories of your token), npm (which takes packages from anyone) and the Anthropic API are allowed. That's why autonomous mode is only for projects you trust.
- **Within the same project,** a tricked agent can leave something in its settings that runs the next time you open that project, or change its credentials. If you suspect a project, delete it, create it again from GitHub and don't copy anything from it.
- **The GitHub token** (option 6) can be used by the project's agents: a tricked agent could push data or delete branches in the repositories you gave it. Choose only the project's repositories and protect the main branch on GitHub (*Settings → Rules → Rulesets*: block *force push* and deletion).
- **VS Code connected to a project** is a bridge to Windows: don't use it with repositories you don't trust, or at the same time as autonomous mode.
- **The proxy is only as reliable as its list.** If you add a domain to `FIREWALL_ALLOW`, anything that can be uploaded to that site is a way out. And if it's behind a CDN that serves other websites by the Host header (like Fastly), the proxy doesn't decrypt it: add only what you need.
- **Programs that don't use the proxy** have no internet access. Almost all of them use it on their own (`HTTPS_PROXY`); those that don't fail with a connection error.
- **MCP servers turned off.** For safety, Claude Code doesn't load any MCP server, not even the ones you add. OpenCode doesn't use the ones a repository brings either.
- **LM Studio, llama.cpp and Open WebUI** don't go through the projects' firewall.

While the environment is connected to the internet, better not handle sensitive data: the firewall limits where the agent connects, but it doesn't stop it from sending data to the allowed destinations.

To allow other destinations (for example, a project's API or a package CDN):

```
FIREWALL_ALLOW=api.myproject.com,cdn.jsdelivr.net
```

And apply it by opening the project again from `iniciar.cmd`. If llama.cpp is recreated and its address changes, shut the project down and open it again.

## 11. Update, stop and delete

| Task | How |
|---|---|
| Update Claude Code, OpenCode and the tools | `iniciar.cmd` → **A** |
| Update this repository | `git pull` (or download the ZIP again) and run `iniciar.cmd`. The projects are kept |
| Shut down all projects | `iniciar.cmd` → **P** |
| Delete a project | `iniciar.cmd` → **B** |
| Update llama.cpp | `docker compose --profile llamacpp pull` |

Each project's files live in a Docker volume (`bulkhead-<project>_workspace`): push them to GitHub to keep them safe.

**Delete everything** (projects, sessions and models), from the repository folder:

```powershell
docker ps -aq --filter "name=bulkhead" | ForEach-Object { docker rm -f $_ }
docker volume ls -q --filter "name=bulkhead" | ForEach-Object { docker volume rm $_ }
```

Don't use `docker compose down -v` with a named project (`-p bulkhead-…`): it would also try to delete the shared models. To delete a project, use option **B**.

## 12. Troubleshooting

| Problem | Fix |
|---|---|
| `failed to connect to the docker API` | Open Docker Desktop and wait for *Engine running* |
| Docker in Windows containers mode | Docker icon → *Switch to Linux containers* |
| `running scripts is disabled` | Use `iniciar.cmd` instead of `iniciar.ps1` |
| `port is already allocated` | Another program is using the port the error shows: close it |
| No model server (LM Studio) | *Developer → Start Server*. If it persists, turn on *Serve on Local Network* |
| No model server (llama.cpp) | The model is still downloading: `docker compose logs -f llamacpp` |
| `could not select device driver "nvidia"` | Update the NVIDIA driver and Docker Desktop |
| Not enough memory in llama.cpp | Lower `LLAMACPP_CTX`, turn on `LLAMACPP_CPU_MOE` or use a smaller quantization |
| The local model doesn't use tools or gets cut off | Raise the context to 32768 or use a bigger model |
| A repository can't be cloned | If it's private: option 6 (*Conectar GitHub*). If it isn't on GitHub: add its domain to `FIREWALL_ALLOW` |
| A project won't start (`unhealthy`) | See why with `docker logs bulkhead-<project>-workspace-1` |
| A tool can't connect (`403`, `Connection refused`, `EHOSTUNREACH`, `Could not resolve host`) | The firewall is blocking that destination: look for `DENIED` in `/var/log/bulkhead-proxy/conexiones.log` and add the domain to `FIREWALL_ALLOW`. If the program doesn't use `HTTPS_PROXY`, it can't get out |
| `pip` or Python give a certificate error | Use the system Python or a normal `venv`: they trust the proxy's certificate through `PIP_CERT` and `SSL_CERT_FILE`. A program with its own list of certificates needs you to point it there |
| VS Code never finishes opening the project | Add to `FIREWALL_ALLOW` the domain that shows up in the *Dev Containers* log |
| VS Code opens as `root` or outside `/workspace` | Close VS Code and use option 5 of the menu again |
| Building the image fails | Check the connection and run `docker compose build --no-cache workspace` |
| `environment variable "ANTHROPIC_API_KEY" required by secret … is not set` | The `ANTHROPIC_API_KEY=` line is missing from `.env` (it can be empty). `iniciar.cmd` adds it by itself; when using `docker compose` or VS Code directly, run `iniciar.cmd` once first |
| Warning `mode is not supported outside Swarm mode` | Harmless: Compose does apply that permission to the key's secret, and the container checks it at startup |
| `con el cortafuegos activo no se resuelven nombres` (names don't resolve with the firewall on) | Update Docker Desktop (Docker Engine 26 or later is needed). If *Settings → Docker Engine* has its own `"dns"`, try removing it |
| A repository brings OpenCode settings (`opencode.json`, `.opencode/`) and they aren't applied | On purpose: they could get around the permissions or run code when opened. Its `AGENTS.md` and `CLAUDE.md` are read |
