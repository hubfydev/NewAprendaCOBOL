# Arquitetura: COBOL Application Server (04-api)

## Visão Geral

Uma API única que funciona como um **servidor de aplicação** para executáveis GNU COBOL,
permitindo que programas COBOL sejam chamados por interfaces Web (HTML, PHP, Java) ou
Mobile (Android, iOS) via HTTP REST e WebSocket.

```
Frontend Web / Mobile App
         │
    HTTP REST / WebSocket (JSON)
         │
┌────────▼────────────────────────────────────────────┐
│           COBOL Application Server                  │
│             Node.js + Express + ws                  │
│                                                     │
│  ProcessManager (controle de concorrência)          │
│   ├── Semáforo por programa (maxConcurrent)         │
│   ├── Fila de espera com timeout (queueMax)         │
│   ├── Limite global de processos                    │
│   └── Watchdog: mata processo travado               │
│                                                     │
│  Commarea Converter (JSON ↔ registro fixo COBOL)    │
└────────┬────────────────────────────────────────────┘
         │
   stdin/stdout pipe (registro fixo estilo CICS)
         │
┌────────▼────────────────────────────────────────────┐
│         GNU COBOL Executables (./bin/)               │
│                                                     │
│   WORKING-STORAGE SECTION                           │
│     01 WS-INPUT  / WS-OUTPUT  (registro fixo)       │
│   PROCEDURE DIVISION                                │
│     ACCEPT WS-INPUT  ← lê da API via stdin          │
│     DISPLAY WS-OUTPUT ← responde à API via stdout   │
└─────────────────────────────────────────────────────┘
```

---

## Decisões de Design

### 1. Comunicação: Registro Fixo (estilo CICS COMMAREA)

A API converte JSON para um buffer de bytes de tamanho fixo conforme os PICTURE clauses
definidos no `programs.json`. O COBOL lê com `ACCEPT` e escreve com `DISPLAY`.

```
API recebe JSON:   { "a": 10, "b": 5, "op": "ADD" }
        │
        ▼ commarea.js
stdin → "0000001000000005ADD       "   (30 bytes fixos)
                                       PIC 9(10)V99 | PIC 9(10)V99 | PIC X(10)

COBOL processa e escreve:
stdout → "000000150000OK        "
         PIC 9(10)V99 | PIC X(10)
        │
        ▼ commarea.js
API responde JSON: { "result": 15, "status": "OK" }
```

Esta abordagem foi escolhida porque:
- É autêntica ao modelo COBOL empresarial (CICS COMMAREA, IMS PCBs)
- Preserva a tipagem forte dos campos PICTURE
- A API (não o COBOL) é responsável pela serialização JSON

### 2. Registro de Programas: `programs.json`

Um único arquivo de configuração declara todos os executáveis disponíveis, seus layouts
de entrada/saída e limites de concorrência. Adicionar um novo programa COBOL não requer
alteração de código — apenas o registro e o executável compilado.

```json
{
  "calc": {
    "exec": "./bin/calc",
    "type": "one-shot",
    "maxConcurrent": 10,
    "queueMax": 50,
    "queueTimeout": 30000,
    "timeout": 5000,
    "input":  [{ "name": "a",  "pic": "9(10)V99" },
               { "name": "b",  "pic": "9(10)V99" },
               { "name": "op", "pic": "X(10)"    }],
    "output": [{ "name": "result", "pic": "9(10)V99" },
               { "name": "status", "pic": "X(10)"    }]
  }
}
```

### 3. Concorrência: Modelo Application Server

Node.js é não-bloqueante: o event loop recebe todas as requisições simultâneas e delega
a execução dos processos COBOL ao SO, que os executa em paralelo real.

```
100 usuários → POST /api/run/calc simultaneamente
      │
      ▼
Node.js event loop (não bloqueia)
      │
      ▼
ProcessManager verifica semáforo "calc" (maxConcurrent: 10)
      │
 ┌────┴──────────────┐
 │                   │
10 spawns          90 entram na fila
imediatos
 │
 ├── spawn(calc) PID 1001
 ├── spawn(calc) PID 1002
 └── ... (paralelo real via SO)

  Cada COBOL termina → próximo da fila entra
```

Analogia com outros servidores de aplicação:
| Este servidor         | Equivalente                   |
|-----------------------|-------------------------------|
| maxConcurrent         | CICS MAX-TASKS / Tomcat threads |
| queueMax              | Tomcat acceptCount            |
| timeout + watchdog    | CICS DTIMOUT                  |
| programs.json         | EJB deployment descriptor     |

### 4. Programas Interativos: WebSocket

Programas COBOL que fazem múltiplas interações (ex: quiz, menus) ficam rodando como
processos vivos. A comunicação acontece via WebSocket — cada mensagem do cliente é
escrita no stdin do COBOL, e cada DISPLAY do COBOL é enviado ao cliente.

