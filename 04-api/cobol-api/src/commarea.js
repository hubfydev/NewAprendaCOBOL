'use strict'

/**
 * Converte definições PICTURE do COBOL para metadados de campo.
 * Suporta: X(n), 9(n), 9(n)V9(m), 9(n)Vmm, S9(n)
 */
function parsePic(pic) {
  pic = pic.trim().toUpperCase()

  if (pic.startsWith('X')) {
    const m = pic.match(/X\((\d+)\)/)
    return { type: 'alpha', length: m ? +m[1] : 1 }
  }

  const signed = pic.startsWith('S')
  const raw = signed ? pic.slice(1) : pic

  const vIdx = raw.indexOf('V')
  const intPart = vIdx === -1 ? raw : raw.slice(0, vIdx)
  const decPart = vIdx === -1 ? '' : raw.slice(vIdx + 1)

  const intDigits = _countDigits(intPart)
  const decDigits = decPart ? _countDigits(decPart) : 0

  return { type: 'numeric', signed, intDigits, decDigits, length: intDigits + decDigits }
}

function _countDigits(str) {
  const m = str.match(/9\((\d+)\)/)
  if (m) return +m[1]
  return (str.match(/9/g) || []).length
}

/**
 * Converte objeto JSON para registro fixo (COMMAREA) pronto para stdin do COBOL.
 * Cada campo é formatado conforme seu PICTURE clause.
 */
function toCommarea(jsonData, fields) {
  if (!fields || fields.length === 0) return ''

  return fields.map(field => {
    const pic = parsePic(field.pic)
    const value = jsonData[field.name]

    if (pic.type === 'alpha') {
      return String(value ?? '').padEnd(pic.length, ' ').slice(0, pic.length)
    }

    const num = parseFloat(value ?? 0)
    const abs = Math.abs(num)
    const intVal = Math.floor(abs)
    const decVal = pic.decDigits > 0
      ? Math.round((abs - intVal) * (10 ** pic.decDigits))
      : 0

    const intStr = String(intVal).padStart(pic.intDigits, '0').slice(-pic.intDigits)
    const decStr = pic.decDigits > 0
      ? String(decVal).padStart(pic.decDigits, '0').slice(-pic.decDigits)
      : ''

    return intStr + decStr
  }).join('')
}

/**
 * Converte registro fixo (stdout do COBOL) de volta para objeto JSON.
 * Cada campo é extraído pela posição e tamanho calculados via PICTURE.
 */
function fromCommarea(raw, fields) {
  const result = {}
  let pos = 0

  for (const field of fields) {
    const pic = parsePic(field.pic)
    const chunk = raw.slice(pos, pos + pic.length)
    pos += pic.length

    if (pic.type === 'alpha') {
      result[field.name] = chunk.trimEnd()
      continue
    }

    if (pic.decDigits === 0) {
      result[field.name] = parseInt(chunk, 10) || 0
    } else {
      const intStr = chunk.slice(0, pic.intDigits)
      const decStr = chunk.slice(pic.intDigits)
      result[field.name] = parseFloat(`${parseInt(intStr, 10) || 0}.${decStr}`) || 0
    }
  }

  return result
}

function commareaLength(fields) {
  return (fields || []).reduce((sum, f) => sum + parsePic(f.pic).length, 0)
}

module.exports = { parsePic, toCommarea, fromCommarea, commareaLength }
