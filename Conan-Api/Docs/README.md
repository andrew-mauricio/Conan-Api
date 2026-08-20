# Conan-Api — plugins on your server

*Portuguese translation: [LEIA-ME-PACOTE.pt.md](LEIA-ME-PACOTE.pt.md)*

This is the **server** package: it's what makes plugins work. You don't need a
compiler, or a header, or anything beyond what's in here.

## Installing

Read **`INSTALAR.txt`**, in the root, next to `winmm.dll`. It's 20 lines and it
covers everything.

The short version: stop the server, rename the `winmm.dll` already sitting in
`ConanSandbox\Binaries\Win64\` to `winmm_orig.dll`, copy the `winmm.dll` from
here and the `Conan-Api` folder into that same place, and bring it back up.

## Installing a plugin

Drag its folder into `Conan-Api\Plugins\` and restart.

```
Conan-Api\
   Plugins\
      Permission\             ships with it: handles VIP, groups and permissions
      PluginYouDownloaded\    you dragged this folder in here
```

To uninstall, delete the folder. To switch a plugin off without losing its
settings, create an empty file called `DESLIGADO` inside it.

## What's in the box

```
winmm.dll        the loader. Without it, nothing happens.
INSTALAR.txt     the five installation steps
Conan-Api\
   Plugins\      the plugins (one folder each)
   Config\       general API settings
   Dados\        what the API writes
   Logs\         this is where you look when something doesn't work
   Docs\         COMECAR.md, with the step by step and the common errors
   VERSAO.txt    the sha256 of each binary, so you can check what you have
```

## VIP and permissions: where they're kept

`Permission` comes installed, and it's the one that records who's VIP, who's
admin and who can do what. By default it keeps all that **in a file right next
to itself**, which works on its own and needs no configuration at all. That's
the right answer for almost every server.

If you run **several servers** and want the same VIP to count on all of them,
you can point `Permission` at a **MySQL** — by touching only
`Conan-Api\Plugins\Permission\config.json`, with nothing to install and no
programming. The keys are already in the file, empty. The step by step, with the
common errors and what to do about each one, is in `Conan-Api\Docs\COMECAR.md`,
in the section **"Guardar os VIPs num MySQL"**.

If you have a single server, you don't need this and you gain nothing from it.

## When something doesn't work

`Conan-Api\Logs\ConanLoader.log` says what the loader did, in Portuguese, with
the name of every plugin folder. If that file wasn't even created, the loader
never got in — go back over the `winmm.dll` step.

## Writing your own plugins

That's a separate download: the **Conan-Api-SDK**, at
`github.com/andrew-mauricio/Conan-Api-SDK`. It has the header, the examples with
source code, and the build guide.

They're separate on purpose: whoever runs a server has no use for a header, and
whoever writes a plugin has no use for the server binaries. If you do both,
download both.

---

*Conan Exiles* belongs to Funcom. This project is independent and has no tie to
Funcom or to Inflexion Games.
