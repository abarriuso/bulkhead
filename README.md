# bulkhead

AI on Windows without giving it access to the rest of your computer: **Claude Code** with your Anthropic account, and **local models** that run on your own GPU. Local models work as an agent, with OpenCode inside a project, or as a chat in the browser, with Open WebUI. Each project runs in its own Docker container, behind a firewall. The only thing you need to install is Docker Desktop.

> [!NOTE]
> A personal project maintained by one person. It works and has automated tests, but nobody has audited it. Before using it with anything important, read [what it protects and what it doesn't](#what-it-protects-and-what-it-doesnt).

[Installation](INSTALL.md) · [User manual](MANUAL.md) · [Working with agents](AGENTS-GUIDE.md) · [Limitations](#limitations)

## Versions

<table>
<tr>
<td width="50%" valign="top">

### Desktop

**Available** · Windows 10 and 11 with Docker Desktop

To use it on your own PC.

**Includes**

- One container per project, with its own files, sessions and ports
- Claude Code: with your subscription, in autonomous mode or with an API key
- Local models on your NVIDIA GPU, served by LM Studio or llama.cpp. Used with:
  - OpenCode: an agent inside the project
  - Open WebUI: a chat in the browser
- Outbound firewall: a proxy that only lets allowed domains through
- `iniciar.cmd`: checks the installation and opens a menu
- VS Code connected to the project

**Limitations**

- The launcher is Windows-only. On Linux it works without it; macOS is untested
- The local model server and Open WebUI are outside the firewall

</td>
<td width="50%" valign="top">

### Server

**In development** · Linux VM, for example on Proxmox

To free up your PC and work from any device.

**Will include**

- The same isolated projects, managed with a Linux script
- A shared local model, with no internet access
- Sessions that stay alive if the connection drops
- Remote access over Tailscale, without opening ports

**Limitations**

- You need to know how to run a Linux server
- Updates and backups are up to you
- Remote access adds attack surface

</td>
</tr>
</table>

## Get started

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and open it.
2. Download this repository (*Code → Download ZIP*) and unzip it.
3. Double-click `iniciar.cmd` → **N** (new project) → **1** (Claude Code).

Step-by-step guide, no commands: [INSTALL.md](INSTALL.md).

## What leaves your computer

![What leaves your computer in each mode. Connected: your code goes to Anthropic, better not use it with sensitive data. Local model: your prompts stay on your computer, but the agent can still upload data to GitHub; with care. Offline, in development: nothing goes over the network; the safest option.](docs/img/datos.svg)

| Mode | Status | What leaves your computer | Sensitive data |
|---|---|---|---|
| **Connected**: Claude Code | Available | Your code and your prompts go to Anthropic, which handles them under your account's terms. The agent can also push to GitHub and download from npm and PyPI | Better not |
| **Local model**: with OpenCode or Open WebUI | Available | Your prompts stay on your computer. But the project's container can still connect to GitHub, npm and PyPI, and llama.cpp downloads models from Hugging Face | With care |
| **Offline**: local model, no network | In development | Nothing goes over the network | The safest option, within the [limits](#what-it-protects-and-what-it-doesnt) below |

> [!WARNING]
> While the environment is connected to the internet, better not handle sensitive data: other people's personal data, company secrets, production credentials or customer information. The firewall limits where the agent can connect, but it doesn't stop it from sending data to the allowed destinations.

## Architecture

![Plan of the desktop version. On a Windows PC, Docker Desktop runs one container per project with Claude Code and OpenCode. The agents only go out through a proxy that lets through Anthropic, npm, PyPI, GitHub and VS Code; everything else is blocked. LM Studio, llama.cpp and Open WebUI are outside the firewall.](docs/img/arquitectura-escritorio.svg)

- The agents run in the project's container, as an unprivileged user. They can't see the Windows drive or the other projects.
- The agents have no DNS and no direct way out: everything goes through a proxy, running as another user, that filters by domain and checks the name of every encrypted connection.
- The firewall is applied before anything starts. If it isn't applied, or it doesn't block the test connections, the container doesn't start.
- The full list of allowed destinations is in [scripts/firewall.sh](scripts/firewall.sh). Add more with `FIREWALL_ALLOW` in `.env`.

![Planned design of the server version, in development. Your devices reach a Linux VM on Proxmox over Tailscale. Each project is an instance with its own firewall. They all use a shared local model through internal networks with no internet access. Only a separate downloader goes out to Hugging Face.](docs/img/arquitectura-servidor.svg)

Planned design for the server version. It isn't released yet.

## What it protects and what it doesn't

| Risk | Covered? | Why |
|---|---|---|
| The agent reading or deleting files on your PC | Yes | It only sees its project's files, not the Windows drive |
| One project reaching another | Yes | Each one has its own container and home folder, and the firewall blocks connections between them |
| The agent connecting anywhere | Yes | It only goes out through a proxy that filters by domain, even behind shared CDNs. See [limitations](#limitations) |
| The environment starting without the firewall | Yes | If it isn't applied, the container doesn't start |
| The agent getting administrator rights | Yes | It runs as an unprivileged user and can't escalate |
| A repository changing the agents' rules | Mostly | Claude Code and OpenCode ship with policies the repository can't change: no permissions, hooks or plugins. It can still give the agent instructions in its `CLAUDE.md`. See the [manual](MANUAL.md#10-security) |
| The agent breaking its own project | No | It can write to `/workspace`. Use git and push often |
| Data leaving through an allowed destination | No | If someone tricks the agent, for example with instructions hidden in a file or a web page, it could send data to GitHub or Anthropic |
| The agent stealing your credentials | Mostly | It never sees the API key: the proxy adds it. But it can use the key while it's configured, and use the project's GitHub token, which only gives access to the repositories you choose |
| A serious bug in Docker or the kernel | No | A container shares the system's kernel: it isolates less than a virtual machine |
| LM Studio, llama.cpp and Open WebUI | No | They don't go through the projects' firewall |

## Limitations

- **Platform.** Built for Windows 10 and 11 with Docker Desktop. On Linux the environment works (CI tests it), but there is no launcher. macOS is untested.
- **Language.** The launcher (`iniciar.cmd`) and the `ia` menu inside the projects are in Spanish. These docs quote their options as they appear on screen.
- **Domain allowlist.** The proxy is only as safe as its list: on each allowed destination, anything that site accepts can be uploaded (npm takes packages from anyone). Programs that don't use the proxy have no internet access. And the proxy decrypts the connection to PyPI, with a certificate unique to each project, to check which page is requested.
- **Unpinned versions.** Every build installs the latest Claude Code and OpenCode. A new version can break something, and a compromised package would get in without warning.
- **Local models.** The ones that fit on a home GPU do much worse than Claude on long tasks, and the recommended ones change every few months.
- **Docker Desktop.** It's paid for companies with more than 250 employees or more than 10 million dollars in annual revenue.
- **At work.** Check your company's policy on AI tools and on where its code may go.
- **Maintenance.** Maintained by one person, with no support. Tools in this field change every week and the project may fall behind.

## Alternatives

If this doesn't fit what you're looking for, one of these may suit you better:

| If you want | Look at | Keep in mind |
|---|---|---|
| More isolation: a lightweight virtual machine per agent | [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) | A Docker product; it asks you to sign in with a Docker account |
| Just Claude Code, inside VS Code | [Anthropic's dev container](https://code.claude.com/docs/en/devcontainer) | An official example, not a maintained image |
| To try local models without fuss | [LM Studio](https://lmstudio.ai) or [Ollama](https://ollama.com) | They serve the model, but they don't isolate the agent |
| Environments for a team | [Coder](https://coder.com) | More powerful, and more complex to maintain |

## License

[MIT](LICENSE).
