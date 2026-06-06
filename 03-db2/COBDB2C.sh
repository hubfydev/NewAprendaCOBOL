#!/bin/bash
# ===========================================================================
#//* ===================================================================== *
#//*                                                                       *
#//*  JOB NAME : COBDB2C                                                   *
#//*  DESC     : COMPILE COBOL+DB2 EMBEDDED SQL SOURCE (.SQB)              *
#//*  STEPS    : STEP010 - PRECOMPILE (DB2 PREP + BIND)                    *
#//*             STEP020 - COMPILE    (GNUCOBOL)                           *
#//*             STEP030 - RETRIEVE   (COPY BINARY TO HOST)                *
#//*                                                                       *
#//* ===================================================================== *
#
# ---------------------------------------------------------------------------
#//COBDB2C  JOB CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
# ---------------------------------------------------------------------------
#
#//* ----------------------------------------------------------------------- *
#//*  SYSIN - PARAMETROS DO JOB (PREENCHA ANTES DE EXECUTAR)                *
#//* ----------------------------------------------------------------------- *
#//SYSIN DD *

    #-----------------------------------------------------------
    # FONTE
    #-----------------------------------------------------------
    PROG_NAME="COBDB2T13"       # Nome do programa fonte (sem extensao)
    PROG_DIR="/home/hubfy/dev/aprenda-cobol-lab/03-db2"  # Diretorio do fonte

    #-----------------------------------------------------------
    # SAIDA
    #-----------------------------------------------------------
    EXEC_NAME="COBDB2T13"       # Nome do executavel a ser gerado

    #-----------------------------------------------------------
    # DB2 SERVER
    #-----------------------------------------------------------
    DB2_SERVER="db2server"      # Nome do container Docker com o DB2
    DB2_USER="db2inst1"         # Usuario da instancia DB2
    DB2_PASS="AprendaCobol2026" # Senha da instancia DB2
    DB2_NAME="COBOLDB"          # Nome da database DB2

#//* DD END
# ---------------------------------------------------------------------------


# ===========================================================================
#//* ===================================================================== *
#//*  AREA DE CONTROLE - NAO ALTERAR ABAIXO DESTA LINHA                   *
#//* ===================================================================== *
# ===========================================================================

set -e

DB2_PROFILE="/database/config/${DB2_USER}/sqllib/db2profile"
DB2_LIB="/opt/ibm/db2/V11.5/lib64"
SQB_FILE="${PROG_NAME}.sqb"
CBL_FILE="${PROG_NAME}.cbl"
BND_FILE="${PROG_NAME}.bnd"

echo "//$(printf '%-8s' "$PROG_NAME")  EXEC PGM=COBDB2C"
echo "//*"
echo "//*  FONTE  : ${PROG_DIR}/${SQB_FILE}"
echo "//*  SAIDA  : ${PROG_DIR}/${EXEC_NAME}"
echo "//*  SERVER : ${DB2_SERVER} / DATABASE: ${DB2_NAME}"
echo "//*"

# ---------------------------------------------------------------------------
#//STEP010  EXEC PGM=DB2PREP,PARM='PRECOMPILE+BIND'
# ---------------------------------------------------------------------------
echo "//STEP010  EXEC PGM=DB2PREP"

if [ ! -f "${PROG_DIR}/${SQB_FILE}" ]; then
    echo "//STEP010  ABEND - FONTE NAO ENCONTRADO: ${PROG_DIR}/${SQB_FILE}" >&2
    exit 8
fi

echo "//STEP010  COPY  SRC=${PROG_DIR}/${SQB_FILE} DST=${DB2_SERVER}:/tmp/${SQB_FILE}"
docker cp "${PROG_DIR}/${SQB_FILE}" "${DB2_SERVER}:/tmp/${SQB_FILE}"

echo "//STEP010  DB2PREP PROG=${PROG_NAME} DB=${DB2_NAME}"
docker exec -u "${DB2_USER}" "${DB2_SERVER}" bash -c "
    source '${DB2_PROFILE}'
    db2 connect to ${DB2_NAME} user ${DB2_USER} using ${DB2_PASS}
    db2 prep /tmp/${SQB_FILE} bindfile
    db2 bind  /tmp/${BND_FILE}
    db2 connect reset
" 2>&1 | sed 's/^/\/\/* PREP> /'

echo "//STEP010  RC=0000 - PRECOMPILE+BIND CONCLUIDO"

# ---------------------------------------------------------------------------
#//STEP020  EXEC PGM=GNUCOBOL,PARM='COMPILE+LINK'
# ---------------------------------------------------------------------------
echo "//STEP020  EXEC PGM=GNUCOBOL"

# Garante o sqlca.cbl no container
if [ -f "${PROG_DIR}/sqlca.cbl" ]; then
    docker cp "${PROG_DIR}/sqlca.cbl" "${DB2_SERVER}:/tmp/sqlca.cbl"
else
    docker exec "${DB2_SERVER}" bash -c \
        "cp /opt/ibm/db2/V11.5/include/cobol_a/sqlca.cbl /tmp/sqlca.cbl"
fi

# Stub para sqlgmf (ausente no libdb2.so da Community Edition)
docker exec "${DB2_SERVER}" bash -c \
    "printf 'void sqlgmf(int x){(void)x;}\n' > /tmp/sqlgmf_stub.c && gcc -c /tmp/sqlgmf_stub.c -o /tmp/sqlgmf_stub.o"

echo "//STEP020  COBC PROG=${PROG_NAME} LINK=DB2"
docker exec "${DB2_SERVER}" bash -c "
    cobc -x /tmp/${CBL_FILE} \
        -I/tmp \
        -L${DB2_LIB} \
        -ldb2 \
        /tmp/sqlgmf_stub.o \
        -o /tmp/${EXEC_NAME} 2>&1
" | sed 's/^/\/\/* COBC> /'

echo "//STEP020  RC=0000 - COMPILE+LINK CONCLUIDO"

# ---------------------------------------------------------------------------
#//STEP030  EXEC PGM=RETRIEVE,PARM='COPY BINARY TO HOST'
# ---------------------------------------------------------------------------
echo "//STEP030  EXEC PGM=RETRIEVE"

docker cp "${DB2_SERVER}:/tmp/${EXEC_NAME}" "${PROG_DIR}/${EXEC_NAME}"
chmod +x "${PROG_DIR}/${EXEC_NAME}"

echo "//STEP030  COPY  SRC=${DB2_SERVER}:/tmp/${EXEC_NAME} DST=${PROG_DIR}/${EXEC_NAME}"
echo "//STEP030  RC=0000 - RETRIEVE CONCLUIDO"

# ---------------------------------------------------------------------------
#//JOBEND
# ---------------------------------------------------------------------------
echo "//*"
echo "//*  JOB COBDB2C CONCLUIDO COM SUCESSO"
echo "//*  EXECUTAVEL: ${PROG_DIR}/${EXEC_NAME}"
echo "//*"
echo "//JOBEND"
