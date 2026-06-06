# COBOL + DB2 no Linux — GnuCOBOL com SQL Embutido via Docker

Este projeto demonstra como compilar e executar programas COBOL com **SQL embutido (embedded SQL)** acessando o **IBM DB2** rodando em um container Docker, tudo a partir do **Fedora Linux** com **GnuCOBOL**.

---

## Ambiente

| Componente | Detalhe |
|---|---|
| Host | Fedora 44 Workstation (x86_64) |
| COBOL Compiler | GnuCOBOL 3.2 (`/usr/bin/cobc`) |
| DB2 Server | IBM DB2 V11.5.8 Community Edition (container Docker) |
| Container | `ibmcom/db2`, nome: `db2server` |
| Database | `COBOLDB` |
| Instância DB2 | `db2inst1` |
| IBM CLI Driver (host) | `/home/hubfy/dev/ibm-drivers/clidriver/` |

---

## Formato do fonte: `.sqb`

Programas COBOL que acessam DB2 com SQL embutido usam a extensão `.sqb` (**SQL Bound**). Dentro do código COBOL, as instruções SQL ficam entre as delimitadoras `EXEC SQL` e `END-EXEC`:

```cobol
EXEC SQL
    SELECT ID, NOME, EMAIL
      FROM ALUNOS
     ORDER BY ID
END-EXEC.
```

Antes de compilar, o fonte `.sqb` precisa passar pelo **precompilador DB2** (`db2 prep`), que substitui cada bloco `EXEC SQL...END-EXEC` por chamadas de API interna do DB2 (`sqlgstrt`, `sqlgcall`, `sqlgstop`, etc.), gerando um `.cbl` puro que o GnuCOBOL consegue compilar.

---

## Por que compilar e executar dentro do container?

A cadeia de compilação usa o `libdb2.so` do servidor DB2 dentro do container (`/opt/ibm/db2/V11.5/lib64/libdb2.so`). O IBM CLI Driver instalado no host (`clidriver`) provê apenas a interface ODBC/CLI — ele **não contém** as funções de runtime do SQL embutido (`sqlgstrt`, `sqlgcall`, etc.).

Além disso, o container roda RHEL 8 (glibc 2.28) enquanto o host roda Fedora 44 (glibc 2.43), então um binário compilado no host não rodaria no container. A solução é compilar **dentro do container** e copiar o resultado de volta ao host.

O GnuCOBOL 3.2 foi instalado no container via EPEL (CentOS Stream 8):

```bash
yum install -y gnucobol --disablerepo=baseos,appstream,extras
```

> **Nota:** Os repositórios BaseOS/AppStream do CentOS Stream 8 estão com mirrors quebrados. A instalação é feita apenas via EPEL, que já contém o GnuCOBOL e suas dependências de runtime.

---

## Detalhe técnico: o stub `sqlgmf`

O precompilador DB2 injeta chamadas para `sqlgmf` (SQL Get Message File) no código gerado. Essa função está **ausente** no `libdb2.so` da edição Community do container. A solução é fornecer um stub vazio em C, compilado e linkado junto ao programa:

```c
void sqlgmf(int x) { (void)x; }
```

Esse stub é gerado automaticamente pelos jobs de compilação — não é necessário nenhuma ação manual.

---

## Os "Jobs" — Scripts estilo JCL

Os dois scripts a seguir foram inspirados na estrutura de **JCL (Job Control Language)** dos Mainframes IBM: os parâmetros ficam declarados no topo do arquivo, em uma seção `//SYSIN DD *`, e os passos de processamento são organizados como `STEP010`, `STEP020`, etc. A saída no terminal usa o prefixo `//` como nas mensagens do JES2/JES3.

---

### `COBDB2C.sh` — Job de Compilação

**Equivalente JCL:** `COMPILE + LKED + BIND`

#### Passos executados

