# Começar — seu primeiro plugin

Você precisa de: o compilador cruzado do MinGW e um servidor de Conan Exiles
Enhanced. Não precisa de Visual Studio, nem do editor da Unreal, nem de conta de
desenvolvedor.

```bash
sudo apt-get install -y mingw-w64        # Debian/Ubuntu
```

---

## 1. Instalar o carregador no servidor

O servidor do Conan não tem sistema de plugins. O carregador entra pela ordem de
busca de DLL do Windows: um executável procura suas DLLs primeiro **na própria
pasta**. Uma `winmm.dll` nossa ali dentro é carregada no lugar da do sistema, e
roda dentro do processo do jogo.

> **Antes de instalar, saiba o que está instalando.** O carregador e todo plugin
> rodam **dentro do processo do seu servidor**, com acesso total à memória do
> jogo, aos dados dos jogadores, ao disco e à rede da máquina. Não há sandbox —
> não pode haver, porque o propósito da API é dar acesso à reflexão do jogo.
> Instale só plugins de quem você confia, de preferência com o fonte à vista para
> compilar você mesmo. O detalhe está no `LEIA-ME`, seção "Antes de instalar
> plugin de terceiro".

**A `winmm.dll` já vem pronta no pacote** — ela está na raiz do que você baixou,
um nível **acima** da pasta `Conan-Api/`:

```
o que você baixou/
   winmm.dll          <- AQUI. É o carregador, já compilado.
   Conan-Api/         <- o resto
```

Não precisa compilar nada para instalar. A `winmm.dll` vem compilada e conferida: o `VERSAO.txt` traz o sha256 dela, e o
log do carregador diz qual versão subiu. O que ela faz por dentro está descrito
em `Docs/LEIA-ME.md` — em português, sem precisar ler código.

**Não pule esta parte.** Sem a `winmm.dll` no lugar certo, o servidor sobe
normalmente, sem plugin nenhum e **sem nenhuma mensagem de erro** — a falha mais
difícil de diagnosticar que este projeto tem.

Copie para `<servidor>/ConanSandbox/Binaries/Win64/`:

| o que | de onde vem |
|---|---|
| `winmm.dll` | **já vem pronta** na raiz do pacote |
| `winmm_orig.dll` | a winmm.dll **real** do sistema, renomeada |
| `Conan-Api/` | a pasta única com tudo dentro |

Só o `winmm.dll` fica solto — ele **tem** de estar ao lado do executável, é assim
que entra no processo. Todo o resto mora dentro de `Conan-Api`, e a própria API
cria as subpastas na primeira execução:

```
Win64/
   ConanSandboxServer-Win64-Shipping.exe
   winmm.dll            <- o carregador
   winmm_orig.dll       <- a original do sistema, renomeada
   Conan-Api/
      Plugins/          as DLLs dos plugins
      Config/           um arquivo por plugin
      Dados/            bancos e estado
      Logs/             ConanLoader.log e ConanApi.log
```

Uma pasta única em vez de arquivos espalhados pela árvore do servidor: quem
instala copia uma coisa, e quem desinstala apaga uma coisa. Espalhar garante que
alguém copie metade e depois não entenda por que não funciona.

A `winmm_orig.dll` não é opcional. O jogo importa a winmm de verdade; se as
funções dela sumirem, o executável não inicia — e falha antes de qualquer log,
sem dizer por quê.

### Rodando sob Wine (Linux)

O Wine tem uma winmm própria e a prefere à que está na pasta do jogo. Sem isto o
servidor sobe **normalmente, sem plugin nenhum e sem erro** — a pior espécie de
falha:

```bash
export WINEDLLOVERRIDES="winmm=n,b"
```

`n,b` = tenta a nativa (a nossa) primeiro, cai para a builtin se faltar.

### Conferir se funcionou

Suba o servidor e olhe `ConanLoader.log`, ao lado do executável:

```
== ConanLoader iniciado ==
reflexao de pe: 318985 objetos vivos
  [ok] ExemploOla.dll
== 1 plugin(s) carregado(s), 0 com falha ==
```

