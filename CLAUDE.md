# Instrucoes do repositorio Conan-Api

## Nao apague a documentacao ao publicar o pacote

Este repositorio guarda duas coisas de naturezas diferentes na mesma raiz:

- **o pacote do servidor** -- `Conan-Api/`, `INSTALAR.txt`, `winmm.dll`
- **a documentacao publica** -- `README.md`, `doc/`, `LICENSE`, `.github/imagens/`

Publicar uma nova versao significa **atualizar o pacote**, nunca substituir a
raiz do repositorio pelo conteudo de uma pasta de build ou de staging.

Ja aconteceu: o commit `d16de94` (v1.1.0) espelhou a pasta de publicacao na
raiz e apagou 11 arquivos que nao estavam nela -- os 3 READMEs, o `LICENSE`,
o `.gitignore` e as 6 imagens. O projeto ficou sem README no GitHub por
horas, e a recuperacao so foi possivel porque o historico nao tinha sido
reescrito.

### Antes de commitar uma publicacao

```
sh .githooks/verificar-documentacao.sh
```

Saidas: `0` aprovado, `1` reprovado (diz qual caminho sumiu), `2` **NAO
VERIFICOU** -- que nao e aprovacao. Se a guarda reprovar, restaure o caminho
em vez de seguir; a lista protegida esta em `CAMINHOS_PROTEGIDOS`, dentro do
proprio script.

Para o hook local recusar sozinho o commit, uma vez por clone:

```
git config core.hooksPath .githooks
```

Detalhes em `.githooks/LEIA-ME.md`.

### Se a remocao for mesmo intencional

Tire o caminho de `CAMINHOS_PROTEGIDOS` no mesmo commit que remove o
arquivo, para a decisao ficar registrada. Nao use `--no-verify` para
contornar a guarda em publicacao automatica.
