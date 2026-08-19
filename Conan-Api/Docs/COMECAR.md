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


## Guardar os VIPs num MySQL (opcional — quase ninguém precisa)

O plugin `Permission` é quem anota **quem é VIP, quem é admin e quem pode o
quê**. Por padrão ele anota isso num arquivo, ao lado dele mesmo
(`permission.db`). Esse arquivo funciona sozinho: não precisa instalar nada, não
precisa configurar nada, e é o certo para a enorme maioria dos servidores.

Você só ganha alguma coisa trocando para MySQL em **dois** casos:

| você tem | vale a pena? |
|---|---|
| um servidor só | **não.** Deixe como está. Você só ganha coisa para dar errado |
| dois ou mais servidores, e quer o mesmo VIP valendo em todos | sim |
| um site/painel que já lê seus jogadores de um MySQL | sim |

> **Leu num fórum que "MySQL é melhor"?** Para um servidor só, não é. O arquivo
> local é mais rápido (não passa por rede), não cai, não tem senha para errar e
> não some quando o outro computador desliga. A vantagem do MySQL é **um lugar
> só para vários servidores** — se você não tem vários, não há vantagem.

### Antes de mexer: o que NÃO acontece

O medo legítimo é "e se o banco cair, meu servidor trava e os jogadores caem?".

Não acontece, e isso foi medido, não prometido: **quem fala com o MySQL é uma
linha de trabalho separada, nunca a do jogo.** A bateria de testes maltrata o
MySQL de três jeitos com o plugin no ar — mata a conexão de fora, corta a rede
no meio de uma operação, e põe no lugar um banco que leva 2 segundos para
responder cada consulta — e nos três o laço do jogo continua no mesmo ritmo. O
que acontece é o `Permission` ficar
**ausente** — como se ele não estivesse instalado — e cada plugin que dependia
dele usa o padrão que ele mesmo escolheu. Ninguém desconecta, ninguém trava.

E ele **tenta voltar sozinho**, esperando cada vez um pouco mais (5 s, 10 s,
20 s… até 5 minutos), **relendo o `config.json` a cada tentativa**. É isso que
faz você corrigir a senha errada no arquivo, salvar, e o plugin entrar sozinho —
**sem reiniciar o servidor de jogo**, que custa 6 a 9 minutos com ninguém
conseguindo entrar.

### O que você precisa ter pronto

Duas coisas — uma gaveta e um usuário — feitas **no MySQL**, não aqui. Se você
não sabe fazer isso, quem cuida do seu MySQL sabe: mande o bloco abaixo para
ele, trocando o nome do banco e a senha:

```sql
CREATE DATABASE IF NOT EXISTS conan_permission CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'conan'@'%' IDENTIFIED BY 'a-senha-que-voce-escolher';
GRANT ALL ON conan_permission.* TO 'conan'@'%';
FLUSH PRIVILEGES;
```

A primeira linha cria a **gaveta** onde os dados vão morar. A segunda cria o
**usuário** que vai abrir essa gaveta. A terceira dá a ele a chave — **dessa
gaveta só**. A quarta manda o MySQL passar a valer o que você acabou de fazer.
As tabelas de dentro o plugin cria sozinho, na primeira vez que subir.

> **Nessa ordem, e sem pular o `CREATE USER`.** Em MySQL antigo dava para
> pular — o `GRANT` criava o usuário sozinho. **No MySQL 8 isso acabou**: o
> `GRANT` sem o usuário existir responde
> `ERROR 1410: You are not allowed to create a user with GRANT`. Conferido no
> MySQL 8.4.11; o bloco acima foi rodado também no MySQL 5.7.44 e no
> MariaDB 10.11, e passou nos três.

**Não use o usuário `root`.** Ele abre o banco inteiro; o plugin só precisa de
uma gaveta. Se alguém puser as mãos nesse servidor, a diferença entre as duas
coisas é o tamanho do estrago.

### Onde mexer

Um arquivo só: `Conan-Api/Plugins/Permission/config.json`. As chaves já estão
lá, vazias, esperando por você:

```json
  "Database": "sqlite",
  "MysqlHost": "127.0.0.1",
  "MysqlPort": 3306,
  "MysqlUser": "",
  "MysqlPass": "",
  "MysqlDB": "",
```

Vira isto:

```json
  "Database": "mysql",
  "MysqlHost": "127.0.0.1",
  "MysqlPort": 3306,
  "MysqlUser": "conan",
  "MysqlPass": "a-senha-que-voce-escolher",
  "MysqlDB": "conan_permission",
```

| chave | o que é |
|---|---|
| `Database` | `sqlite` (arquivo local, o padrão) ou `mysql`. Nada mais |
| `MysqlHost` | onde o MySQL está. **Na mesma máquina? use `127.0.0.1`** |
| `MysqlPort` | o número da porta. `3306` é o normal — só mude se te disseram outro |
| `MysqlUser` | o usuário que você criou ali em cima |
| `MysqlPass` | a senha dele |
| `MysqlDB` | o nome da gaveta que você criou (`conan_permission` no exemplo) |

Salve, reinicie o servidor **uma vez**, e olhe `Conan-Api/Logs/ConanApi.log`.
Deu certo quando aparece isto:

