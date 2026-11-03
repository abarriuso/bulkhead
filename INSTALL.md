# Installation

1. [Requirements](#requirements)
2. [Simple installation](#simple-installation)
3. [Advanced installation](#advanced-installation)

## Requirements

### To use Claude (the basics)

| | Minimum | Recommended |
|---|---|---|
| System | Windows 10 64-bit version 22H2, or Windows 11 version 23H2 or later (Home or Pro) | Windows 11 |
| RAM | 8 GB | 16 GB |
| Free disk space | 15 GB | 30 GB |
| Processor | With virtualization (almost all since 2015) | — |
| Internet | Required | — |
| Account | Claude **Pro, Max or Team**, or an Anthropic API key | Not needed with a local model |

Claude's free plan doesn't include Claude Code. Without a paid account you can use a local model, with OpenCode or Open WebUI (see below).

Docker Desktop is free for personal and educational use, and for companies with fewer than 250 employees and less than 10 million dollars in annual revenue. Above that, it needs a paid licence.

**How to check your Windows version:** Windows key + R → type `winver` → Enter.

**How to check your RAM:** Settings → System → About → *Installed RAM*.

**How to check that virtualization is on:** Task Manager (Ctrl + Shift + Esc) → *Performance* → *CPU* → **Virtualization: Enabled**. If it says *Disabled*, it has to be turned on in the BIOS: the only step that may need technical help.

### To use a local model (optional)

| | Minimum | Recommended |
|---|---|---|
| Graphics card | NVIDIA with 6 GB of memory | NVIDIA with 12 GB or more |
| RAM | 16 GB | 32 GB |
| Extra free space | 10 GB | 30 GB |

Without an NVIDIA card, everything else works as normal.

## Simple installation

No commands. About 20 minutes in all.

The launcher's menus are in Spanish; each step below gives the key to press and what it does.

### Step 1. Install Docker Desktop

1. Go to https://www.docker.com/products/docker-desktop/ and click **Download for Windows**.
2. Open the downloaded file and click *OK* until it finishes.
3. **Restart the computer.**
4. Open **Docker Desktop** from the Start menu and accept the terms. You don't need an account: you can click *Skip*.
5. If it asks to install or update **WSL**, click the button that appears and restart if asked.
6. Wait until **Engine running** shows in green at the bottom left.

### Step 2. Download bulkhead

1. Go to https://github.com/abarriuso/bulkhead
2. Green **Code** button → **Download ZIP**.
3. Right-click the downloaded ZIP → **Extract All** → **Extract**.

### Step 3. Start it

1. Open the extracted folder.
2. **Double-click `iniciar.cmd`.**
3. If *"Windows protected your PC"* appears: **More info** → **Run anyway**.
4. Wait for the menu to appear. The first time, it downloads the environment (about 1 GB) and takes a few minutes.

### Step 4. Create your first project

1. In the menu, type **N** (*Nuevo proyecto*, new project) and press Enter.
2. Type a short name, for example `test`.
3. Press Enter to start an empty project (or paste the address of a GitHub repository).

Each project has its own container, with its files kept apart from the others.

### Step 5. Sign in to Claude

1. In the project menu, type **1** (Claude Code) and press Enter. It opens in a new tab.
2. A link appears: copy it, open it in the browser and sign in with your Claude account.
3. Copy the code the page shows and paste it into the black window (right-click to paste).

Each project has its own session: in each new project, Claude Code asks you to sign in the first time.

**No paid Claude account?** With an NVIDIA graphics card you can use a local model: see [Local model with LM Studio](#local-model-with-lm-studio).

### The next times

1. Open **Docker Desktop** and wait for *Engine running*.
2. **Double-click `iniciar.cmd`** and choose the project by its number.

To learn how to work with the agents: [Working with agents](AGENTS-GUIDE.md).

## Advanced installation

### Install with commands

In PowerShell as administrator:

```powershell
wsl --install
winget install -e --id Docker.DockerDesktop
winget install -e --id Git.Git
```

Restart, open Docker Desktop and wait for *Engine running*. Then, in a normal PowerShell:

```powershell
cd $HOME\Documents
git clone https://github.com/abarriuso/bulkhead.git
cd bulkhead
.\iniciar.cmd
```

With Git you can update it later with `git pull`.

### Optional settings

Edit the `.env` file in the folder (it is created on the first start) and run `iniciar.cmd` again:

| Variable | What for |
|---|---|
| `ANTHROPIC_API_KEY` | Use Claude Code with an API key (option 7) |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | Your git identity inside the container |

The other variables: [user manual](MANUAL.md#9-configuration).

### Local model with LM Studio

1. Update the NVIDIA driver: https://www.nvidia.com/Download/index.aspx
2. Install LM Studio 0.4.1 or later: https://lmstudio.ai (or `winget install -e --id ElementLabs.LMStudio`).
3. *Discover* → download a model ([recommended models](MANUAL.md#recommended-models)).
4. Load it with a context of **32768** and *GPU offload* at the maximum.
5. *Developer* → **Start Server**.
6. Double-click `iniciar.cmd`. For an agent in the project, option **3** (OpenCode local); for a chat in the browser, option **W** (Open WebUI) on the main screen.

### Local model with llama.cpp (without LM Studio)

1. Update the NVIDIA driver and restart Docker Desktop.
2. Check that Docker sees the graphics card:
   ```powershell
   docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
   ```
3. Choose the model in `.env` (`LLAMACPP_HF_REPO`, see [recommended models](MANUAL.md#recommended-models)).
4. Start:
   ```powershell
   .\iniciar.cmd -LlamaCpp
   ```
5. The first start downloads the model. Follow the progress with `docker compose logs -f llamacpp`. In the project menu, option **3**.

### Installation problems

| Problem | Fix |
|---|---|
| Docker Desktop doesn't start or mentions virtualization | Turn on virtualization in the BIOS (*Intel VT-x* or *AMD-V / SVM*) |
| Docker Desktop asks for WSL | `wsl --update` in PowerShell as administrator, then restart |
| `access denied` when using Docker | `net localgroup docker-users "$env:USERNAME" /add` as administrator, then sign out |
| `failed to connect to the docker API` | Open Docker Desktop and wait for *Engine running* |

More problems: [user manual](MANUAL.md#12-troubleshooting).
