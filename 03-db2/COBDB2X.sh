#!/bin/bash
# ===========================================================================
#//* ===================================================================== *
#//*                                                                       *
#//*  JOB NAME : COBDB2X                                                   *
#//*  DESC     : EXECUTE COBOL+DB2 PROGRAM IN DB2 CONTAINER               *
#//*  STEPS    : STEP010 - DEPLOY  (COPY BINARY TO CONTAINER)              *
#//*             STEP020 - EXECUTE (RUN PROGRAM IN DB2 ENVIRONMENT)        *
#//*                                                                       *
#//* ===================================================================== *
#
# ---------------------------------------------------------------------------
#//COBDB2X  JOB CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
# ---------------------------------------------------------------------------
#
#//* ----------------------------------------------------------------------- *
#//*  SYSIN - PARAMETROS DO JOB (PREENCHA ANTES DE EXECUTAR)                *
#//* ----------------------------------------------------------------------- *
#//SYSIN DD *

    #-----------------------------------------------------------
    # PROGRAMA A EXECUTAR
    #-----------------------------------------------------------
    EXEC_NAME="COBDB2T13"       # Nome do executavel (binario compilado)
    EXEC_DIR="/home/hubfy/dev/aprenda-cobol-lab/03-db2"  # Diretorio do executavel no host

    #-----------------------------------------------------------
    # DB2 SERVER
    #-----------------------------------------------------------
    DB2_SERVER="db2server"      # Nome do container Docker com o DB2
    DB2_USER="db2inst1"         # Usuario da instancia DB2

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

echo "//$(printf '%-8s' "$EXEC_NAME")  EXEC PGM=COBDB2X"
echo "//*"
echo "//*  PROGRAMA: ${EXEC_DIR}/${EXEC_NAME}"
echo "//*  SERVER  : ${DB2_SERVER}"
echo "//*"

# ---------------------------------------------------------------------------
#//STEP010  EXEC PGM=DEPLOY,PARM='COPY BINARY TO CONTAINER'
# ---------------------------------------------------------------------------
echo "//STEP010  EXEC PGM=DEPLOY"

if [ ! -f "${EXEC_DIR}/${EXEC_NAME}" ]; then
    echo "//STEP010  ABEND - EXECUTAVEL NAO ENCONTRADO: ${EXEC_DIR}/${EXEC_NAME}" >&2
    exit 8
fi

docker cp "${EXEC_DIR}/${EXEC_NAME}" "${DB2_SERVER}:/tmp/${EXEC_NAME}"
docker exec "${DB2_SERVER}" bash -c "chmod +x /tmp/${EXEC_NAME}"

echo "//STEP010  COPY  SRC=${EXEC_DIR}/${EXEC_NAME} DST=${DB2_SERVER}:/tmp/${EXEC_NAME}"
echo "//STEP010  RC=0000 - DEPLOY CONCLUIDO"

# ---------------------------------------------------------------------------
#//STEP020  EXEC PGM=EXECUTE
# ---------------------------------------------------------------------------
echo "//STEP020  EXEC PGM=${EXEC_NAME}"
echo "//*"
echo "//*  ---- SAIDA DO PROGRAMA ----"
echo "//*"

docker exec -u "${DB2_USER}" "${DB2_SERVER}" bash -c "
    source '${DB2_PROFILE}'
    export LD_LIBRARY_PATH=${DB2_LIB}:\$LD_LIBRARY_PATH
    /tmp/${EXEC_NAME}
"
STEP020_RC=$?

echo "//*"
echo "//*  ---- FIM DA SAIDA ----"
echo "//*"

if [ "${STEP020_RC}" -ne 0 ]; then
    echo "//STEP020  ABEND - PROGRAMA TERMINOU COM RC=${STEP020_RC}" >&2
    exit "${STEP020_RC}"
fi

echo "//STEP020  RC=0000 - EXECUTE CONCLUIDO"

# ---------------------------------------------------------------------------
#//JOBEND
# ---------------------------------------------------------------------------
echo "//*"
echo "//*  JOB COBDB2X CONCLUIDO COM SUCESSO"
echo "//*"
echo "//JOBEND"
