# claude-code-local-llm-docker

Agentes de IA de programación en Windows sin darles acceso al resto de tu ordenador: **Claude Code** con tu cuenta de Anthropic y **OpenCode** con un modelo local en tu propia GPU. Cada proyecto va en su propio contenedor de Docker, protegido por un cortafuegos. Solo hace falta instalar Docker Desktop.

> [!NOTE]
> Proyecto personal que mantiene una sola persona. Funciona y tiene pruebas automáticas, pero nadie lo ha auditado. Antes de usarlo con algo importante, lee [qué protege y qué no](#qué-protege-y-qué-no).

[Instalación](INSTALACION.md) · [Manual de uso](MANUAL.md) · [Cómo trabajar con agentes](GUIA-AGENTES.md) · [Limitaciones](#limitaciones)

## Versiones

<table>
<tr>
<td width="50%" valign="top">

### Escritorio

**Disponible** · Windows 10 y 11 con Docker Desktop

Para usarlo en tu propio PC.

**Incluye**

- Un contenedor por proyecto, con sus archivos, sesiones y puertos
- Claude Code: con tu suscripción, en modo autónomo o con clave de API
- OpenCode con un modelo local (LM Studio o llama.cpp, GPU NVIDIA)
- Open WebUI, opcional: chat con el modelo local en el navegador
- Cortafuegos de salida en lista blanca
- `iniciar.cmd`: comprueba la instalación y abre un menú
- VS Code conectado al proyecto

**Limitaciones**

- Lanzador solo para Windows. En Linux funciona sin él; en macOS no se ha probado
- El modelo local y Open WebUI quedan fuera del cortafuegos

</td>
<td width="50%" valign="top">

### Servidor

**En desarrollo** · VM Linux, por ejemplo en Proxmox

Para dejar libre tu PC y trabajar desde cualquier dispositivo.

**Incluirá**

- Los mismos proyectos aislados, gestionados con un script de Linux
- Un modelo local compartido, sin acceso a internet
- Sesiones que siguen vivas aunque se corte la conexión
- Acceso remoto por Tailscale, sin abrir puertos

**Limitaciones**

- Hay que saber mantener un servidor Linux
- Las actualizaciones y las copias de seguridad son cosa tuya
- El acceso remoto añade superficie de ataque

</td>
</tr>
</table>

## Empezar

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y ábrelo.
2. Descarga este repositorio (*Code → Download ZIP*) y descomprímelo.
3. Doble clic en `iniciar.cmd` → **N** (nuevo proyecto) → **1** (Claude Code).

Guía paso a paso, sin comandos: [INSTALACION.md](INSTALACION.md).

## Qué sale de tu equipo

![Qué sale de tu equipo en cada modo. Conectado: tu código va a Anthropic, mejor no usarlo con datos sensibles. Modelo local: las instrucciones no salen, pero el agente aún puede subir datos a GitHub; con cuidado. Sin internet, en desarrollo: nada sale por la red; lo más prudente.](docs/img/datos.svg)

| Modo | Estado | Qué sale de tu equipo | Datos sensibles |
|---|---|---|---|
| **Conectado**: Claude Code | Disponible | Tu código y tus instrucciones van a Anthropic, que los trata según las condiciones de tu cuenta. El agente también puede subir cosas a GitHub y descargar de npm y PyPI | Mejor no |
| **Modelo local**: OpenCode u Open WebUI con LM Studio o llama.cpp | Disponible | Las instrucciones no salen de tu equipo. Pero el contenedor del proyecto sigue pudiendo conectarse a GitHub, npm y PyPI, y llama.cpp descarga modelos de Hugging Face | Con cuidado |
| **Sin internet**: OpenCode con un modelo local, sin red | En desarrollo | Nada por la red | Lo más prudente, con los [límites](#qué-protege-y-qué-no) de abajo |

> [!WARNING]
> Con el entorno conectado a internet, mejor no tratar datos sensibles: datos personales de otras personas, secretos de empresa, credenciales de producción o información de clientes. El cortafuegos limita adónde se conecta el agente, pero no impide que envíe datos a los destinos permitidos.

## Arquitectura

![Plano de la versión escritorio. En un PC con Windows, Docker Desktop ejecuta un contenedor por proyecto con Claude Code y OpenCode. Su cortafuegos solo deja salir a Anthropic, npm, PyPI, GitHub, OpenCode y VS Code; el resto se bloquea. LM Studio, llama.cpp y Open WebUI quedan fuera del cortafuegos.](docs/img/arquitectura-escritorio.svg)

- Los agentes se ejecutan en el contenedor del proyecto, con un usuario sin privilegios. No ven el disco de Windows ni los demás proyectos.
- El cortafuegos se aplica antes de arrancar nada. Si no se aplica, o si no bloquea una conexión de prueba, el contenedor no arranca.
- La lista completa de destinos permitidos está en [scripts/firewall.sh](scripts/firewall.sh). Se amplía con `FIREWALL_ALLOW` en `.env`.

![Plano previsto de la versión servidor, en desarrollo. Tus dispositivos entran por Tailscale a una VM Linux en Proxmox. Cada proyecto es una instancia con su propio cortafuegos. Todas usan un modelo local compartido por redes internas sin salida a internet. Solo un descargador aparte sale a Hugging Face.](docs/img/arquitectura-servidor.svg)

Diseño previsto para la versión servidor. Todavía no está publicado.

## Qué protege y qué no

| Riesgo | ¿Cubierto? | Por qué |
|---|---|---|
| Que el agente lea o borre archivos de tu PC | Sí | Solo ve los archivos de su proyecto, no el disco de Windows |
| Que un proyecto llegue a otro | Sí | Cada uno tiene su contenedor y su carpeta personal, y el cortafuegos bloquea las conexiones entre ellos |
| Que el agente se conecte a cualquier sitio | En gran parte | Solo llega a la lista blanca. Ver [lista blanca por IP](#limitaciones) |
| Que el entorno arranque sin cortafuegos | Sí | Si no se aplica, el contenedor no arranca |
| Que el agente consiga permisos de administrador | Sí | Corre como usuario sin privilegios y no puede escalarlos |
| Que un repositorio cambie las reglas de los agentes | En gran parte | Claude Code y OpenCode traen políticas que el repositorio no puede cambiar. Ver [MANUAL](MANUAL.md#10-seguridad) |
| Que el agente estropee su proyecto | No | Puede escribir en `/workspace`. Usa git y sube los cambios a menudo |
| Que salgan datos por un destino permitido | No | Si alguien engaña al agente, por ejemplo con instrucciones ocultas en un fichero o en una web, podría enviar datos a GitHub o a Anthropic |
| Que el agente use tus credenciales | En parte | La clave de API solo la recibe Claude Code con API. La sesión de GitHub sí la puede usar: mejor un token limitado a los repositorios del proyecto |
| Un fallo grave de Docker o del núcleo | No | Un contenedor comparte el núcleo del sistema: aísla menos que una máquina virtual |
| LM Studio, llama.cpp y Open WebUI | No | No pasan por el cortafuegos de los proyectos |

## Limitaciones

- **Plataforma.** Pensado para Windows 10 y 11 con Docker Desktop. En Linux el entorno funciona (lo prueba la CI), pero no hay lanzador. En macOS no se ha probado.
- **Lista blanca por IP.** Los dominios permitidos se convierten en direcciones IP al arrancar. Si un servicio cambia de IP, deja de conectar hasta reiniciar el proyecto. Y como varias webs pueden compartir la IP de una CDN, permitir una puede dejar pasar otras.
- **Versiones sin fijar.** Cada construcción instala la última versión de Claude Code y OpenCode. Una versión nueva puede romper algo, y un paquete comprometido entraría sin aviso.
- **Modelos locales.** Los que caben en una GPU doméstica rinden bastante menos que Claude en tareas largas, y los recomendados cambian cada pocos meses.
- **Docker Desktop.** Es de pago en empresas de más de 250 empleados o de más de 10 millones de dólares de facturación anual.
- **En el trabajo.** Consulta la política de tu empresa sobre herramientas de IA y sobre dónde puede estar su código.
- **Mantenimiento.** Lo mantiene una persona, sin soporte. Las herramientas de este campo cambian cada semana y el proyecto puede quedarse atrás.

## Alternativas

Si esto no encaja con lo que buscas, puede que te sirva mejor alguna de estas:

| Si buscas | Mira | A tener en cuenta |
|---|---|---|
| Más aislamiento: una máquina virtual ligera por agente | [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) | Producto de Docker; pide iniciar sesión con una cuenta de Docker |
| Solo Claude Code, dentro de VS Code | [Dev container de Anthropic](https://code.claude.com/docs/en/devcontainer) | Ejemplo oficial, no una imagen mantenida |
| Probar modelos locales sin complicarte | [LM Studio](https://lmstudio.ai) u [Ollama](https://ollama.com) | Sirven el modelo, pero no aíslan al agente |
| Entornos para un equipo con varias personas | [Coder](https://coder.com) | Más potente y más complejo de mantener |

## Licencia

[MIT](LICENSE).