| Step | Equivalente Mainframe | O que faz |
|---|---|---|
| `STEP010` | `DB2PREP` + `DB2BIND` | Precompila o `.sqb` com `db2 prep`, gerando `.cbl` e `.bnd`; depois executa `db2 bind` para registrar o pacote na database |
| `STEP020` | `COBOL` + `LKED` | Compila o `.cbl` com `cobc` dentro do container, linkando contra `libdb2.so` |
| `STEP030` | `IEBCOPY` | Copia o executável gerado de volta ao diretório do projeto no host |

#### Parâmetros (`//SYSIN DD *`)

Abra `COBDB2C.sh` e edite a seção de parâmetros:

```bash
#//SYSIN DD *

    # FONTE
    PROG_NAME="COBDB2T13"       # Nome do programa fonte (sem extensão .sqb)
    PROG_DIR="/caminho/fontes"  # Diretório onde o .sqb está no host

    # SAIDA
    EXEC_NAME="COBDB2T13"       # Nome do executável a ser gerado

    # DB2 SERVER
    DB2_SERVER="db2server"      # Nome do container Docker
    DB2_USER="db2inst1"         # Usuário da instância DB2
    DB2_PASS="AprendaCobol2026" # Senha
    DB2_NAME="COBOLDB"          # Nome da database

#//* DD END
```

#### Como executar

```bash
bash COBDB2C.sh
```

#### Saída esperada

```
//COBDB2T13  EXEC PGM=COBDB2C
//*
//*  FONTE  : /caminho/fontes/COBDB2T13.sqb
//*  SAIDA  : /caminho/fontes/COBDB2T13
//*  SERVER : db2server / DATABASE: COBOLDB
//*
//STEP010  EXEC PGM=DB2PREP
//STEP010  COPY  SRC=...sqb DST=db2server:/tmp/COBDB2T13.sqb
//STEP010  DB2PREP PROG=COBDB2T13 DB=COBOLDB
//* PREP>  SQL0060W  The "COBOL" precompiler is in progress.
//* PREP>  SQL0091W  Precompilation ended with "0" errors and "0" warnings.
//* PREP>  SQL0061W  The binder is in progress.
//* PREP>  SQL0091N  Binding ended with "0" errors and "0" warnings.
//STEP010  RC=0000 - PRECOMPILE+BIND CONCLUIDO
//STEP020  EXEC PGM=GNUCOBOL
//STEP020  COBC PROG=COBDB2T13 LINK=DB2
//STEP020  RC=0000 - COMPILE+LINK CONCLUIDO
//STEP030  EXEC PGM=RETRIEVE
//STEP030  COPY  SRC=db2server:/tmp/COBDB2T13 DST=.../COBDB2T13
//STEP030  RC=0000 - RETRIEVE CONCLUIDO
//*
//*  JOB COBDB2C CONCLUIDO COM SUCESSO
//*  EXECUTAVEL: /caminho/fontes/COBDB2T13
//*
//JOBEND
```

---

### `COBDB2X.sh` — Job de Execução

**Equivalente JCL:** `GO step` (o passo de execução do programa)

#### Passos executados

| Step | Equivalente Mainframe | O que faz |
|---|---|---|
| `STEP010` | `IEBCOPY` / `DEPLOY` | Copia o executável do host para o container |
| `STEP020` | `GO` / `EXEC PGM=` | Executa o programa no ambiente DB2 do container (com `db2profile` carregado) |

#### Parâmetros (`//SYSIN DD *`)

Abra `COBDB2X.sh` e edite a seção de parâmetros:

```bash
#//SYSIN DD *

    # PROGRAMA A EXECUTAR
    EXEC_NAME="COBDB2T13"        # Nome do executável (binário compilado)
    EXEC_DIR="/caminho/binarios" # Diretório do executável no host

    # DB2 SERVER
    DB2_SERVER="db2server"       # Nome do container Docker
    DB2_USER="db2inst1"          # Usuário da instância DB2

#//* DD END
```

#### Como executar

```bash
bash COBDB2X.sh
```

#### Saída esperada

