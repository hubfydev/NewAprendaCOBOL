'use strict'

/**
 * Valida os campos de entrada de um programa COBOL antes de chamar o executável.
 * Usa as definições de campo do programs.json (pic, enum).
 *
 * @param {Array}  fields - campos definidos em programs.json (input[])
 * @param {object} body   - payload JSON recebido pelo cliente
 * @returns {Array} lista de erros (vazia = válido)
 */
function validateInput(fields, body) {
  if (!fields || fields.length === 0) return []

  const errors = []

  for (const field of fields) {
    const value = body[field.name]

    // Campo obrigatório
    if (value === undefined || value === null || value === '') {
      errors.push({ field: field.name, message: `Campo obrigatório` })
      continue
    }

    const pic = field.pic.trim().toUpperCase()

    // Campos numéricos (PIC 9...)
    if (pic.startsWith('9') || pic.startsWith('S9')) {
      const num = parseFloat(value)
      if (isNaN(num) || !isFinite(num)) {
        errors.push({ field: field.name, message: `Deve ser um número válido` })
        continue
      }
      if (!pic.startsWith('S9') && num < 0) {
        errors.push({ field: field.name, message: `Deve ser um número não-negativo (campo não possui sinal)` })
      }
    }

    // Campos com enum (X com valores permitidos)
    if (field.enum) {
      const normalized = String(value).trim().toUpperCase()
      const allowed = field.enum.map(v => v.toUpperCase())
      if (!allowed.includes(normalized)) {
        errors.push({
          field: field.name,
          message: `Valor "${value}" inválido. Permitidos: ${field.enum.join(', ')}`
        })
      }
    }
  }

  return errors
}

module.exports = { validateInput }