Se aparecer `ABORTADO: a reflexao nao respondeu`, as âncoras não conferem — veja
[quando o jogo atualizar](#quando-o-jogo-atualizar).

---


## Instalar um plugin — arraste a pasta

Cada plugin é **uma pasta**, com tudo o que ele precisa dentro. Para instalar,
você arrasta a pasta para dentro de `Conan-Api/Plugins/` e reinicia o servidor.

```
Conan-Api/
   Plugins/
      Permission/               <- já vem no pacote, é o padrão
         ConanPermission.dll
         config.json
      PluginQueVoceBaixou/      <- você arrastou esta pasta
         PluginQueVoceBaixou.dll
         config.json
         (banco, tabelas, o que ele precisar — tudo aqui dentro)
```

**Não há arquivo de configuração para editar, nem lista para ligar.** A pasta
estar ali já é a instalação. O carregador varre `Plugins/`, entra em cada pasta e
carrega a DLL que encontra.

| você quer | você faz |
|---|---|
| instalar | arrasta a pasta para `Plugins/` |
| desinstalar | apaga a pasta |
| desligar sem apagar | cria um arquivo vazio `DESLIGADO` dentro da pasta |
| ver o que aconteceu | `Conan-Api/Logs/ConanLoader.log` |

**Qual DLL o carregador escolhe**, se a pasta tiver mais de uma: primeiro procura
uma com o nome da pasta (`MeuPlugin/MeuPlugin.dll`); se não houver, e existir uma
só, usa essa. Se houver duas e nenhuma com o nome da pasta, ele **recusa** e diz
no log qual renomear — escolher "a primeira" seria uma decisão invisível que muda
com a ordem do sistema de arquivos.

**Cada plugin tem o próprio espaço.** O `config.json` de um não colide com o de
outro, e o banco de um não fica na pasta do vizinho. Dois plugins podem ter
arquivos de mesmo nome sem se atrapalharem.


## Escrever um plugin? É outro download

Este pacote é o do **servidor**: ele faz plugin rodar. Se você quer *escrever*
um, baixe o **SDK** — são os headers, seis exemplos com fonte e o guia de
compilação. São coisas separadas de propósito: quem administra um servidor não
precisa de compilador nem de header para nada, e quem escreve plugin não precisa
dos binários do servidor.

Quem faz os dois baixa os dois.

## Erros que valem conhecer

**O plugin não carrega e nada aparece no log.** Confira se a função exportada se
chama exatamente `ConanPluginCarregar` e está em `extern "C"`. Sem isso o
carregador não a encontra e registra `nao exporta ConanPluginCarregar()`.

**Um valor sai absurdo.** Offset provavelmente mudou — o jogo atualizou. Regere.
Valor absurdo é o sintoma bom; o ruim é o valor plausível e errado.

**O servidor cai ao carregar o plugin.** O carregador **contém** a falha do plugin
durante o carregamento — em MinGW **e** em MSVC, com tabela de escopo SEH
(`__C_specific_handler`) numa thread dedicada. O servidor sobe sem o plugin e o
motivo vai para `ConanLoader.log`. O que **não** é contido é uma falha que acontece
**dentro de um hook**: aí o código do plugin roda na thread do jogo, fora da
guarda, e pode derrubar o servidor. Use `g_api->Legivel(ptr, n)` antes de seguir
ponteiro de origem duvidosa, sobretudo dentro de hook.

**Funcionou no `curl`/no teste e não no jogo.** Compilar não prova nada. Só o log
do servidor rodando prova.

---

## Desinstalar, e o cuidado com o `winmm.dll`

Desinstalar exige desfazer as três coisas que a instalação fez — e a ordem
importa, porque o `winmm.dll` que você instalou é o **carregador**, não a winmm do
sistema:

1. apague a pasta `Conan-Api/`;
2. apague o `winmm.dll` (o carregador) de dentro de `Win64/`;
3. **renomeie `winmm_orig.dll` de volta para `winmm.dll`.** Sem a winmm de verdade
   o executável não inicia — e falha antes de qualquer log, sem dizer por quê.

Apagar só a pasta `Conan-Api/` **não** desinstala: o carregador continua no lugar
da winmm do sistema, sequestrando a importação a cada boot.

**Ao atualizar (reinstalar por cima), nunca renomeie para `winmm_orig.dll` o
`winmm.dll` que já está na pasta** — ele já é o carregador. Se o carregador virar o
próprio `winmm_orig.dll`, ele reencaminha as chamadas da winmm para si mesmo, entra
em recursão e o servidor morre **sem subir e sem mensagem** (sai com código 1, sem
escrever log). A `winmm_orig.dll` tem de ser sempre a winmm **do sistema** —
guarde uma cópia da original antes da primeira instalação, é ela que volta aqui.

Para preservar os dados dos jogadores entre versões, **não** apague
`Conan-Api/Config/` nem `Conan-Api/Dados/`: são a configuração e os bancos dos
plugins (VIP, permissões, etc.).

---

## Quando o jogo atualizar

Os offsets mudam sempre; os nomes quase nunca. A API **se recusa a funcionar**
com âncora desatualizada — nenhum plugin carrega, e o motivo vai para o log. Isso
é de propósito: ler memória aleatória e devolver valores plausíveis seria muito

Quando o jogo do Conan atualizar, os offsets mudam e **a API se recusa a
carregar** — de propósito. O log (`Conan-Api/Logs/ConanApi.log`) diz que a build
não confere. Não é defeito: é a API se negando a ler memória que mudou de lugar.
Quando isso acontecer, espere uma versão atualizada da API; seus plugins não
precisam ser recompilados, porque falam com a tabela, e a tabela não muda de
forma.
