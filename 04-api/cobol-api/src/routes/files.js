'use strict'

const { Router } = require('express')
const multer = require('multer')
const programs = require('../../programs.json')
const { runProgram } = require('../runner')
const jobStore = require('../jobStore')

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }
})

const router = Router()

router.post('/:program', upload.single('file'), (req, res) => {
  const { program } = req.params
  const config = programs[program]

  if (!config) {
    return res.status(404).json({ error: 'Programa não encontrado', program })
  }
  if (!req.file) {
    return res.status(400).json({ error: 'Nenhum arquivo enviado. Use o campo "file" no form-data.' })
  }

  const jobId = jobStore.create(program)
  jobStore.update(jobId, { status: 'running' })

  const rawStdin = req.file.buffer.toString('utf8')

  runProgram(program, config, {}, { rawStdin })
    .then(result => {
      jobStore.update(jobId, { status: 'done', result })
    })
    .catch(err => {
      jobStore.update(jobId, {
        status: 'error',
        error: err.message,
        code: err.code,
        ...(err.stderr !== undefined && { stderr: err.stderr })
      })
    })

  res.status(202).json({
    jobId,
    status: 'running',
    poll: `/api/job/${jobId}`
  })
})

module.exports = router
