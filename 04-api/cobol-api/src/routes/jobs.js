'use strict'

const { Router } = require('express')
const jobStore = require('../jobStore')

const router = Router()

router.get('/:jobId', (req, res) => {
  const job = jobStore.get(req.params.jobId)
  if (!job) return res.status(404).json({ error: 'Job não encontrado' })
  res.json(job)
})

module.exports = router
