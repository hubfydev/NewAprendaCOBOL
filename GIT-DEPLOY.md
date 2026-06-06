# Git Deploy — Aprenda COBOL

Guia de configuração e uso do repositório Git para o projeto **NewAprendaCOBOL**.

---

## Repositório

| Item | Valor |
|---|---|
| Remote | `https://github.com/hubfydev/NewAprendaCOBOL.git` |
| Branch principal | `main` |
| Visibilidade | Público |

---

## Configuração inicial (já realizada)

Os passos abaixo foram executados uma única vez para configurar o ambiente. Estão documentados aqui para referência caso precise reconfigurar em outra máquina.

### 1. Identidade global do git

```bash
git config --global user.name  "hubfydev"
git config --global user.email "thehubfy@gmail.com"
git config --global init.defaultBranch main
```

### 2. Credential helper (HTTPS)

O GitHub não aceita senha de conta para push via HTTPS — exige **Personal Access Token (PAT)**. O helper `store` salva o token no disco após a primeira autenticação, evitando que seja pedido novamente:

```bash
git config --global credential.helper store
```

> As credenciais ficam gravadas em `~/.git-credentials` em texto simples.
> Adequado para máquina pessoal. Em máquinas compartilhadas prefira `cache` (memória, expira).

### 3. Inicializar o repositório local

```bash
cd /home/hubfy/dev/aprenda-cobol-lab
git init
git remote add origin https://github.com/hubfydev/NewAprendaCOBOL.git
```

---

## Primeiro push (já realizado)

O repositório remoto estava vazio. O primeiro commit enviado foi precedido de limpeza do índice para remover arquivos que não devem ser versionados (binários compilados, `node_modules`, arquivos gerados pelo precompilador DB2).

```bash
cd /home/hubfy/dev/aprenda-cobol-lab
git add .
git commit -m "refactor: limpa binarios e node_modules; adiciona .gitignore e estrutura de diretorios"
git push -u origin main
```

Na primeira vez, o git pediu as credenciais:

```
Username for 'https://github.com': hubfydev
Password for 'https://hubfydev@github.com': <PAT>
```

O `-u origin main` vincula a branch local `main` à remota — nos pushes seguintes basta `git push`.

---

## Workflow do dia a dia

```bash
# 1. Ver o que mudou
git status

# 2. Adicionar os arquivos alterados
git add .                         # todos
git add 03-db2/MEUPROG.sqb        # ou arquivo específico

# 3. Criar o commit
git commit -m "feat: adiciona programa MEUPROG com cursor DB2"

# 4. Enviar ao GitHub
git push
```

---

## Gerar ou renovar o PAT

O PAT é necessário para autenticação no push. Para gerar um novo:

1. GitHub → seu avatar → **Settings**
2. **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. **Generate new token (classic)**
4. Marque o escopo **`repo`** (acesso total a repositórios)
5. Copie o token gerado — ele só é exibido uma vez

Para atualizar o token salvo localmente:

```bash
# Apaga as credenciais salvas
rm ~/.git-credentials

# No próximo push o git pede novamente — informe o novo PAT
git push
```

---

## O que é versionado — `.gitignore`

```gitignore
# Node.js
node_modules/

# GnuCOBOL binários compilados (sem extensão)
03-db2/COBDB2T1
03-db2/COBDB2T12
03-db2/COBDB2T13

# Arquivos gerados pelo db2 prep (precompilador DB2)
03-db2/*.cbl
!03-db2/sqlca.cbl       # exceção: copybook DB2, mantido como referência
03-db2/*.bnd

# Arquivos objeto C
*.o

# Claude Code configurações locais
.claude/
```

**Regra geral:** só vai ao git o que foi escrito à mão — fontes `.sqb`, `.cob`, scripts `.sh`, fontes Node.js e documentação `.md`. Tudo que é gerado por compilação ou instalação de dependências fica fora.

---

## Estrutura versionada

```
NewAprendaCOBOL/
├── .gitignore
├── GIT-DEPLOY.md               ← este arquivo
├── 01-hello/                   (.gitkeep — estrutura reservada)
├── 02-files/                   (.gitkeep — estrutura reservada)
├── 03-db2/
│   ├── README.md               documentação do ambiente DB2
│   ├── COBDB2T1.cob            fonte COBOL puro
│   ├── COBDB2T12.cob           fonte COBOL puro
│   ├── COBDB2T13.sqb           fonte COBOL + SQL embutido
│   ├── sqlca.cbl               copybook SQLCA (IBM DB2)
│   ├── COBDB2C.sh              job de compilação (estilo JCL)
│   ├── COBDB2X.sh              job de execução  (estilo JCL)
│   └── build-sqb.sh            script de build auxiliar
├── 04-api/
│   └── cobol-api/
│       ├── index.js
│       ├── package.json
│       ├── package-lock.json
│       └── tsconfig.json
└── 05-games/
    └── cobol-quiz-game/
        ├── backend/            (.gitkeep — estrutura reservada)
        ├── cobol-core/         (.gitkeep — estrutura reservada)
        └── frontend/           (.gitkeep — estrutura reservada)
```

---

## Adicionar novo programa `.sqb` ao versionamento

Ao criar um novo programa `MEUPROG.sqb`, os arquivos gerados pelo build (`MEUPROG.cbl`, `MEUPROG.bnd`, e o binário `MEUPROG`) **não são versionados** automaticamente pelo `.gitignore`. Para incluir o novo binário na exclusão, adicione uma linha ao `.gitignore`:

```gitignore
# GnuCOBOL binários compilados (sem extensão)
03-db2/COBDB2T1
03-db2/COBDB2T12
03-db2/COBDB2T13
03-db2/MEUPROG        # ← adicionar aqui
```

O fonte `.sqb` é versionado normalmente:

```bash
git add 03-db2/MEUPROG.sqb .gitignore
git commit -m "feat: adiciona programa MEUPROG"
git push
```