```
//COBDB2T13  EXEC PGM=COBDB2X
//*
//*  PROGRAMA: /caminho/binarios/COBDB2T13
//*  SERVER  : db2server
//*
//STEP010  EXEC PGM=DEPLOY
//STEP010  COPY  SRC=.../COBDB2T13 DST=db2server:/tmp/COBDB2T13
//STEP010  RC=0000 - DEPLOY CONCLUIDO
//STEP020  EXEC PGM=COBDB2T13
//*
//*  ---- SAIDA DO PROGRAMA ----
//*
====================================
****** APRENDA COBOL - LISTAGEM DE ALUNOS ******
====================================
NOME           SOBRENOME             EMAIL
Andre             Costa                       andre@email.com
Aluno             COBOL                       aluno@aprendacobol.com
====================================
********* FIM DO RELATORIO DE ALUNOS **************
====================================
//*
//*  ---- FIM DA SAIDA ----
//*
//STEP020  RC=0000 - EXECUTE CONCLUIDO
//*
//*  JOB COBDB2X CONCLUIDO COM SUCESSO
//*
//JOBEND
```

---

## Fluxo completo de desenvolvimento

```
┌─────────────────────────────────────────────────────────┐
│  HOST (Fedora 44)                                       │
│                                                         │
│  1. Editar fonte                                        │
│     MEUPROG.sqb  ←── você escreve aqui                 │
│                                                         │
│  2. Configurar e rodar COBDB2C.sh                       │
│     PROG_NAME="MEUPROG"                                 │
│     bash COBDB2C.sh                                     │
│                          │                              │
│                          ▼  docker cp + docker exec     │
│  ┌───────────────────────────────────────────────────┐  │
│  │  CONTAINER (db2server / RHEL 8)                   │  │
│  │                                                   │  │
│  │  db2 prep  MEUPROG.sqb → MEUPROG.cbl + .bnd       │  │
│  │  db2 bind  MEUPROG.bnd → pacote registrado        │  │
│  │  cobc      MEUPROG.cbl → MEUPROG (executável)     │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
│                          ▼  docker cp (de volta)        │
│     MEUPROG  ←── executável no projeto                  │
│                                                         │
│  3. Configurar e rodar COBDB2X.sh                       │
│     EXEC_NAME="MEUPROG"                                 │
│     bash COBDB2X.sh                                     │
│                          │                              │
│                          ▼  docker cp + docker exec     │
│  ┌───────────────────────────────────────────────────┐  │
│  │  CONTAINER (db2server / RHEL 8)                   │  │
│  │                                                   │  │
│  │  source db2profile                                │  │
│  │  /tmp/MEUPROG  ←── executa com acesso ao DB2      │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Arquivos do projeto

| Arquivo | Tipo | Descrição |
|---|---|---|
| `COBDB2T13.sqb` | Fonte | Programa COBOL com SQL embutido (lista alunos via cursor) |
| `COBDB2T13.cbl` | Gerado | Saída do `db2 prep` — COBOL puro com chamadas de API DB2 |
| `COBDB2T13.bnd` | Gerado | Bind file — pacote de acesso registrado na database |
| `COBDB2T13` | Executável | Binário compilado pelo GnuCOBOL dentro do container |
| `sqlca.cbl` | Copybook | SQLCA (SQL Communication Area) — copiado do container DB2 |
| `COBDB2C.sh` | Job | Script de compilação estilo JCL |
| `COBDB2X.sh` | Job | Script de execução estilo JCL |

---

## Condições de erro (ABEND)

Ambos os scripts saem com `exit 8` e exibem `//STEPXXX  ABEND` em caso de falha, assim como o comportamento de ABEND nos jobs JCL de Mainframe:

| Condição | Script | Mensagem |
|---|---|---|
| Arquivo `.sqb` não encontrado | `COBDB2C.sh` | `//STEP010  ABEND - FONTE NAO ENCONTRADO` |
| Executável não encontrado no host | `COBDB2X.sh` | `//STEP010  ABEND - EXECUTAVEL NAO ENCONTRADO` |
| Programa termina com RC != 0 | `COBDB2X.sh` | `//STEP020  ABEND - PROGRAMA TERMINOU COM RC=N` |
