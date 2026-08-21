#!/bin/sh
# =============================================================================
# GUARDA DE DOCUMENTACAO
#
# PROPOSITO DE NEGOCIO
#   Impedir que a documentacao publica do repositorio desapareca sem que
#   ninguem perceba. Existe por prejuizo medido: em 18/08/2026 o commit
#   d16de94 (v1.1.0) publicou o pacote do servidor espelhando uma pasta de
#   staging na raiz do repo e levou junto 11 arquivos que nao estavam nela --
#   os 3 READMEs, o LICENSE, o .gitignore e as 6 imagens. A pagina do projeto
#   no GitHub ficou sem README por horas ate alguem reparar no navegador.
#   Processo que espelha diretorio apaga o que nao conhece: a guarda e o que
#   transforma esse apagamento silencioso em commit recusado.
#
# INVARIANTES DO DOMINIO
#   I-DOC-1  Todo caminho de CAMINHOS_PROTEGIDOS existe no indice do git.
#            Verificado no pre-commit (antes de gravar) e no CI (depois de
#            subir), porque as duas camadas falham por motivos diferentes.
#   I-DOC-2  Toda imagem local referenciada por um README versionado existe no
#            repositorio. README que renderiza com imagem quebrada e falha
#            silenciosa: a pagina abre, so esta errada.
#   I-DOC-3  A guarda falha FECHADA. Nao conseguir verificar nunca e aprovacao.
#
# COMPORTAMENTO EM CASO DE FALHA
#   Sai 0  APROVADO       -- todos os caminhos protegidos presentes.
#   Sai 1  REPROVADO      -- ao menos um sumiu; imprime exatamente quais.
#   Sai 2  NAO VERIFICOU  -- git ausente, fora de repositorio, 'git ls-files'
#          falhou ou indice vazio. NAO E APROVACAO: quem chama trata 2 como
#          bloqueio. Aprovar por falta de medicao e o defeito que a guarda
#          existe para nao repetir.
#
# COMO INSTALAR (uma vez por clone):  git config core.hooksPath .githooks
# =============================================================================

set -u

# ATUALIZADA EM 21/08/2026, e a lista velha mostra exatamente como ela apodrece:
#   · pedia CLAUDE.md, que e' PRIVADO e nunca deveria estar num repo publico;
#   · pedia doc/README.en.md, que deixou de existir quando o ingles virou o
#     README.md da raiz. A guarda ficava reprovando um arquivo cuja ausencia
#     era a CORRECAO.
#
# A REGRA QUE ELA ENCODA AGORA: o INGLES e' obrigatorio, a traducao e' opcional.
# Ingles e' a lingua primaria e a que se mantem; portugues e espanhol ficam ao
# lado como traducao, e a falta de uma delas nao e' repositorio quebrado.
CAMINHOS_PROTEGIDOS="
README.md
LICENSE
.gitignore
.gitattributes
INSTALL.txt
.github/imagens/conan-header.jpg
.github/imagens/conan-1.jpg
.github/imagens/conan-2.jpg
.github/imagens/bandeiras/br.png
.github/imagens/bandeiras/us.png
.github/imagens/bandeiras/es.png
.githooks/pre-commit
.githooks/verificar-documentacao.sh
.github/workflows/guarda-documentacao.yml
"

# As traducoes. Existem e sao bem-vindas; a ausencia de uma e' NOTA, nao falha.
# Um repositorio sem a versao em espanhol continua auditavel; um sem o README
# em ingles, nao.
CAMINHOS_OPCIONAIS="
doc/README.pt.md
doc/README.es.md
INSTALAR.pt.txt
"

nao_verificou() {
    echo "GUARDA DOC: NAO VERIFICOU -- $1" >&2
    echo "GUARDA DOC: estado 2 nao e aprovacao." >&2
    exit 2
}

command -v git >/dev/null 2>&1 || nao_verificou "git nao encontrado no PATH"
git rev-parse --git-dir >/dev/null 2>&1 || nao_verificou "nao e um repositorio git"

# git ls-files le o INDICE, nao o disco: no pre-commit ja reflete exatamente o
# que o commit vai gravar, inclusive as remocoes que ainda nao foram gravadas.
INDICE=$(git ls-files) || nao_verificou "'git ls-files' falhou"
[ -n "$INDICE" ] || nao_verificou "indice vazio -- instrumento sem sinal"

esta_no_indice() {
    printf '%s\n' "$INDICE" | grep -qxF "$1"
}

# Colapsa 'x/../' para comparar o caminho referenciado com o caminho indexado.
normalizar() {
    printf '%s' "$1" | sed -e 's|^\./||' -e ':a' -e 's|[^/][^/]*/\.\./||' -e 'ta'
}

faltando=""
quebradas=""

for caminho in $CAMINHOS_PROTEGIDOS; do
    esta_no_indice "$caminho" || faltando="$faltando $caminho"
done

# As opcionais NAO entram em $faltando: elas viram nota. Reprovar por falta de
# traducao pintaria o repositorio de vermelho por um arquivo que nunca foi
# exigido — e guarda que reclama do que nao importa e' guarda que se aprende a
# ignorar.
ausentes_opcionais=""
for caminho in $CAMINHOS_OPCIONAIS; do
    esta_no_indice "$caminho" || ausentes_opcionais="$ausentes_opcionais $caminho"
done

# I-DOC-2: imagem local citada em README versionado tem de existir.
for readme in $(git ls-files '*README*.md' 'README.md'); do
    pasta=$(dirname "$readme")
    conteudo=$(git show ":$readme" 2>/dev/null) || continue
    refs=$(printf '%s\n' "$conteudo" \
        | grep -oE '(src="[^"]+"|\]\([^) ]+\))' \
        | sed -e 's/^src="//' -e 's/"$//' -e 's/^\](//' -e 's/)$//')
    for ref in $refs; do
        case "$ref" in
            http:*|https:*|mailto:*|\#*|data:*) continue ;;
            *.jpg|*.jpeg|*.png|*.gif|*.svg|*.webp) ;;
            *) continue ;;
        esac
        [ "$pasta" = "." ] && alvo="$ref" || alvo="$pasta/$ref"
        alvo=$(normalizar "$alvo")
        esta_no_indice "$alvo" || quebradas="$quebradas $readme->$alvo"
    done
done

if [ -n "$faltando" ] || [ -n "$quebradas" ]; then
    echo "GUARDA DOC: REPROVADO" >&2
    for f in $faltando; do
        echo "  documentacao protegida ausente do indice: $f" >&2
    done
    for q in $quebradas; do
        echo "  imagem referenciada que nao existe no repo: $q" >&2
    done
    echo "" >&2
    echo "  Se a remocao for intencional, tire o caminho de CAMINHOS_PROTEGIDOS" >&2
    echo "  no mesmo commit. Atalho de emergencia: git commit --no-verify" >&2
    exit 1
fi

for o in $ausentes_opcionais; do
    echo "GUARDA DOC: nota -- traducao ausente (opcional): $o"
done

echo "GUARDA DOC: aprovado -- documentacao protegida integra"
exit 0
