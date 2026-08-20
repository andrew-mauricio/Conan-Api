# Conan-Api — plugins no seu servidor

*Tradução. O documento principal é o [README-PACKAGE.md](README-PACKAGE.md), em inglês.*

Este é o pacote do **servidor**: ele faz plugin funcionar. Você não precisa de
compilador, nem de header, nem de nada além do que está aqui dentro.

## Instalar

Leia o **`INSTALAR.txt`**, na raiz, ao lado da `winmm.dll`. São 20 linhas e
resolvem tudo.

O resumo: pare o servidor, renomeie a `winmm.dll` que já existe em
`ConanSandbox\Binaries\Win64\` para `winmm_orig.dll`, copie para lá a `winmm.dll`
daqui e a pasta `Conan-Api`, e suba.

## Instalar um plugin

Arraste a pasta dele para dentro de `Conan-Api\Plugins\` e reinicie.

```
Conan-Api\
   Plugins\
      Permission\             já vem: controla VIP, grupos e permissões
      PluginQueVoceBaixou\    você arrastou esta pasta aqui
```

Para desinstalar, apague a pasta. Para desligar sem perder a configuração, crie
um arquivo vazio chamado `DESLIGADO` lá dentro.

## O que tem aqui

```
winmm.dll        o carregador. Sem ele, nada acontece.
INSTALAR.txt     os cinco passos da instalação
Conan-Api\
   Plugins\      os plugins (uma pasta cada)
   Config\       ajustes gerais da API
   Dados\        o que a API grava
   Logs\         é aqui que você olha quando algo não funciona
   Docs\         COMECAR.md, com o passo a passo e os erros comuns
   VERSAO.txt    o sha256 de cada binário, para conferir o que você tem
```

## VIP e permissões: onde ficam guardados

O `Permission` já vem instalado e é ele que anota quem é VIP, quem é admin e
quem pode o quê. Por padrão ele guarda isso **num arquivo ao lado dele mesmo**,
que funciona sozinho e não precisa de configuração nenhuma. É o certo para quase
todo servidor.

Se você roda **vários servidores** e quer o mesmo VIP valendo em todos, dá para
apontar o `Permission` para um **MySQL** — mexendo só no
`Conan-Api\Plugins\Permission\config.json`, sem instalar nada e sem programar.
As chaves já estão no arquivo, vazias. O passo a passo, com os erros comuns e o
que fazer em cada um, está em `Conan-Api\Docs\COMECAR.md`, na seção
**"Guardar os VIPs num MySQL"**.

Se você tem um servidor só, não precisa disso e não ganha nada com ele.

## Quando algo não funciona

`Conan-Api\Logs\ConanLoader.log` diz o que o carregador fez, em português, com o
nome de cada pasta de plugin. Se esse arquivo nem foi criado, o carregador não
entrou — reveja o passo da `winmm.dll`.

## Escrever seus próprios plugins

É outro download: o **Conan-Api-SDK**, em
`github.com/andrew-mauricio/Conan-Api-SDK`. Lá estão o header, os exemplos com
código-fonte e o guia de compilação.

São separados de propósito: quem administra um servidor não precisa de header
para nada, e quem escreve plugin não precisa dos binários do servidor. Quem faz
os dois baixa os dois.

---

*Conan Exiles* é da Funcom. Este projeto é independente e não tem vínculo com a
Funcom nem com a Inflexion Games.
