'use strict'

const { randomUUID } = require('crypto')

const store = new Map()

function create(programName) {
  const jobId = randomUUID()
  store.set(jobId, {
    jobId,
    programName,
    status: 'queued',
    createdAt: new Date().toISOString()
  })
  return jobId
}

function update(jobId, patch) {
  const job = store.get(jobId)
  if (job) {
    store.set(jobId, { ...job, ...patch, updatedAt: new Date().toISOString() })
  }
}

function get(jobId) {
  return store.get(jobId) || null
}

module.exports = { create, update, get }