```
[permission] banco: MySQL em 127.0.0.1:3306, banco 'conan_permission', usuario 'conan' (prazos: 5000 ms para conectar, 10000 ms por operacao)
[permission] MySQL: pronto (8.4.11, utf8mb4, sem NO_BACKSLASH_ESCAPES)
[permission] instantaneo #1: 4 grupo(s), 0 jogador(es), 2 no(s) no padrao
```

> **Por que `127.0.0.1` e não `localhost`?** São a mesma máquina, mas
> `localhost` no Windows às vezes tenta primeiro um caminho que não existe e
> demora alguns segundos antes de tentar o certo. `127.0.0.1` vai direto.

### Três armadilhas que pegam todo mundo

**1. Espaço no fim, vindo do copiar-e-colar.** Você seleciona a senha ou o
endereço no site do provedor, o mouse pega um espaço junto, e você cola. O valor
fica com cara de certo — **espaço não aparece na tela**. O plugin recusa e
mostra o valor entre colchetes, para o espaço ficar visível:

```
"MysqlHost" termina com ESPACO. (...) Entre colchetes ele fica visivel:
[127.0.0.1 ] tem 10 caracteres; o certo e [127.0.0.1], com 9.
```

Apague o espaço. (Na **senha** ele não recusa: senha com espaço pode ser senha
de verdade.)

**2. Aspas em volta do número da porta.** `"MysqlPort": "3306"` com aspas
funciona igual a `3306` sem aspas — não se preocupe com isso. O que **não**
funciona é escrever palavra no lugar do número; aí ele diz que aquilo é texto e
que precisa do número.

**3. `MySQL` com maiúscula.** `"mysql"`, `"MySQL"`, `"MYSQL"` — todos valem.
Mas **`"mysqll"` com dois L não vale**, e o plugin **para** em vez de adivinhar.
Isso é de propósito: se ele caísse no arquivo local calado, seus VIPs iriam para
um lugar que você não está olhando, e você só descobriria semanas depois,
procurando no MySQL e não achando.

### Quando o log reclamar

Toda mensagem de erro deste plugin diz **o que está errado** e **o que fazer**.
Procure no `ConanApi.log` a linha que começa com `[permission]`, logo acima
daquela moldura de `###`:

| o log diz | o que houve | o que fazer |
|---|---|---|
| `recusou o login do usuario 'x'` | usuário ou senha errados | confira `MysqlUser` e `MysqlPass`. Confira espaço no fim |
| `entrou no MySQL, mas nao conseguiu abrir o banco` | a gaveta não existe, ou o usuário não tem a chave dela | rode as duas linhas de SQL que **o próprio log escreve**, prontas para copiar |
| `nao ha nada escutando na porta 3306` | o MySQL está parado, ou está em outra porta | ligue o MySQL, ou corrija `MysqlPort` |
| `nao consegui resolver o endereco 'x'` | o nome não existe, ou está escrito errado | confira `MysqlHost`. Mesma máquina? use `127.0.0.1` |
| `sem "MysqlUser"` / `sem "MysqlDB"` | você deixou a chave vazia | preencha. Ele não escolhe por você de propósito |
| `nao e um numero de porta — isso e texto` | você escreveu palavra na porta | escreva o número: `"MysqlPort": 3306` |

E um erro que aparece **no MySQL**, não no log do plugin, quando você está
criando o usuário:

| o MySQL diz | o que houve | o que fazer |
|---|---|---|
| `ERROR 1410: You are not allowed to create a user with GRANT` | você rodou o `GRANT` sem ter criado o usuário antes | rode o `CREATE USER` primeiro — é a segunda das quatro linhas ali em cima |
| `ERROR 1044 / 1045` ao testar no cliente do MySQL | a senha ou o usuário não batem | refaça o `CREATE USER`, com aspas simples exatamente como no exemplo |

**Nada disso derruba o servidor de jogo.** Em todos esses casos os jogadores
continuam jogando; só o `Permission` fica ausente até você corrigir o arquivo.

### Se o seu MySQL for 8.0 ou mais novo

Nada a fazer na maioria dos casos — foi testado contra o **MySQL 8.4.11** e
conectou sem configuração nenhuma. Existe um caso em que o MySQL exige um
método de login que precisa de uma chave que ele mesmo não quer entregar sem
conexão cifrada; se isso acontecer, **o log escreve a linha de SQL exata** que
resolve. Copie, rode no MySQL, pronto — você não precisa entender o assunto.

**Você não precisa instalar nada para o MySQL funcionar aqui.** Não há DLL para
baixar, nem "conector" para instalar: o plugin fala com o MySQL por conta
própria. Se alguém mandar você baixar um arquivo para isso, não é deste plugin.

### Voltar atrás

Troque `"Database"` de volta para `"sqlite"` e reinicie. Os dados que você já
tinha no arquivo local **continuam lá**, intactos — trocar de banco não apaga o
outro.

O que **não** acontece sozinho é os dados irem de um para o outro: o que você
gravou no MySQL fica no MySQL, o que estava no arquivo fica no arquivo. Não há
importação automática, e é melhor assim — juntar dois cadastros de VIP
adivinhando qual vale seria o tipo de ajuda que estraga.

---

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
