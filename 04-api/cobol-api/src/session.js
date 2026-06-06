'use strict'

const { spawn } = require('child_process')
const path = require('path')
const processManager = require('./processManager')

const ROOT = path.resolve(__dirname, '..')
const activeSessions = new Map()

/**
 * Cria sessão WebSocket para programa COBOL interativo.
 * O processo COBOL fica vivo durante toda a sessão.
 *
 * Protocolo de mensagens WebSocket (JSON):
 *   Cliente → servidor: { "type": "input",  "data": "texto enviado ao COBOL" }
 *   Servidor → cliente: { "type": "output", "data": "saída do COBOL" }
 *   Servidor → cliente: { "type": "error",  "data": "stderr do COBOL" }
 *   Servidor → cliente: { "type": "close",  "exitCode": 0 }
 */
async function createSession(ws, programName, config) {
  await processManager.acquire(programName, config)

  const execPath = path.resolve(ROOT, config.exec)
  const proc = spawn(execPath, [], { cwd: ROOT, env: process.env })

  processManager.track(proc.pid, { program: programName, type: 'interactive' })
  activeSessions.set(ws, { proc, programName })

  const sessionMs = config.sessionTimeout || 300000
  const watchdog = setTimeout(() => {
    proc.kill('SIGKILL')
    if (ws.readyState === ws.OPEN) {
      ws.close(1001, 'Session timeout')
    }
  }, sessionMs)

  proc.stdout.on('data', data => {
    if (ws.readyState === ws.OPEN) {
      ws.send(JSON.stringify({ type: 'output', data: data.toString() }))
    }
  })

  proc.stderr.on('data', data => {
    if (ws.readyState === ws.OPEN) {
      ws.send(JSON.stringify({ type: 'error', data: data.toString() }))
    }
  })

  proc.on('close', exitCode => {
    clearTimeout(watchdog)
    processManager.untrack(proc.pid)
    processManager.release(programName)
    activeSessions.delete(ws)
    if (ws.readyState === ws.OPEN) {
      ws.send(JSON.stringify({ type: 'close', exitCode }))
      ws.close()
    }
  })

  ws.on('message', raw => {
    try {
      const { data } = JSON.parse(raw)
      if (proc.stdin.writable) {
        proc.stdin.write(String(data) + '\n')
      }
    } catch {
      // ignora mensagens malformadas
    }
  })

  ws.on('close', () => {
    clearTimeout(watchdog)
    activeSessions.delete(ws)
    if (!proc.killed) {
      proc.kill('SIGTERM')
      setTimeout(() => { if (!proc.killed) proc.kill('SIGKILL') }, 2000)
    }
    processManager.untrack(proc.pid)
    processManager.release(programName)
  })
}

function sessionCount() {
  return activeSessions.size
}

module.exports = { createSession, sessionCount }
