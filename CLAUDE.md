# Instrucoes do repositorio Conan-Api

## Publicar atualiza o pacote; nao substitui a raiz

Este repositorio guarda duas coisas de naturezas diferentes na mesma raiz:

- **o pacote do servidor**, que vem da distribuicao -- `Conan-Api/`,
  `INSTALAR.txt`, `winmm.dll`
- **o que e escrito no proprio GitHub e NAO vem do pacote** -- a lista abaixo

Publicar significa atualizar o pacote. Limpar a raiz antes de copiar apaga o
segundo grupo, e o push conclui sem erro nenhum -- foi assim nas v1.1.0 e
v1.9.0. A v1.9.1 e a v1.9.2 corrigiram o script (preservacao por arquivo,
devolucao que mescla); esta lista existe para a preservacao nao ficar
incompleta de novo.

## Caminhos que a publicacao tem de preservar

```
README.md                 doc/                      LICENSE
.github/imagens/          .github/workflows/        .gitignore
.gitattributes            .githooks/                CLAUDE.md
```

`.githooks/`, `.gitattributes` e `.gitignore` sao os que a restauracao da
v1.9.0 nao conhecia: o workflow foi devolvido, mas o script que ele chama
nao, e a guarda ficou no ar sem poder rodar. Se um deles sumir de novo, o
job "Guarda de documentacao" fica vermelho em todo push.

`.gitattributes` nao e detalhe: ele forca LF nos `.sh`. Sem ele, um clone
Windows com `core.autocrlf=true` grava CRLF e o runner Ubuntu recusa o
interpretador -- a guarda existe e nao roda.

## Antes de commitar uma publicacao

```
sh .githooks/verificar-documentacao.sh
```

Saidas: `0` aprovado, `1` reprovado (diz qual caminho sumiu), `2` **NAO
VERIFICOU** -- que nao e aprovacao. Se reprovar, restaure o caminho em vez de
seguir. A lista protegida esta em `CAMINHOS_PROTEGIDOS`, dentro do script.

Para o hook local recusar sozinho o commit, uma vez por clone:

```
git config core.hooksPath .githooks
```

Detalhes em `.githooks/LEIA-ME.md`.

## Se a remocao for mesmo intencional

Tire o caminho de `CAMINHOS_PROTEGIDOS` no mesmo commit que remove o
arquivo, para a decisao ficar registrada. Nao use `--no-verify` para
contornar a guarda em publicacao automatica.
