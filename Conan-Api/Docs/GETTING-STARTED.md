# Getting started — your first plugin

*Portuguese translation: [COMECAR.pt.md](COMECAR.pt.md)*

You need: a C++ compiler that produces a 64-bit Windows DLL, and a Conan Exiles
Enhanced server. You don't need the Unreal editor or a developer account.

Most people doing this are on Windows, so start there:

**Visual Studio 2017, 2019 or 2022** (the free Community edition is enough).
Install the "Desktop development with C++" workload. New project → **Dynamic-Link
Library (DLL)**, platform **x64**, and set
*C/C++ → Code Generation → Runtime Library* to **/MT**.

That last setting matters more than it looks. With **/MD** your DLL depends on
the Visual C++ redistributable being installed on the machine running the
server — and that machine is often a rented box, or a container under Wine,
where it isn't. The symptom is `LoadLibrary` failing with a generic code that
explains nothing. **/MT** links the runtime in and the question never comes up.

**x64 is not optional** either: a 32-bit DLL simply won't load.

If you'd rather build from a Linux box or from WSL, mingw-w64 does the same job:

```bash
sudo apt-get install -y mingw-w64        # Debian/Ubuntu
```

Every example folder ships **both**: a `compilar.bat` for Windows, which finds
`cl.exe` or `g++` and builds, and a `compilar.sh` for Linux and WSL. On Windows,
open the *x64 Native Tools Command Prompt for VS* from the Start menu, `cd` into
the example, and run `compilar.bat`.

---

## 1. Install the loader on the server

The Conan server has no plugin system. The loader gets in through the Windows
DLL search order: an executable looks for its DLLs **in its own folder** first.
A `winmm.dll` of ours sitting in there gets loaded instead of the system one,
and runs inside the game process.

> **Before you install, know what you're installing.** The loader and every
> plugin run **inside your server's process**, with full access to the game's
> memory, to player data, to the disk and to the machine's network. There's no
> sandbox — there can't be one, because the whole point of the API is to give
> access to the game's reflection. Only install plugins from people you trust,
> ideally with the source out in the open so you can compile it yourself. The
> detail is in `LEIA-ME`, section "Antes de instalar plugin de terceiro".

**The `winmm.dll` ships ready-made in the package** — it's at the root of what
you downloaded, one level **above** the `Conan-Api/` folder:

```
what you downloaded/
   winmm.dll          <- HERE. This is the loader, already compiled.
   Conan-Api/         <- everything else
```

You don't have to compile anything to install it. The `winmm.dll` comes
compiled and checked: `VERSAO.txt` carries its sha256, and the loader's log says
which version came up. What it does on the inside is written up in
`Docs/README.md` — no code reading required.

**Don't skip this part.** Without the `winmm.dll` in the right place, the server
comes up normally, with no plugins at all and **no error message** — the hardest
failure to diagnose this project has.

Copy into `<server>/ConanSandbox/Binaries/Win64/`:

| what | where it comes from |
|---|---|
| `winmm.dll` | **ships ready-made** at the root of the package |
| `winmm_orig.dll` | the **real** system winmm.dll, renamed |
| `Conan-Api/` | the single folder with everything inside |

Only `winmm.dll` sits loose — it **has** to be next to the executable, that's
how it gets into the process. Everything else lives inside `Conan-Api`, and the
API creates the subfolders itself on first run:

```
Win64/
   ConanSandboxServer-Win64-Shipping.exe
   winmm.dll            <- the loader
   winmm_orig.dll       <- the system's original, renamed
   Conan-Api/
      Plugins/          the plugin DLLs
      Config/           one file per plugin
      Dados/            databases and state
      Logs/             ConanLoader.log and ConanApi.log
```

One single folder instead of files scattered across the server tree: whoever
installs copies one thing, and whoever uninstalls deletes one thing. Scattering
guarantees somebody copies half of it and then can't work out why it won't run.

`winmm_orig.dll` isn't optional. The game imports the real winmm; if its
functions go missing, the executable won't start — and it fails before any log,
without saying why.

### Running under Wine (Linux)

Wine has a winmm of its own and prefers it to the one in the game folder.
Without this the server comes up **normally, with no plugins and no error** —
the worst kind of failure:

```bash
export WINEDLLOVERRIDES="winmm=n,b"
```

`n,b` = try the native one (ours) first, fall back to the builtin if it's
missing.

### Checking that it worked

Start the server and look at `ConanLoader.log`, next to the executable:

