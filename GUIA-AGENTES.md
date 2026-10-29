# Cómo trabajar con agentes

Un **agente** es una IA que no solo responde: lee tu proyecto, escribe código, ejecuta comandos, prueba lo que ha hecho y corrige sus errores hasta terminar la tarea. Claude Code y OpenCode son agentes. Esta guía resume cómo trabaja la gente que les saca partido.

1. [La idea básica](#1-la-idea-básica)
2. [El ciclo de trabajo](#2-el-ciclo-de-trabajo)
3. [Cómo pedir las cosas](#3-cómo-pedir-las-cosas)
4. [CLAUDE.md: las instrucciones del proyecto](#4-claudemd-las-instrucciones-del-proyecto)
5. [Permisos: normal o autónomo](#5-permisos-normal-o-autónomo)
6. [Git: tu red de seguridad](#6-git-tu-red-de-seguridad)
7. [Qué agente y qué modelo usar](#7-qué-agente-y-qué-modelo-usar)
8. [Varios agentes a la vez](#8-varios-agentes-a-la-vez)
9. [Errores típicos](#9-errores-típicos)
10. [Comandos útiles de Claude Code](#10-comandos-útiles-de-claude-code)

## 1. La idea básica

Trata al agente como a una persona nueva en el equipo, muy rápida y con mucho conocimiento, pero que **no sabe nada de tu proyecto** hasta que lo lee y que **a veces se equivoca con total seguridad**. Funciona mejor cuando:

- sabe qué quieres conseguir y por qué,
- tiene una forma de comprobar si lo ha hecho bien (pruebas, abrir la web, ejecutar el programa),
- trabaja en un sitio donde equivocarse no rompe nada.

Este entorno se ocupa de lo último: cada proyecto está aislado en su contenedor, con un cortafuegos, y el agente no puede tocar el resto de tu ordenador.

## 2. El ciclo de trabajo

Casi todo el mundo trabaja en este ciclo, repetido muchas veces al día:

1. **Pedir una tarea concreta.** "Añade un formulario de contacto a la página de inicio", no "mejora la web".
2. **Dejar que planifique** si la tarea es grande. En Claude Code, pulsa `Shift+Tab` hasta *plan mode*: el agente investiga y propone un plan sin tocar nada. Corrígelo antes de que empiece.
3. **Dejar que trabaje.** Escribe código, lo ejecuta y lo prueba.
4. **Revisar el resultado.** Pruébalo tú (abre la web, ejecuta el programa) y mira qué ha cambiado: pídele "resume qué has cambiado" o mira el diff en VS Code.
5. **Guardar con git** si te gusta ("haz commit de esto"), o pedir cambios si no.

Tareas pequeñas y frecuentes funcionan mucho mejor que una tarea enorme.

## 3. Cómo pedir las cosas

| En vez de… | Mejor… |
|---|---|
| "Arregla el error" | "Al pulsar *Enviar* en el formulario sale `TypeError: x is undefined` en la consola. Encuentra la causa y arréglalo" |
| "Haz una web" | "Crea una web de una sola página para mi panadería con React y Vite: portada, horario y un mapa. Arráncala en el puerto 5173" |
| "Mejora el código" | "El archivo `pedidos.js` tiene funciones muy largas. Divídelas sin cambiar el comportamiento y comprueba que las pruebas siguen pasando" |

Consejos:

- **Da contexto:** qué quieres, para quién y qué no quieres que toque.
- **Dile cómo comprobarlo:** "ejecuta las pruebas", "comprueba que la página carga sin errores".
- **Pega los errores completos**, no los resumas.
- **Pregunta antes de pedir** si no sabes cómo se hace algo: "¿qué opciones hay para añadir un login? Explícamelas antes de hacer nada".
- **Si se atasca o da vueltas**, para (`Esc`), explícale lo que ves y redirígelo. A veces es mejor empezar una conversación nueva (`/clear`) con lo aprendido.

## 4. CLAUDE.md: las instrucciones del proyecto

El agente lee el archivo `CLAUDE.md` del proyecto **cada vez que empieza**. Es la forma más eficaz de que trabaje bien: ahí va lo que le dirías a alguien nuevo el primer día.

- Cómo se arranca y cómo se prueba el proyecto.
- Normas: idioma, estilo, qué librerías usar o evitar.
- Cosas que no debe hacer ("no toques la carpeta `legacy/`").

Los proyectos nuevos de este entorno empiezan con una plantilla. Si clonas un repositorio sin `CLAUDE.md`, pídele a Claude Code `/init` y lo genera a partir del código. Cuando el agente cometa el mismo error dos veces, añade la norma a `CLAUDE.md`.

OpenCode usa `AGENTS.md` y, si no existe, también lee `CLAUDE.md`.

## 5. Permisos: normal o autónomo

- **Claude Code (opción 1):** pide permiso antes de editar archivos o ejecutar comandos. Ideal para empezar y entender qué hace. En este entorno, «Sí, y no volver a preguntar» no se guarda para siempre: así un repositorio tampoco puede dejar comandos aprobados. Para que no pregunte por cada edición, pulsa `Shift+Tab` hasta *accept edits*.
- **Claude Code autónomo (opción 2):** no pide permiso. Es como trabaja mucha gente con tareas largas, pero **solo con proyectos y repositorios de confianza**. El aislamiento protege tu ordenador, pero no impide que unas instrucciones escondidas en un archivo, un issue o una web (*prompt injection*) engañen al agente para que borre cosas o envíe tu código a GitHub o a otra API permitida.
- **OpenCode local (opción 3):** pide permiso antes de editar archivos o ejecutar comandos, como Claude Code. Dentro puedes activar la aprobación automática; aplica el mismo criterio que con el modo autónomo.

Aunque uses el modo autónomo, **revisa siempre el resultado** antes de guardarlo y subirlo.

Regla práctica: si el agente va a leer algo que no has escrito tú (un repositorio ajeno, una web, issues de desconocidos), usa el modo que pide permiso.

## 6. Git: tu red de seguridad

Git guarda versiones de tu proyecto. Con agentes es imprescindible porque permite deshacer cualquier cosa. No hace falta saber usarlo: el agente lo hace por ti si se lo pides.

- **Antes de una tarea grande:** "haz commit de lo que hay".
- **Para probar algo arriesgado:** "crea una rama nueva para esto".
- **Si algo sale mal:** "deshaz los cambios desde el último commit".
- **Para guardarlo de verdad:** conecta GitHub (opción 6) y pide "sube los cambios a GitHub". Lo que solo está en el contenedor se pierde si borras el proyecto.

## 7. Qué agente y qué modelo usar

| Opción | Cuándo | Coste |
|---|---|---|
| Claude Code con tu cuenta | Lo más capaz y lo más usado. Para casi todo | Incluido en Claude Pro, Max o Team |
| Claude Code con API | Uso puntual o automatizado, sin suscripción | Pago por uso |
| Modelo local con OpenCode | Agente cuyas instrucciones no salen de tu PC. Tareas sencillas | Gratis (usa tu tarjeta gráfica) |
| Modelo local con Open WebUI | Chat en el navegador para preguntar, redactar o resumir. No es un agente: no toca el proyecto | Gratis (usa tu tarjeta gráfica) |

Los modelos locales son bastante menos capaces que los de la nube: úsalos para tareas acotadas y con un `CLAUDE.md` claro.

## 8. Varios agentes a la vez

Cuando ya te manejas, puedes tener varios agentes trabajando en paralelo:

- **En proyectos distintos:** cada uno en su contenedor, sin interferir. Abre cada proyecto desde `iniciar.cmd`.
- **En el mismo proyecto:** abre varias pestañas de Claude Code, pero dales tareas que no toquen los mismos archivos, o pide a cada uno que trabaje en su propia rama con `git worktree`.

Revisar el trabajo de varios agentes cansa: empieza con uno y añade más cuando el ciclo te resulte natural.

## 9. Errores típicos

- **Aceptar sin mirar.** El agente puede decir "listo, funciona" y no ser verdad. Pruébalo tú.
- **Conversaciones eternas.** Con mucho historial el agente se despista. Una tarea, una conversación; usa `/clear` al cambiar de tema.
- **Pedir demasiado de golpe.** Divide en pasos que puedas revisar.
- **No usar git.** Sin commits no hay forma fácil de volver atrás.
- **Pegar contraseñas o claves en el chat o en el código.** Van en `.env` y nunca se suben a GitHub.
- **Desactivar el cortafuegos para que algo funcione.** Mejor añade solo el dominio que falta a `FIREWALL_ALLOW`.

## 10. Comandos útiles de Claude Code

| Comando | Qué hace |
|---|---|
| `Shift+Tab` | Cambia de modo: normal, aceptar ediciones, *plan mode* |
| `Esc` | Interrumpe al agente para corregirlo |
| `Esc` `Esc` | Vuelve a un mensaje anterior de la conversación |
| `/init` | Crea o completa `CLAUDE.md` a partir del código |
| `/clear` | Empieza una conversación nueva |
| `/compact` | Resume la conversación para liberar espacio |
| `/model` | Cambia de modelo |
| `/help` | Lista todos los comandos |
| `ia claude -c` | (en la terminal) Continúa la última conversación |
