#!/bin/bash
# Build script for GnuCOBOL + DB2 embedded SQL (.sqb) programs
#
# Usage: ./build-sqb.sh <program>
#   Example: ./build-sqb.sh COBDB2T13
#
# Process:
#   1. db2 PREP (precompile) - inside container, generates .cbl + .bnd
#   2. db2 BIND              - binds the package to the DB2 database
#   3. cobc compile          - inside container, links against libdb2.so
#   4. copy binary back      - to project directory

set -e

PROGRAM="${1:-COBDB2T13}"
SQB_FILE="${PROGRAM}.sqb"
CONTAINER="db2server"
DB2_USER="db2inst1"
DB2_PASS="AprendaCobol2026"
DB2_NAME="COBOLDB"
DB2_PROFILE="/database/config/db2inst1/sqllib/db2profile"
DB2_LIB="/opt/ibm/db2/V11.5/lib64"
PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "${PROJ_DIR}/${SQB_FILE}" ]; then
    echo "ERRO: Arquivo ${SQB_FILE} nao encontrado em ${PROJ_DIR}" >&2
    exit 1
fi

echo "==> [1/4] Copiando ${SQB_FILE} para o container..."
docker cp "${PROJ_DIR}/${SQB_FILE}" "${CONTAINER}:/tmp/${SQB_FILE}"

echo "==> [2/4] Precompilando (db2 PREP) dentro do container..."
docker exec -u "${DB2_USER}" "${CONTAINER}" bash -c "
    source '${DB2_PROFILE}'
    db2 connect to ${DB2_NAME} user ${DB2_USER} using ${DB2_PASS}
    db2 prep /tmp/${SQB_FILE} bindfile
    db2 bind /tmp/${PROGRAM}.bnd
    db2 connect reset
"

echo "==> [3/4] Compilando com cobc dentro do container..."
docker cp "${PROJ_DIR}/sqlca.cbl" "${CONTAINER}:/tmp/sqlca.cbl" 2>/dev/null || \
    docker exec "${CONTAINER}" bash -c \
        "cp /opt/ibm/db2/V11.5/include/cobol_a/sqlca.cbl /tmp/sqlca.cbl"

# Stub para sqlgmf (ausente no libdb2.so da Community Edition)
docker exec "${CONTAINER}" bash -c \
    "echo 'void sqlgmf(int x){(void)x;}' > /tmp/sqlgmf_stub.c && gcc -c /tmp/sqlgmf_stub.c -o /tmp/sqlgmf_stub.o"

docker exec "${CONTAINER}" bash -c "
    cobc -x /tmp/${PROGRAM}.cbl \
        -I/tmp \
        -L${DB2_LIB} \
        -ldb2 \
        /tmp/sqlgmf_stub.o \
        -o /tmp/${PROGRAM} 2>&1
"

echo "==> [4/4] Copiando executavel para o projeto..."
docker cp "${CONTAINER}:/tmp/${PROGRAM}" "${PROJ_DIR}/${PROGRAM}"
chmod +x "${PROJ_DIR}/${PROGRAM}"

echo ""
echo "Build concluido: ${PROJ_DIR}/${PROGRAM}"
echo "Para executar:"
echo "  docker exec -u ${DB2_USER} ${CONTAINER} bash -c 'source ${DB2_PROFILE} && /tmp/${PROGRAM}'"
