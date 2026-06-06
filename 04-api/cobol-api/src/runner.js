'use strict'

const { spawn } = require('child_process')
const path = require('path')
const processManager = require('./processManager')
const { toCommarea, fromCommarea } = require('./commarea')

const ROOT = path.resolve(__dirname, '..')

/**
 * Executa um programa COBOL como subprocesso.
 *
 * Fluxo:
 *   1. Adquire semáforo (bloqueia se no limite de concorrência)
 *   2. Converte inputData JSON → COMMAREA (registro fixo)
 *   3. Faz spawn do executável e escreve no stdin
 *   4. Coleta stdout e converte de volta para JSON
 *   5. Libera semáforo ao terminar (ou ao falhar)
 *
 * @param {string} programName  - chave no programs.json
 * @param {object} config       - configuração do programa
 * @param {object} inputData    - campos de entrada (JSON)
 * @param {object} options      - { rawStdin: string } para bypass do commarea (batch/file)
 */
async function runProgram(programName, config, inputData = {}, options = {}) {
  await processManager.acquire(programName, config)

  return new Promise((resolve, reject) => {
    const execPath = path.resolve(ROOT, config.exec)
    const start = Date.now()
    let proc

    try {
      proc = spawn(execPath, [], { cwd: ROOT, env: process.env })
    } catch (spawnErr) {
      processManager.release(programName)
      spawnErr.code = 'SPAWN_ERROR'
      return reject(spawnErr)
    }

    processManager.track(proc.pid, { program: programName, type: 'one-shot' })

    let stdout = ''
    let stderr = ''

    proc.stdout.on('data', d => { stdout += d.toString() })
    proc.stderr.on('data', d => { stderr += d.toString() })

    const timeoutMs = config.timeout || 10000
    const watchdog = setTimeout(() => {
      proc.kill('SIGKILL')
      const err = new Error(`Processo COBOL excedeu timeout de ${timeoutMs}ms`)
      err.code = 'TIMEOUT'
      reject(err)
    }, timeoutMs)

    proc.on('close', exitCode => {
      clearTimeout(watchdog)
      processManager.untrack(proc.pid)
      processManager.release(programName)

      const durationMs = Date.now() - start

      if (exitCode !== 0) {
        const err = new Error(`COBOL encerrou com código ${exitCode}`)
        err.code = 'EXIT_ERROR'
        err.exitCode = exitCode
        err.stderr = stderr.trim()
        err.durationMs = durationMs
        return reject(err)
      }

      const outputData = config.output && config.output.length > 0
        ? fromCommarea(stdout.trimEnd(), config.output)
        : { raw: stdout.trimEnd() }

      resolve({ ...outputData, _meta: { exitCode: 0, durationMs } })
    })

    proc.on('error', err => {
      clearTimeout(watchdog)
      processManager.untrack(proc.pid)
      processManager.release(programName)
      err.code = 'SPAWN_ERROR'
      reject(err)
    })

    if (options.rawStdin !== undefined) {
      proc.stdin.write(options.rawStdin)
    } else if (config.input && config.input.length > 0) {
      proc.stdin.write(toCommarea(inputData, config.input) + '\n')
    }
    proc.stdin.end()
  })
}

module.exports = { runProgram }
