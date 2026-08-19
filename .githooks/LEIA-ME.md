# Guarda de documentacao

Impede que os READMEs, o LICENSE e as imagens do projeto sumam do
repositorio sem ninguem perceber.

Existe por prejuizo medido: em 18/08/2026 o commit `d16de94` publicou o
pacote do servidor espelhando uma pasta de staging na raiz e apagou 11
arquivos que nao estavam nela. O projeto ficou sem README no GitHub ate
alguem reparar no navegador.

## Instalar (uma vez por clone)

```
git config core.hooksPath .githooks
```

Sem isso, o hook local nao roda -- `core.hooksPath` e configuracao do clone
e nao viaja dentro do repositorio. A camada do GitHub Actions roda de
qualquer jeito, mas so **depois** que o commit ja subiu.

## Os tres estados

| saida | significado |
|---|---|
| `0` | aprovado: documentacao protegida integra |
| `1` | reprovado: algum caminho protegido sumiu (a guarda diz qual) |
| `2` | **NAO VERIFICOU** -- nao e aprovacao; o hook bloqueia igual ao `1` |

## Quando a remocao for intencional

Tire o caminho de `CAMINHOS_PROTEGIDOS` em
`.githooks/verificar-documentacao.sh` no mesmo commit que remove o arquivo.
Atalho de emergencia: `git commit --no-verify`.
