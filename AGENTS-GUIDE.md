# Working with agents

An **agent** is an AI that does more than answer: it reads your project, writes code, runs commands, tests what it has done and fixes its own mistakes until the task is finished. Claude Code and OpenCode are agents. This guide sums up how the people who get the most out of them work.

1. [The basic idea](#1-the-basic-idea)
2. [The work loop](#2-the-work-loop)
3. [How to ask](#3-how-to-ask)
4. [CLAUDE.md: the project's instructions](#4-claudemd-the-projects-instructions)
5. [Permissions: normal or autonomous](#5-permissions-normal-or-autonomous)
6. [Git: your safety net](#6-git-your-safety-net)
7. [Which agent and which model](#7-which-agent-and-which-model)
8. [Several agents at once](#8-several-agents-at-once)
9. [Common mistakes](#9-common-mistakes)
10. [Useful Claude Code commands](#10-useful-claude-code-commands)

## 1. The basic idea

Treat the agent like a new member of the team: very fast and very knowledgeable, but it **knows nothing about your project** until it reads it, and it is **sometimes wrong with complete confidence**. It works best when:

- it knows what you want to achieve and why,
- it has a way to check that it got it right (tests, opening the website, running the program),
- it works somewhere a mistake doesn't break anything.

This environment takes care of the last one: each project is isolated in its container, behind a firewall, and the agent can't touch the rest of your computer.

## 2. The work loop

Almost everyone works in this loop, many times a day:

1. **Ask for a specific task.** "Add a contact form to the home page", not "improve the website".
2. **Let it plan** if the task is big. In Claude Code, press `Shift+Tab` until *plan mode*: the agent investigates and proposes a plan without touching anything. Correct it before it starts.
3. **Let it work.** It writes the code, runs it and tests it.
4. **Review the result.** Try it yourself (open the website, run the program) and look at what changed: ask it to "summarise what you changed", or look at the diff in VS Code.
5. **Save it with git** if you like it ("commit this"), or ask for changes if you don't.

Small, frequent tasks work much better than one huge task.

## 3. How to ask

| Instead of… | Better… |
|---|---|
| "Fix the bug" | "When I click *Send* on the form, the console shows `TypeError: x is undefined`. Find the cause and fix it" |
| "Make a website" | "Create a one-page website for my bakery with React and Vite: a front page, opening hours and a map. Start it on port 5173" |
| "Improve the code" | "The file `orders.js` has very long functions. Split them up without changing the behaviour and check that the tests still pass" |

Tips:

- **Give context:** what you want, who it's for, and what you don't want it to touch.
- **Tell it how to check:** "run the tests", "check that the page loads without errors".
- **Paste whole errors**, don't summarise them.
- **Ask before you ask for it** if you don't know how something is done: "what are the options for adding a login? Explain them before doing anything".
- **If it gets stuck or goes round in circles**, stop it (`Esc`), explain what you see and steer it. Sometimes it's better to start a new conversation (`/clear`) with what you've learnt.

## 4. CLAUDE.md: the project's instructions

The agent reads the project's `CLAUDE.md` file **every time it starts**. It's the most effective way to make it work well: it holds what you would tell someone new on their first day.

- How to start and test the project.
- Rules: language, style, which libraries to use or avoid.
- Things it must not do ("don't touch the `legacy/` folder").

New projects in this environment start with a template. If you clone a repository without a `CLAUDE.md`, ask Claude Code for `/init` and it writes one from the code. When the agent makes the same mistake twice, add the rule to `CLAUDE.md`.

OpenCode uses `AGENTS.md` and, if there isn't one, reads `CLAUDE.md` too.

## 5. Permissions: normal or autonomous

- **Claude Code (option 1):** asks for permission before editing files or running commands. Ideal to start with and to understand what it does. In this environment, "Yes, and don't ask again" isn't saved for good: that way a repository can't leave commands approved either. To stop it asking about every edit, press `Shift+Tab` until *accept edits*.
- **Autonomous Claude Code (option 2, *Claude Code autónomo*):** doesn't ask for permission. It's how many people work on long tasks, but **only with projects and repositories you trust**. The isolation protects your computer, but it doesn't stop instructions hidden in a file, an issue or a web page (*prompt injection*) from tricking the agent into deleting things or sending your code to GitHub or another allowed API.
- **OpenCode local (option 3):** asks for permission before editing files or running commands, like Claude Code. Inside, you can turn on automatic approval; use the same judgement as with autonomous mode.

Even in autonomous mode, **always review the result** before you save and push it.

Rule of thumb: if the agent is going to read something you didn't write (someone else's repository, a website, issues from strangers), use the mode that asks for permission.

## 6. Git: your safety net

Git keeps versions of your project. With agents it's essential, because it lets you undo anything. You don't need to know how to use it: the agent does it for you if you ask.

- **Before a big task:** "commit what's there".
- **To try something risky:** "create a new branch for this".
- **If something goes wrong:** "undo the changes since the last commit".
- **To really keep it:** connect GitHub (option 6, *Conectar GitHub*) and ask it to "push the changes to GitHub". Whatever is only in the container is lost if you delete the project.

## 7. Which agent and which model

| Option | When | Cost |
|---|---|---|
| Claude Code with your account | The most capable and the most used. For almost everything | Included in Claude Pro, Max or Team |
| Claude Code with the API | Occasional or automated use, without a subscription | Pay per use |
| Local model with OpenCode | An agent whose prompts don't leave your PC. Simple tasks | Free (uses your graphics card) |
| Local model with Open WebUI | A chat in the browser to ask, write or summarise. It isn't an agent: it doesn't touch the project | Free (uses your graphics card) |

Local models are much less capable than the ones in the cloud: use them for well-defined tasks, with a clear `CLAUDE.md`.

## 8. Several agents at once

Once you're comfortable, you can have several agents working in parallel:

- **In different projects:** each one in its own container, without getting in each other's way. Open each project from `iniciar.cmd`.
- **In the same project:** open several Claude Code tabs, but give them tasks that don't touch the same files, or ask each one to work on its own branch with `git worktree`.

Reviewing the work of several agents is tiring: start with one and add more when the loop feels natural.

## 9. Common mistakes

- **Accepting without looking.** The agent may say "done, it works" when it doesn't. Try it yourself.
- **Endless conversations.** With a long history the agent loses focus. One task, one conversation; use `/clear` when you change subject.
- **Asking for too much at once.** Split it into steps you can review.
- **Not using git.** Without commits there's no easy way back.
- **Pasting passwords or keys into the chat or the code.** They go in `.env` and are never pushed to GitHub.
- **Turning off the firewall to make something work.** Better to add just the missing domain to `FIREWALL_ALLOW`.

## 10. Useful Claude Code commands

| Command | What it does |
|---|---|
| `Shift+Tab` | Switches mode: normal, accept edits, *plan mode* |
| `Esc` | Interrupts the agent so you can correct it |
| `Esc` `Esc` | Goes back to an earlier message in the conversation |
| `/init` | Creates or completes `CLAUDE.md` from the code |
| `/clear` | Starts a new conversation |
| `/compact` | Summarises the conversation to free up space |
| `/model` | Changes the model |
| `/help` | Lists all the commands |
| `ia claude -c` | (in the terminal) Continues the last conversation |
