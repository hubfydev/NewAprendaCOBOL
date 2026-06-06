'use strict'

const { Router } = require('express')
const programs = require('../../programs.json')

const router = Router()

router.get('/', (req, res) => {
  const list = Object.entries(programs).map(([name, cfg]) => ({
    name,
    type: cfg.type,
    description: cfg.description || '',
    endpoint: cfg.type === 'interactive'
      ? `ws://${req.headers.host}/api/ws/${name}`
      : `POST /api/run/${name}`,
    input:  cfg.input  || [],
    output: cfg.output || []
  }))
  res.json({ count: list.length, programs: list })
})

router.get('/:program', (req, res) => {
  const cfg = programs[req.params.program]
  if (!cfg) return res.status(404).json({ error: 'Programa não encontrado' })
  res.json({ name: req.params.program, ...cfg })
})

module.exports = router