```
== ConanLoader iniciado ==
reflexao de pe: 318985 objetos vivos
  [ok] ExemploOla.dll
== 1 plugin(s) carregado(s), 0 com falha ==
```

If you get `ABORTADO: a reflexao nao respondeu`, the anchors don't match — see
[when the game updates](#when-the-game-updates).

---


## Installing a plugin — drag the folder in

Each plugin is **one folder**, with everything it needs inside. To install, you
drag the folder into `Conan-Api/Plugins/` and restart the server.

```
Conan-Api/
   Plugins/
      Permission/               <- ships in the package, it's the default one
         ConanPermission.dll
         config.json
      PluginYouDownloaded/      <- you dragged this folder in
         PluginYouDownloaded.dll
         config.json
         (database, tables, whatever it needs — all in here)
```

**There's no config file to edit and no list to switch on.** The folder being
there is the installation. The loader scans `Plugins/`, goes into each folder
and loads the DLL it finds.

| you want to | you do |
|---|---|
| install | drag the folder into `Plugins/` |
| uninstall | delete the folder |
| turn it off without deleting it | create an empty file called `DESLIGADO` inside the folder |
| see what happened | `Conan-Api/Logs/ConanLoader.log` |

**Which DLL the loader picks**, if the folder has more than one: it looks first
for one named after the folder (`MyPlugin/MyPlugin.dll`); if there isn't one and
there's only a single DLL, it uses that. If there are two and neither is named
after the folder, it **refuses** and says in the log which one to rename —
picking "the first one" would be an invisible decision that changes with
filesystem ordering.

**Every plugin gets its own space.** One plugin's `config.json` doesn't collide
with another's, and one plugin's database doesn't end up in its neighbour's
folder. Two plugins can have files with the same name and never trip over each
other.


## Keeping your VIPs in MySQL (optional — almost nobody needs this)

The `Permission` plugin is the one that keeps track of **who's VIP, who's admin
and who can do what**. By default it keeps that in a file right next to itself
(`permission.db`). That file works on its own: nothing to install, nothing to
configure, and it's the right answer for the vast majority of servers.

You only gain something by switching to MySQL in **two** cases:

| what you have | worth it? |
|---|---|
| one server only | **no.** Leave it alone. All you gain is more things that can go wrong |
| two or more servers, and you want the same VIP to count on all of them | yes |
| a website/panel that already reads your players out of a MySQL | yes |

> **Read on a forum that "MySQL is better"?** For a single server, it isn't. The
> local file is faster (no network in the way), doesn't go down, has no password
> to get wrong and doesn't disappear when the other computer shuts off. MySQL's
> advantage is **one place for several servers** — if you don't have several,
> there's no advantage.

### Before you touch it: what doesn't happen

The legitimate fear is "what if the database goes down, my server hangs and the
players get dropped?".

It doesn't happen, and that was measured, not promised: **the thing talking to
MySQL is a separate worker thread, never the game's.** The test suite abuses
MySQL three ways with the plugin live — kills the connection from outside, cuts
the network in the middle of an operation, and swaps in a database that takes 2
seconds to answer every query — and in all three the game loop keeps the same
rhythm. What happens is that `Permission` goes **absent**, as if it weren't
installed, and every plugin that depended on it falls back to the default it
picked for itself. Nobody gets disconnected, nothing hangs.

And it **tries to come back on its own**, waiting a bit longer each time (5 s,
10 s, 20 s… up to 5 minutes), **re-reading `config.json` on every attempt**.
That's what lets you fix the wrong password in the file, save, and have the
plugin come up by itself — **without restarting the game server**, which costs 6
to 9 minutes with nobody able to get in.

### What you need to have ready

Two things — a drawer and a user — created **in MySQL**, not here. If you don't
know how to do that, whoever looks after your MySQL does: send them the block
below, swapping in your own database name and password:

```sql
CREATE DATABASE IF NOT EXISTS conan_permission CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'conan'@'%' IDENTIFIED BY 'the-password-you-choose';
GRANT ALL ON conan_permission.* TO 'conan'@'%';
FLUSH PRIVILEGES;
```

The first line creates the **drawer** where the data will live. The second
creates the **user** who'll open that drawer. The third gives them the key — **to
that drawer only**. The fourth tells MySQL to make what you just did take effect.
The tables inside it, the plugin creates by itself the first time it starts.

> **In that order, and don't skip the `CREATE USER`.** On old MySQL you could
> skip it — `GRANT` created the user for you. **On MySQL 8 that's over**: a
> `GRANT` without an existing user answers
> `ERROR 1410: You are not allowed to create a user with GRANT`. Checked on
> MySQL 8.4.11; the block above was also run on MySQL 5.7.44 and on
> MariaDB 10.11, and passed on all three.

**Don't use the `root` user.** It opens the whole database; the plugin only
needs one drawer. If somebody gets their hands on that server, the difference
between the two is how big the damage is.

### Where to change it

One file only: `Conan-Api/Plugins/Permission/config.json`. The keys are already
there, empty, waiting for you:

```json
  "Database": "sqlite",
  "MysqlHost": "127.0.0.1",
  "MysqlPort": 3306,
  "MysqlUser": "",
  "MysqlPass": "",
  "MysqlDB": "",
```

It becomes this:

```json
  "Database": "mysql",
  "MysqlHost": "127.0.0.1",
  "MysqlPort": 3306,
  "MysqlUser": "conan",
  "MysqlPass": "the-password-you-choose",
  "MysqlDB": "conan_permission",
```

| key | what it is |
|---|---|
| `Database` | `sqlite` (local file, the default) or `mysql`. Nothing else |
| `MysqlHost` | where MySQL is. **Same machine? use `127.0.0.1`** |
| `MysqlPort` | the port number. `3306` is the normal one — only change it if you were told otherwise |
| `MysqlUser` | the user you created up above |
| `MysqlPass` | their password |
| `MysqlDB` | the name of the drawer you created (`conan_permission` in the example) |

Save, restart the server **once**, and look at `Conan-Api/Logs/ConanApi.log`.
It worked when this shows up:

```
[permission] banco: MySQL em 127.0.0.1:3306, banco 'conan_permission', usuario 'conan' (prazos: 5000 ms para conectar, 10000 ms por operacao)
[permission] MySQL: pronto (8.4.11, utf8mb4, sem NO_BACKSLASH_ESCAPES)
[permission] instantaneo #1: 4 grupo(s), 0 jogador(es), 2 no(s) no padrao
```

> **Why `127.0.0.1` and not `localhost`?** They're the same machine, but
> `localhost` on Windows sometimes tries a path that doesn't exist first and
> takes a few seconds before trying the right one. `127.0.0.1` goes straight
> there.

### Three traps that catch everyone

**1. A trailing space, out of copy-and-paste.** You select the password or the
address on your provider's site, the mouse grabs a space along with it, and you
paste. The value looks right — **a space doesn't show up on screen**. The plugin
refuses it and shows the value in brackets, so the space becomes visible:

```
"MysqlHost" termina com ESPACO. (...) Entre colchetes ele fica visivel:
[127.0.0.1 ] tem 10 caracteres; o certo e [127.0.0.1], com 9.
```

Delete the space. (In the **password** it doesn't refuse: a password with a
space in it can be a real password.)

**2. Quotes around the port number.** `"MysqlPort": "3306"` with quotes works
the same as `3306` without them — don't worry about that. What **doesn't** work
is writing a word where the number goes; then it tells you that's text and that
it needs the number.

**3. `MySQL` with capitals.** `"mysql"`, `"MySQL"`, `"MYSQL"` — all fine.
But **`"mysqll"` with two L's isn't**, and the plugin **stops** instead of
guessing. That's on purpose: if it quietly fell back to the local file, your
VIPs would go somewhere you're not looking, and you'd only find out weeks later,
searching MySQL and coming up empty.

### When the log complains

Every error message from this plugin says **what's wrong** and **what to do**.
In `ConanApi.log`, look for the line that starts with `[permission]`, just above
that frame of `###`:

| the log says | what happened | what to do |
|---|---|---|
| `recusou o login do usuario 'x'` | wrong user or password | check `MysqlUser` and `MysqlPass`. Check for a trailing space |
| `entrou no MySQL, mas nao conseguiu abrir o banco` | the drawer doesn't exist, or the user doesn't have its key | run the two lines of SQL **the log itself writes out**, ready to copy |
| `nao ha nada escutando na porta 3306` | MySQL is stopped, or it's on another port | start MySQL, or fix `MysqlPort` |
| `nao consegui resolver o endereco 'x'` | the name doesn't exist, or it's misspelled | check `MysqlHost`. Same machine? use `127.0.0.1` |
| `sem "MysqlUser"` / `sem "MysqlDB"` | you left the key empty | fill it in. It doesn't choose for you, on purpose |
| `nao e um numero de porta — isso e texto` | you wrote a word in the port | write the number: `"MysqlPort": 3306` |

And one error that shows up **in MySQL**, not in the plugin's log, while you're
creating the user:

| MySQL says | what happened | what to do |
|---|---|---|
| `ERROR 1410: You are not allowed to create a user with GRANT` | you ran the `GRANT` without creating the user first | run the `CREATE USER` first — it's the second of the four lines up above |
| `ERROR 1044 / 1045` when testing in the MySQL client | the password or the user don't match | redo the `CREATE USER`, with single quotes exactly like the example |

**None of this brings the game server down.** In every one of these cases the
players keep playing; only `Permission` stays absent until you fix the file.

### If your MySQL is 8.0 or newer

Nothing to do in most cases — it was tested against **MySQL 8.4.11** and
connected with no configuration at all. There's one case where MySQL demands a
login method that needs a key MySQL itself won't hand over without an encrypted
connection; if that happens, **the log writes the exact line of SQL** that fixes
it. Copy it, run it in MySQL, done — you don't need to understand the subject.

**You don't need to install anything for MySQL to work here.** There's no DLL to
download and no "connector" to install: the plugin talks to MySQL on its own. If
somebody tells you to download a file for this, it isn't from this plugin.

### Going back

Switch `"Database"` back to `"sqlite"` and restart. The data you already had in
the local file **is still there**, untouched — switching databases doesn't erase
the other one.

What **doesn't** happen by itself is the data moving from one to the other: what
you wrote into MySQL stays in MySQL, what was in the file stays in the file.
There's no automatic import, and that's better — merging two VIP lists by
guessing which one counts is the kind of help that ruins things.

---

## Want to write a plugin? That's another download

This package is the **server** one: it makes plugins run. If you want to *write*
one, download the **SDK** — headers, six examples with source, and the build
guide. They're separate on purpose: running a server needs no compiler and no
headers at all, and writing a plugin needs none of the server binaries.

If you do both, download both.

## Mistakes worth knowing about

**The plugin doesn't load and nothing shows up in the log.** Check that the
exported function is called exactly `ConanPluginCarregar` and is inside
`extern "C"`. Without that the loader can't find it and logs
`nao exporta ConanPluginCarregar()`.

**A value comes out absurd.** An offset probably moved — the game updated.
Regenerate. An absurd value is the good symptom; the bad one is the plausible,
wrong value.

**The server crashes while loading the plugin.** The loader **contains** a
plugin crash during load — on MinGW **and** on MSVC, with an SEH scope table
(`__C_specific_handler`) on a dedicated thread. The server comes up without the
plugin and the reason goes to `ConanLoader.log`. What is **not** contained is a
crash that happens **inside a hook**: there the plugin's code runs on the game
thread, outside the guard, and can take the server down. Use
`g_api->Legivel(ptr, n)` before following a pointer of doubtful origin,
especially inside a hook.

**It worked in `curl`/in the test and not in the game.** Compiling proves
nothing. Only the log of the running server proves anything.

---

## Uninstalling, and being careful with `winmm.dll`

Uninstalling means undoing the three things the install did — and the order
matters, because the `winmm.dll` you installed is the **loader**, not the
system's winmm:

1. delete the `Conan-Api/` folder;
2. delete the `winmm.dll` (the loader) from inside `Win64/`;
3. **rename `winmm_orig.dll` back to `winmm.dll`.** Without the real winmm the
   executable won't start — and it fails before any log, without saying why.

Deleting only the `Conan-Api/` folder **doesn't** uninstall anything: the loader
is still standing in for the system's winmm, hijacking the import on every boot.

**When updating (reinstalling over the top), never rename the `winmm.dll` that's
already in the folder to `winmm_orig.dll`** — that one is already the loader. If
the loader becomes its own `winmm_orig.dll`, it forwards the winmm calls to
itself, recurses, and the server dies **without coming up and without a message**
(exits with code 1, writing no log). `winmm_orig.dll` has to always be the
**system's** winmm — keep a copy of the original before your first install,
that's the one that goes back here.

To keep player data across versions, **don't** delete `Conan-Api/Config/` or
`Conan-Api/Dados/`: those are the plugins' configuration and databases (VIP,
permissions, and so on).

---

## When the game updates

Offsets always change; names almost never do. The API **refuses to work** with a
stale anchor — no plugin loads, and the reason goes to the log. That's on
purpose: reading random memory and handing back plausible values would be far too

When the Conan game updates, offsets move and **the API refuses to load** — on
purpose. The log (`Conan-Api/Logs/ConanApi.log`) says the build doesn't match.
It isn't a defect: it's the API refusing to read memory that moved. When that
happens, wait for an updated version of the API; your plugins don't need
recompiling, because they talk to the table, and the table doesn't change shape.
