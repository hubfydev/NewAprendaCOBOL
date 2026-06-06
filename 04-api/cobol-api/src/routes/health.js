'use strict'

const { Router } = require('express')
const processManager = require('../processManager')
const { sessionCount } = require('../session')

const startTime = Date.now()
const router = Router()

router.get('/', (req, res) => {
  const stats = processManager.stats()
  res.json({
    status: 'ok',
    uptimeSeconds: Math.floor((Date.now() - startTime) / 1000),
    processes: {
      active: stats.globalActive,
      limit:  stats.globalMax
    },
    sessions: {
      active: sessionCount()
    },
    programs: stats.programs
  })
})

module.exports = router
