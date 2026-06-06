# Aprenda COBOL Lab

Laboratório de aprendizado GNU COBOL com foco em integração moderna:
programas COBOL compilados servidos como backend via API REST/WebSocket,
consumidos por interfaces Web (PHP, HTML) ou Mobile (Android, iOS).

```
GNU COBOL (backend)  →  Node.js API  →  PHP / HTML / Mobile (frontend)
```

---

## Índice

1. [Estrutura do projeto](#estrutura-do-projeto)
2. [Pré-requisitos e instalação](#pré-requisitos-e-instalação)
3. [Como rodar](#como-rodar)
4. [Como criar um novo programa COBOL](#como-criar-um-novo-programa-cobol)
5. [Formato COMMAREA — como os dados trafegam](#formato-commarea--como-os-dados-trafegam)
6. [Registrar o programa na API (programs.json)](#registrar-o-programa-na-api-programsjson)
7. [Compilar e testar com curl](#compilar-e-testar-com-curl)
8. [Como trocar parâmetros de entrada e saída](#como-trocar-parâmetros-de-entrada-e-saída)
9. [Adicionar uma nova página PHP](#adicionar-uma-nova-página-php)
10. [Referência da API](#referência-da-api)
11. [Módulos do laboratório](#módulos-do-laboratório)

---

## Estrutura do projeto

```
aprenda-cobol-lab/
├── ARCHITECTURE.md          ← decisões de arquitetura detalhadas
├── README.md                ← este arquivo
│
├── 01-hello/                ← introdução ao COBOL
├── 02-files/                ← leitura e escrita de arquivos
├── 03-db2/                  ← integração com DB2
│
└── 04-api/                  ← servidor de aplicação COBOL
    ├── cobol-api/           ← API Node.js (servidor principal)
    │   ├── index.js         ← entry point (Express + WebSocket)
    │   ├── programs.json    ← registry: todos os programas disponíveis
    │   ├── Makefile         ← compila os .cob para ./bin/
    │   ├── bin/             ← executáveis COBOL compilados
    │   ├── programs/        ← fontes .cob organizados por programa
    │   │   ├── hello/hello.cob
    │   │   └── calc/calc.cob
    │   └── src/
    │       ├── commarea.js        ← PICTURE parser + JSON ↔ registro fixo
    │       ├── processManager.js  ← semáforos, filas, watchdog
    │       ├── runner.js          ← spawn + stdin/stdout pipe
    │       ├── session.js         ← sessões WebSocket (programas interativos)
    │       ├── jobStore.js        ← jobs assíncronos (upload/batch)
    │       ├── validation.js      ← valida campos antes de chamar COBOL
    │       └── routes/
    │           ├── programs.js    ← GET  /api/programs
    │           ├── run.js         ← POST /api/run/:program
    │           ├── files.js       ← POST /api/upload/:program
    │           ├── jobs.js        ← GET  /api/job/:jobId
    │           └── health.js      ← GET  /api/health
    │
    ├── frontend-php/        ← interface web em PHP
    │   ├── router.php       ← dispatcher de rotas
    │   └── pages/
    │       ├── home.php     ← lista de programas disponíveis
    │       ├── calc.php     ← calculadora COBOL
    │       └── 404.php
    │
    └── frontend-html/       ← interface web em HTML puro (sem servidor)
        └── index.html       ← calculadora via fetch() JavaScript

└── 05-games/                ← jogos em COBOL (em desenvolvimento)
```

---

## Pré-requisitos e instalação

### GNU COBOL (compilador)

```bash
# Fedora / RHEL
sudo dnf install -y gnucobol

# Ubuntu / Debian
sudo apt install -y gnucobol

# Verificar
cobc --version
```

### Node.js (API)

```bash
# Verificar (requer >= 18)
node --version

# Instalar dependências da API
cd 04-api/cobol-api
npm install
```

### PHP (interface web)

```bash
# Fedora / RHEL
sudo dnf install -y php php-cli php-curl

# Ubuntu / Debian
sudo apt install -y php php-cli

# Verificar
php --version
```

---

## Como rodar

Abra **dois terminais**:

**Terminal 1 — API COBOL:**
```bash
cd 04-api/cobol-api
make all       # compila todos os programas COBOL
npm start      # sobe o servidor na porta 3000
```

**Terminal 2 — Interface Web PHP:**
```bash
cd 04-api/frontend-php
php -S localhost:8080 router.php
```

| URL | O que é |
|---|---|
| `http://localhost:8080` | Home — lista de programas |
| `http://localhost:8080/calc` | Calculadora COBOL |
| `http://localhost:3000/api/programs` | API: lista de programas |
| `http://localhost:3000/api/health` | API: status do servidor |

A interface HTML não precisa de servidor — abra diretamente:

```bash
xdg-open 04-api/frontend-html/index.html
```

---

## Como criar um novo programa COBOL

Exemplo completo: programa **SAUDACAO** que recebe um nome e retorna uma mensagem personalizada.

### Passo 1 — Criar o fonte .cob

```bash
mkdir -p 04-api/cobol-api/programs/saudacao
```

Crie `04-api/cobol-api/programs/saudacao/saudacao.cob`:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SAUDACAO.
      *----------------------------------------------------------------
      * Programa: SAUDACAO
      * Entrada (stdin, 30 bytes):
      *   WS-NOME  X(30)  — nome do usuário
      * Saida (stdout, 60 bytes):
      *   WS-MSG   X(60)  — mensagem de saudação
      *----------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-INPUT.
          05 WS-NOME             PIC X(30).
       01 WS-OUTPUT.
          05 WS-MSG              PIC X(60).
       PROCEDURE DIVISION.
           ACCEPT WS-INPUT FROM STDIN
           PERFORM VALIDAR-ENTRADA
           IF WS-NOME NOT = SPACES
               PERFORM GERAR-SAUDACAO
           END-IF
           DISPLAY WS-OUTPUT UPON STDOUT
           STOP RUN.
       VALIDAR-ENTRADA.
           IF WS-NOME = SPACES
               MOVE "Nome nao informado." TO WS-MSG
           END-IF.
       GERAR-SAUDACAO.
           STRING "Ola, " DELIMITED SIZE
                  FUNCTION TRIM(WS-NOME) DELIMITED SIZE
                  "! Bem-vindo ao COBOL Lab." DELIMITED SIZE
                  INTO WS-MSG.
```

### Passo 2 — Adicionar ao Makefile

Em `04-api/cobol-api/Makefile`, adicione:

```makefile
PROGRAMS := hello calc saudacao   # ← adicionar aqui

saudacao:
	@mkdir -p $(BIN)
	$(COBC) $(COBFLAGS) -o $(BIN)/saudacao programs/saudacao/saudacao.cob
	@echo "  [OK] saudacao -> $(BIN)/saudacao"
```

### Passo 3 — Registrar em programs.json

Em `04-api/cobol-api/programs.json`, adicione:

```json
{
  "saudacao": {
    "exec": "./bin/saudacao",
    "type": "one-shot",
    "description": "Gera saudação personalizada com o nome informado",
    "maxConcurrent": 20,
    "queueMax": 100,
    "queueTimeout": 10000,
    "timeout": 5000,
    "input": [
      { "name": "nome", "pic": "X(30)" }
    ],
    "output": [
      { "name": "msg", "pic": "X(60)" }
    ]
  }
}
```

### Passo 4 — Compilar

```bash
cd 04-api/cobol-api
make saudacao
```

Saída esperada:
```
cobc -x -o bin/saudacao programs/saudacao/saudacao.cob
  [OK] saudacao -> bin/saudacao
```

### Passo 5 — Testar com curl

```bash
curl -s -X POST http://localhost:3000/api/run/saudacao \
  -H "Content-Type: application/json" \
  -d '{"nome": "Maria"}' | python3 -m json.tool
```

Resposta:
```json
{
    "msg": "Ola, Maria! Bem-vindo ao COBOL Lab.",
    "_meta": {
        "exitCode": 0,
        "durationMs": 4
    }
}
```

---

## Formato COMMAREA — como os dados trafegam

A API converte JSON para um **registro de tamanho fixo** (igual ao COMMAREA do CICS)
antes de enviar ao COBOL via `stdin`. O COBOL lê com `ACCEPT` e escreve com `DISPLAY`.

```
                     JSON (API) ←→ COMMAREA (COBOL)
                     ─────────────────────────────────

 Input:
   { "a": 15.5, "b": 4.5, "op": "ADD" }
            │
            ▼  commarea.js: toCommarea()
   "000000015050000000045000ADD       "   ← 34 bytes no stdin
    ────────────────────────────────────
    WS-A         WS-B         WS-OP
    9(10)V99     9(10)V99     X(10)
    12 bytes     12 bytes     10 bytes

 Output:
   "00000000002000OK        "   ← 24 bytes no stdout
    ──────────────────────────
    WS-RESULT    WS-STATUS
    9(12)V99     X(10)
    14 bytes     10 bytes
            │
            ▼  commarea.js: fromCommarea()
   { "result": 20, "status": "OK", "_meta": {...} }
```

### Regras de formatação por PICTURE

| PICTURE | Tipo | Formatação na COMMAREA |
|---|---|---|
| `X(n)` | Alfanumérico | String com `n` chars, preenchida com espaços à direita |
| `9(n)` | Numérico inteiro | Número com `n` dígitos, zeros à esquerda |
| `9(n)V99` | Numérico decimal | `n` dígitos inteiros + 2 decimais (sem ponto), total `n+2` chars |
| `9(n)V9(m)` | Numérico decimal | `n+m` chars, ponto virtual na posição `n` |

**Exemplos:**

```
Valor 15.5  →  PIC 9(10)V99  →  "000000001550"  (12 chars)
Valor "ADD" →  PIC X(10)     →  "ADD       "    (10 chars)
Valor 0     →  PIC 9(5)      →  "00000"          (5 chars)
```

---

## Registrar o programa na API (programs.json)

Cada entrada em `programs.json` define um programa COBOL disponível na API.

```json
{
  "nome-do-programa": {
    "exec":         "./bin/nome-do-programa",
    "type":         "one-shot",
    "description":  "Descrição exibida na home e em GET /api/programs",
    "maxConcurrent": 10,
    "queueMax":      50,
    "queueTimeout":  30000,
    "timeout":       5000,
    "input": [
      { "name": "campo1", "pic": "X(30)"    },
      { "name": "campo2", "pic": "9(8)V99"  },
      { "name": "campo3", "pic": "X(10)", "enum": ["OP1", "OP2"] }
    ],
    "output": [
      { "name": "resultado", "pic": "9(12)V99" },
      { "name": "status",    "pic": "X(10)"    }
    ]
  }
}
```

### Campos de configuração

| Campo | Descrição | Padrão |
|---|---|---|
| `exec` | Caminho para o executável compilado | obrigatório |
| `type` | `"one-shot"` (REST) ou `"interactive"` (WebSocket) | obrigatório |
| `description` | Texto descritivo exibido na home e na API | `""` |
| `maxConcurrent` | Máximo de instâncias simultâneas deste programa | `10` |
| `queueMax` | Máximo de requisições aguardando na fila | `50` |
| `queueTimeout` | ms antes de retornar 503 da fila | `30000` |
| `timeout` | ms antes de matar o processo COBOL | `10000` |
| `input` | Array de campos de entrada (COMMAREA de entrada) | `[]` |
| `output` | Array de campos de saída (COMMAREA de saída) | `[]` |

### Definição de campo

| Campo | Descrição |
|---|---|
| `name` | Nome da chave no JSON (`req.body` / resposta) |
| `pic` | PICTURE clause COBOL (`X(n)`, `9(n)`, `9(n)V9(m)`) |
| `enum` | *(opcional)* lista de valores permitidos — API retorna 422 se violado |

---

## Compilar e testar com curl

### Compilar programas

```bash
cd 04-api/cobol-api

make all          # compila todos os programas do Makefile
make calc         # compila só o calc
make saudacao     # compila só o saudacao
make clean        # remove todos os binários
```

### Testar manualmente o executável (sem a API)

```bash
# Envia COMMAREA diretamente para o COBOL via echo
echo "000000001000000000000500ADD       " | ./bin/calc
# Saída esperada: 00000000001500OK        
```

### Testar via API com curl

**Listar programas disponíveis:**
```bash
curl http://localhost:3000/api/programs
```

**Executar um programa (one-shot):**
```bash
curl -s -X POST http://localhost:3000/api/run/calc \
  -H "Content-Type: application/json" \
  -d '{"a": 10, "b": 3, "op": "DIV"}'
```

**Testar validação (campo faltando):**
```bash
curl -s -X POST http://localhost:3000/api/run/calc \
  -H "Content-Type: application/json" \
  -d '{"a": 10, "op": "ADD"}'
# → 422 com detalhes do campo inválido
```

**Testar validação (enum inválido):**
```bash
curl -s -X POST http://localhost:3000/api/run/calc \
  -H "Content-Type: application/json" \
  -d '{"a": 10, "b": 5, "op": "MOD"}'
# → 422: "Valor MOD inválido. Permitidos: ADD, SUB, MUL, DIV"
```

**Health check:**
```bash
curl http://localhost:3000/api/health
```

**Upload de arquivo (batch):**
```bash
curl -s -X POST http://localhost:3000/api/upload/calc \
  -F "file=@dados.dat"
# → 202 com { jobId, poll }

curl http://localhost:3000/api/job/{jobId}
# → status do job
```

---

## Como trocar parâmetros de entrada e saída

Quando os campos de um programa COBOL mudarem, atualize **dois lugares** sempre juntos:

### 1. O fonte COBOL (.cob)

Os campos da `WORKING-STORAGE SECTION` devem refletir os novos dados.

**Antes** — resultado como número inteiro:
```cobol
01 WS-OUTPUT.
   05 WS-RESULT  PIC 9(12)V99.
   05 WS-STATUS  PIC X(10).
```

**Depois** — adicionando campo de unidade:
```cobol
01 WS-OUTPUT.
   05 WS-RESULT  PIC 9(12)V99.
   05 WS-STATUS  PIC X(10).
   05 WS-UNIDADE PIC X(5).     ← novo campo
```

### 2. O programs.json

Os campos de `output` devem ter exatamente a mesma ordem e tamanho dos campos COBOL.

```json
"output": [
  { "name": "result",  "pic": "9(12)V99" },
  { "name": "status",  "pic": "X(10)"    },
  { "name": "unidade", "pic": "X(5)"     }
]
```

> **Regra de ouro:** a soma dos tamanhos dos campos de `input` em `programs.json`
> deve ser igual ao tamanho total de `WS-INPUT` no COBOL, e o mesmo para `output`.
> Um byte a mais ou a menos causa desalinhamento silencioso nos dados.

### Verificar o alinhamento

```bash
# Calcule o tamanho esperado dos campos:
# X(30) = 30, 9(10)V99 = 12, X(10) = 10 → total = 52

# Teste direto: envie exatamente N bytes e veja o COBOL responder corretamente
python3 -c "print('Maria' + ' '*25, end='')" | ./bin/saudacao
```

### Recompilar após mudanças no .cob

```bash
cd 04-api/cobol-api
make saudacao   # sempre recompilar após editar o .cob
```

---

## Adicionar uma nova página PHP

### Passo 1 — Criar a página

Crie `04-api/frontend-php/pages/saudacao.php`:

```php
<?php
$API_URL = 'http://localhost:3000/api/run/saudacao';
$result  = null;
$erro    = null;
$nome    = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nome = trim($_POST['nome'] ?? '');
    if (empty($nome)) {
        $erro = 'Informe um nome.';
    } else {
        $ch = curl_init($API_URL);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode(['nome' => $nome]),
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $raw  = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $data = json_decode($raw, true);
        if ($code === 200) {
            $result = $data['msg'];
        } else {
            $erro = $data['error'] ?? 'Erro desconhecido.';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"><title>Saudação COBOL</title></head>
<body>
  <h1>Saudação COBOL</h1>
  <form method="POST">
    <input type="text" name="nome" value="<?= htmlspecialchars($nome) ?>" placeholder="Seu nome">
    <button type="submit">Executar</button>
  </form>
  <?php if ($erro):   ?><p style="color:red"><?= htmlspecialchars($erro) ?></p><?php endif; ?>
  <?php if ($result): ?><p><strong><?= htmlspecialchars($result) ?></strong></p><?php endif; ?>
</body>
</html>
```

### Passo 2 — Registrar no router.php

```php
$routes = [
    '/'          => __DIR__ . '/pages/home.php',
    '/calc'      => __DIR__ . '/pages/calc.php',
    '/saudacao'  => __DIR__ . '/pages/saudacao.php',  // ← nova rota
];
```

### Passo 3 — Adicionar metadados na home.php

```php
$programMeta = [
    'calc' => [
        'icon'        => '×',
        'title'       => 'Calculadora',
        'description' => 'Soma, subtrai, multiplica e divide dois números.',
        'route'       => '/calc',
    ],
    'saudacao' => [                              // ← novo programa
        'icon'        => '👋',
        'title'       => 'Saudação',
        'description' => 'Gera saudação personalizada com o nome informado.',
        'route'       => '/saudacao',
    ],
];
```

Acesse: `http://localhost:8080/saudacao`

---

## Referência da API

Base URL: `http://localhost:3000`

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/api/programs` | Lista todos os programas registrados |
| `GET` | `/api/programs/:program` | Detalhes de um programa específico |
| `POST` | `/api/run/:program` | Executa programa one-shot (JSON body) |
| `POST` | `/api/upload/:program` | Executa programa com arquivo (form-data) |
| `GET` | `/api/job/:jobId` | Consulta resultado de job assíncrono |
| `GET` | `/api/health` | Status do servidor, processos ativos, filas |
| `WS` | `/api/ws/:program` | Sessão WebSocket para programa interativo |

### Códigos de status HTTP

| Código | Significado |
|---|---|
| `200` | Sucesso — resultado COBOL no body |
| `202` | Job criado (upload) — polling via `/api/job/:id` |
| `400` | Uso incorreto (ex: tentar REST em programa interativo) |
| `404` | Programa não encontrado no registry |
| `422` | Dados de entrada inválidos (validação antes de chamar COBOL) |
| `500` | COBOL encerrou com erro (exit ≠ 0) |
| `503` | Fila cheia ou limite global de processos atingido |
| `504` | Timeout — processo COBOL ultrapassou o tempo configurado |

### Formato da resposta de sucesso (one-shot)

```json
{
  "campo1": "valor1",
  "campo2": 42.5,
  "_meta": {
    "exitCode": 0,
    "durationMs": 4
  }
}
```

### Formato da resposta de erro (validação)

```json
{
  "error": "Dados de entrada inválidos",
  "code": "VALIDATION_ERROR",
  "details": [
    { "field": "op",  "message": "Valor \"MOD\" inválido. Permitidos: ADD, SUB, MUL, DIV" },
    { "field": "b",   "message": "Campo obrigatório" }
  ]
}
```

### WebSocket — protocolo de mensagens

```json
// Cliente → servidor
{ "type": "input", "data": "texto enviado ao COBOL via stdin" }

// Servidor → cliente
{ "type": "output",  "data": "saída do COBOL via stdout" }
{ "type": "error",   "data": "mensagem de stderr" }
{ "type": "close",   "exitCode": 0 }
```

---

## Módulos do laboratório

| Pasta | Conteúdo |
|---|---|
| `01-hello/` | Primeiros programas COBOL — IDENTIFICATION, DATA, PROCEDURE |
| `02-files/` | Leitura e escrita de arquivos sequenciais |
| `03-db2/` | Integração com IBM DB2 (embedded SQL, SQLCA) |
| `04-api/` | Servidor de aplicação — REST API + interfaces Web |
| `05-games/` | Quiz e jogos interativos em COBOL (em desenvolvimento) |

---

*GNU COBOL — aprenda COBOL com integração moderna.*
