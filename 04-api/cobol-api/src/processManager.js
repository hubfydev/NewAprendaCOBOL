'use strict'

/**
 * Semáforo por programa: controla concorrência e fila de espera.
 * Análogo ao MAX-TASKS do CICS ou ao thread pool do Tomcat.
 */
class Semaphore {
  constructor(max, queueMax, queueTimeout) {
    this._max = max
    this._queueMax = queueMax
    this._queueTimeout = queueTimeout
    this._active = 0
    this._queue = []
  }

  acquire() {
    return new Promise((resolve, reject) => {
      if (this._active < this._max) {
        this._active++
        return resolve()
      }
      if (this._queue.length >= this._queueMax) {
        const err = new Error('Fila cheia — tente novamente mais tarde')
        err.code = 'QUEUE_FULL'
        return reject(err)
      }
      let entry
      const timer = setTimeout(() => {
        const idx = this._queue.indexOf(entry)
        if (idx !== -1) this._queue.splice(idx, 1)
        const err = new Error('Tempo de espera na fila esgotado')
        err.code = 'QUEUE_TIMEOUT'
        reject(err)
      }, this._queueTimeout)
      entry = { resolve, timer }
      this._queue.push(entry)
    })
  }

  release() {
    if (this._queue.length > 0) {
      const next = this._queue.shift()
      clearTimeout(next.timer)
      next.resolve()
    } else {
      this._active = Math.max(0, this._active - 1)
    }
  }

  stats() {
    return { active: this._active, queued: this._queue.length, max: this._max }
  }
}

/**
 * Gerenciador global de processos COBOL.
 * Mantém semáforos por programa, limite global e rastreamento de PIDs.
 */
class ProcessManager {
  constructor(globalMax = 50) {
    this._globalMax = globalMax
    this._globalActive = 0
    this._semaphores = new Map()
    this._processes = new Map()
  }

  _semaphore(name, config = {}) {
    if (!this._semaphores.has(name)) {
      this._semaphores.set(name, new Semaphore(
        config.maxConcurrent || 10,
        config.queueMax      || 50,
        config.queueTimeout  || 30000
      ))
    }
    return this._semaphores.get(name)
  }

  async acquire(programName, config) {
    if (this._globalActive >= this._globalMax) {
      const err = new Error('Limite global de processos COBOL atingido')
      err.code = 'GLOBAL_LIMIT'
      throw err
    }
    await this._semaphore(programName, config).acquire()
    this._globalActive++
  }

  release(programName) {
    const sem = this._semaphores.get(programName)
    if (sem) sem.release()
    this._globalActive = Math.max(0, this._globalActive - 1)
  }

  track(pid, info) {
    this._processes.set(pid, { ...info, startTime: Date.now() })
  }

  untrack(pid) {
    this._processes.delete(pid)
  }

  stats() {
    const programs = {}
    for (const [name, sem] of this._semaphores) {
      programs[name] = sem.stats()
    }
    return {
      globalActive: this._globalActive,
      globalMax: this._globalMax,
      programs
    }
  }
}

module.exports = new ProcessManager(
  parseInt(process.env.COBOL_MAX_PROCESSES || '50', 10)
)