```
Browser ──WS connect──► session.js cria processo + sessionId
Browser ──WS send(R1)──► stdin.write(R1) ──► COBOL processa
COBOL DISPLAY(P2) ──────► stdout ──────────► WS send(P2) ──► Browser
...
COBOL STOP RUN ─────────► WS close ────────────────────────► Browser
```

---

## Fluxos de Uso

### One-shot (REST)

```
POST /api/run/:program
Content-Type: application/json
{ ...campos de entrada conforme programs.json... }

200 OK
{ ...campos de saída..., "_meta": { "exitCode": 0, "durationMs": 47 } }
```

### Interativo (WebSocket)

```
WS  /api/ws/:program

← { "type": "output", "data": "Primeira pergunta do COBOL" }
→ { "type": "input",  "data": "resposta do usuário" }
← { "type": "output", "data": "Próxima saída do COBOL" }
← { "type": "close",  "exitCode": 0 }
```

### Upload de Arquivo (Batch)

```
POST /api/upload/:program
Content-Type: multipart/form-data
file: dados.dat

202 Accepted
{ "jobId": "abc123", "status": "queued" }

GET /api/job/:jobId
{ "status": "done", "output": "...", "exitCode": 0 }
```

### Listagem de Programas

```
GET /api/programs

{
  "programs": [
    { "name": "calc",      "type": "one-shot",    "description": "..." },
    { "name": "quiz",      "type": "interactive", "description": "..." },
    { "name": "relatorio", "type": "one-shot",    "description": "..." }
  ]
}
```

### Health Check

```
GET /api/health

{
  "status": "ok",
  "uptime": 3600,
  "processes": {
    "active": 4,
    "globalLimit": 50
  },
  "programs": {
    "calc":   { "active": 3, "queued": 0, "maxConcurrent": 10 },
    "quiz":   { "active": 1, "queued": 0, "maxConcurrent": 20 }
  }
}
```

---

## Comportamento sob Carga

| Situação | Resposta HTTP |
|---|---|
| Processo disponível | `200 OK` com resultado JSON |
| Fila com capacidade | `202 Accepted` aguarda na fila |
| Fila cheia (queueMax) | `503 Service Unavailable` |
| Timeout do COBOL | `504 Gateway Timeout`, processo morto |
| Crash (exit ≠ 0) | `500 Internal Server Error` com stderr |
| Programa não registrado | `404 Not Found` |
| Input inválido | `422 Unprocessable Entity` |

---

## Estrutura de Arquivos

```
04-api/cobol-api/
├── programs.json              ← registry de programas e layouts COMMAREA
├── bin/                       ← executáveis COBOL compilados
├── programs/                  ← fontes .cob organizados por programa
│   ├── hello/hello.cob
│   └── calc/calc.cob
└── src/
    ├── index.js               ← Express + WebSocket server, graceful shutdown
    ├── commarea.js            ← converte JSON ↔ registro fixo (PICTURE parser)
    ├── processManager.js      ← semáforos, filas, watchdog, cleanup
    ├── runner.js              ← spawn + pipe stdin/stdout + timeout
    ├── session.js             ← sessões WebSocket para programas interativos
    └── routes/
        ├── programs.js        ← GET  /api/programs
        ├── run.js             ← POST /api/run/:program
        ├── files.js           ← POST /api/upload/:program
        ├── jobs.js            ← GET  /api/job/:jobId
        └── health.js          ← GET  /api/health
```

---

## Estrutura de um Programa COBOL compatível com esta API

```cobol
IDENTIFICATION DIVISION.
  PROGRAM-ID. CALC.
DATA DIVISION.
  WORKING-STORAGE SECTION.
    * Campos de entrada — tamanhos devem bater com programs.json
    01 WS-INPUT.
      05 WS-A      PIC 9(10)V99.
      05 WS-B      PIC 9(10)V99.
      05 WS-OP     PIC X(10).
    * Campos de saída
    01 WS-OUTPUT.
      05 WS-RESULT PIC 9(10)V99.
      05 WS-STATUS PIC X(10).
PROCEDURE DIVISION.
    ACCEPT WS-INPUT          *> lê registro fixo do stdin (enviado pela API)
    * ... lógica de negócio ...
    MOVE "OK        " TO WS-STATUS
    DISPLAY WS-OUTPUT        *> escreve registro fixo no stdout (lido pela API)
    STOP RUN.
```

---

## Tecnologias

| Componente | Tecnologia | Motivo |
|---|---|---|
| Servidor HTTP | Node.js + Express 5 | Não-bloqueante, ideal para I/O de subprocessos |
| WebSocket | ws (npm) | Leve, sem overhead de Socket.io |
| Processos COBOL | child_process.spawn | Comunicação assíncrona via streams |
| Semáforos | async-sema (npm) | Controle de concorrência sem bloquear event loop |
| Compilador COBOL | GnuCOBOL (cobc) | Open source, Fedora package |

---

_Projeto: Aprenda COBOL Lab — Módulo 04-api_
