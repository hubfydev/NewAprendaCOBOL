'use strict'

const express = require('express')
const http    = require('http')
const { WebSocketServer } = require('ws')
const programs = require('./programs.json')
const { createSession } = require('./src/session')

const app = express()

app.use(express.json())

// CORS — permite chamadas de qualquer origem (web app, mobile app)
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin',  '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  if (req.method === 'OPTIONS') return res.sendStatus(200)
  next()
})

app.use('/api/programs', require('./src/routes/programs'))
app.use('/api/run',      require('./src/routes/run'))
app.use('/api/upload',   require('./src/routes/files'))
app.use('/api/job',      require('./src/routes/jobs'))
app.use('/api/health',   require('./src/routes/health'))

app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' })
})

app.use((err, req, res, next) => {
  console.error('[ERRO]', err.message)
  res.status(500).json({ error: err.message })
})

const server = http.createServer(app)

// WebSocket: /api/ws/:program
const wss = new WebSocketServer({ noServer: true })

server.on('upgrade', (req, socket, head) => {
  if (!req.url.startsWith('/api/ws/')) {
    socket.destroy()
    return
  }
  wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws, req))
})

wss.on('connection', (ws, req) => {
  const programName = req.url.replace('/api/ws/', '').split('?')[0]
  const config = programs[programName]

  if (!config) {
    ws.close(1008, 'Programa não encontrado')
    return
  }
  if (config.type !== 'interactive') {
    ws.close(1008, `Programa não é interativo. Use: POST /api/run/${programName}`)
    return
  }

  createSession(ws, programName, config).catch(err => {
    if (ws.readyState === ws.OPEN) ws.close(1013, err.message)
  })
})

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Encerrando servidor...')
  server.close(() => {
    console.log('Servidor encerrado.')
    process.exit(0)
  })
})

const PORT = process.env.PORT || 3000
server.listen(PORT, () => {
  console.log('')
  console.log('  COBOL Application Server')
  console.log('  ─────────────────────────────────────────')
  console.log(`  REST  →  http://localhost:${PORT}/api/run/:program`)
  console.log(`  WS    →  ws://localhost:${PORT}/api/ws/:program`)
  console.log(`  Lista →  GET http://localhost:${PORT}/api/programs`)
  console.log(`  Saúde →  GET http://localhost:${PORT}/api/health`)
  console.log('  ─────────────────────────────────────────')
  console.log('')
})
