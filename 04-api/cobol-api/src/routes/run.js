'use strict'

const { Router } = require('express')
const programs = require('../../programs.json')
const { runProgram } = require('../runner')
const { validateInput } = require('../validation')

const router = Router()

const STATUS_MAP = {
  QUEUE_FULL:    503,
  QUEUE_TIMEOUT: 503,
  GLOBAL_LIMIT:  503,
  TIMEOUT:       504,
  EXIT_ERROR:    500,
  SPAWN_ERROR:   500
}

router.post('/:program', async (req, res) => {
  const { program } = req.params
  const config = programs[program]

  if (!config) {
    return res.status(404).json({ error: 'Programa não encontrado', program })
  }
  if (config.type === 'interactive') {
    return res.status(400).json({
      error: 'Este programa é interativo. Use WebSocket.',
      wsEndpoint: `ws://HOST/api/ws/${program}`
    })
  }

  // Validação de entrada antes de chamar o COBOL
  const errors = validateInput(config.input, req.body || {})
  if (errors.length > 0) {
    return res.status(422).json({
      error: 'Dados de entrada inválidos',
      code: 'VALIDATION_ERROR',
      details: errors
    })
  }

  try {
    const result = await runProgram(program, config, req.body || {})
    res.json(result)
  } catch (err) {
    const status = STATUS_MAP[err.code] || 500
    res.status(status).json({
      error:   err.message,
      code:    err.code,
      ...(err.exitCode   !== undefined && { exitCode:   err.exitCode }),
      ...(err.stderr     !== undefined && { stderr:     err.stderr }),
      ...(err.durationMs !== undefined && { durationMs: err.durationMs })
    })
  }
})

module.exports = router
