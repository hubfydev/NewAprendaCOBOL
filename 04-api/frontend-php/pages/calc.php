<?php
/**
 * Calculadora COBOL — Interface PHP
 * Chama a API Node.js que executa o programa GNU COBOL calc.cob
 */

$API_URL = 'http://localhost:3000/api/run/calc';

$result   = null;
$apiError = null;
$formData = ['num1' => '', 'num2' => '', 'operacao' => 'ADD'];

$opMap = [
    'ADD' => ['label' => 'Somar',       'symbol' => '+'],
    'SUB' => ['label' => 'Subtrair',    'symbol' => '−'],
    'MUL' => ['label' => 'Multiplicar', 'symbol' => '×'],
    'DIV' => ['label' => 'Dividir',     'symbol' => '÷'],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $num1 = trim($_POST['num1'] ?? '');
    $num2 = trim($_POST['num2'] ?? '');
    $op   = strtoupper(trim($_POST['operacao'] ?? ''));

    $formData = ['num1' => $num1, 'num2' => $num2, 'operacao' => $op];

    // Validação PHP (primeira camada, antes de chamar a API)
    if (!is_numeric($num1) || !is_numeric($num2)) {
        $apiError = 'Os dois campos devem ser números válidos.';
    } elseif (!array_key_exists($op, $opMap)) {
        $apiError = 'Selecione uma operação válida.';
    } else {
        $payload = json_encode([
            'a'  => (float)$num1,
            'b'  => (float)$num2,
            'op' => $op,
        ]);

        // Chamar a API COBOL
        $ch = curl_init($API_URL);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $raw      = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        curl_close($ch);

        if ($raw === false || $curlErr) {
            $apiError = 'Não foi possível conectar à API COBOL. '
                      . 'Verifique se o servidor está rodando em localhost:3000.';
        } else {
            $data = json_decode($raw, true);
            if ($httpCode === 200) {
                $cobolStatus = $data['status'] ?? 'OK';
                $valor = $data['result'] ?? 0;

                // Trata resultado negativo (COBOL retorna magnitude + status NEGATIVE)
                if ($cobolStatus === 'NEGATIVE') {
                    $valor = -$valor;
                    $cobolStatus = 'OK';
                }

                $result = [
                    'valor'      => $valor,
                    'status'     => $cobolStatus,
                    'durationMs' => $data['_meta']['durationMs'] ?? 0,
                    'a'          => (float)$num1,
                    'b'          => (float)$num2,
                    'op'         => $op,
                ];
            } else {
                $msg = $data['error'] ?? 'Erro desconhecido.';
                if (!empty($data['details'])) {
                    $items = array_column($data['details'], 'message');
                    $msg .= ' (' . implode('; ', $items) . ')';
                }
                $apiError = $msg;
            }
        }
    }
}

function esc($v) { return htmlspecialchars($v, ENT_QUOTES, 'UTF-8'); }
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Calculadora COBOL — PHP</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
      background: #0f1923;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }

    .card {
      background: #1a2535;
      border: 1px solid #2a3a50;
      border-radius: 16px;
      width: 100%;
      max-width: 460px;
      overflow: hidden;
      box-shadow: 0 20px 60px rgba(0,0,0,0.5);
    }

    .card-header {
      background: #0d1f33;
      padding: 24px 28px 20px;
      border-bottom: 1px solid #2a3a50;
    }

    .badge-row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .badge {
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 0.8px;
      text-transform: uppercase;
      padding: 3px 8px;
      border-radius: 4px;
      font-family: monospace;
    }

    .badge-cobol  { background: #1e4d2b; color: #4ade80; border: 1px solid #166534; }
    .badge-php    { background: #312e81; color: #a5b4fc; border: 1px solid #4338ca; }
    .badge-api    { background: #7c2d12; color: #fb923c; border: 1px solid #c2410c; }

    .card-title {
      font-size: 22px;
      font-weight: 700;
      color: #f1f5f9;
    }

    .card-subtitle {
      font-size: 12px;
      color: #64748b;
      margin-top: 4px;
    }

    .card-body {
      padding: 28px;
    }

    .form-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 20px;
    }

    .form-group {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    label {
      font-size: 12px;
      font-weight: 600;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    input[type="number"] {
      background: #0f1923;
      border: 1px solid #2a3a50;
      border-radius: 8px;
      color: #f1f5f9;
      font-size: 18px;
      padding: 12px 14px;
      outline: none;
      transition: border-color 0.15s;
      width: 100%;
      -moz-appearance: textfield;
    }
    input[type="number"]::-webkit-outer-spin-button,
    input[type="number"]::-webkit-inner-spin-button { -webkit-appearance: none; }
    input[type="number"]:focus { border-color: #3b82f6; }

    .op-label {
      font-size: 12px;
      font-weight: 600;
      color: #94a3b8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 10px;
    }

    .op-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      margin-bottom: 24px;
    }

    .op-option { display: none; }

    .op-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      padding: 12px;
      background: #0f1923;
      border: 1px solid #2a3a50;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.15s;
      user-select: none;
    }

    .op-symbol {
      font-size: 20px;
      font-weight: 700;
      color: #64748b;
    }

    .op-name {
      font-size: 13px;
      font-weight: 600;
      color: #94a3b8;
    }

    .op-option:checked + .op-btn {
      background: #1e3a5f;
      border-color: #3b82f6;
    }

    .op-option:checked + .op-btn .op-symbol,
    .op-option:checked + .op-btn .op-name {
      color: #60a5fa;
    }

    .op-btn:hover {
      border-color: #3b82f6;
      background: #1a2f4a;
    }

    .btn-submit {
      width: 100%;
      padding: 14px;
      background: #2563eb;
      color: #fff;
      font-size: 15px;
      font-weight: 700;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      transition: background 0.15s;
      letter-spacing: 0.3px;
    }

    .btn-submit:hover { background: #1d4ed8; }
    .btn-submit:active { background: #1e40af; }

    /* Resultado */
    .result-box {
      margin-top: 20px;
      border-radius: 10px;
      padding: 20px;
      text-align: center;
      animation: fadeIn 0.3s ease;
    }

    @keyframes fadeIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; } }

    .result-box.success {
      background: #0a2318;
      border: 1px solid #166534;
    }

    .result-box.error {
      background: #2d0f0f;
      border: 1px solid #7f1d1d;
    }

    .result-expression {
      font-size: 13px;
      color: #64748b;
      margin-bottom: 6px;
      font-family: monospace;
    }

    .result-value {
      font-size: 36px;
      font-weight: 800;
      color: #4ade80;
      font-family: 'Courier New', monospace;
    }

    .result-value.neg { color: #fb923c; }

    .result-meta {
      font-size: 11px;
      color: #374151;
      margin-top: 10px;
      font-family: monospace;
    }

    .result-meta span { color: #4b5563; }

    .error-msg {
      color: #f87171;
      font-size: 14px;
      font-weight: 500;
    }

    .div0-msg {
      color: #fb923c;
      font-size: 22px;
      font-weight: 700;
    }

    .card-footer {
      padding: 14px 28px;
      background: #0d1f33;
      border-top: 1px solid #1e2d3d;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 11px;
      color: #374151;
      font-family: monospace;
    }

    .flow {
      display: flex;
      align-items: center;
      gap: 4px;
      flex-wrap: wrap;
    }

    .flow-item { color: #4b5563; }
    .flow-sep  { color: #1e3a5f; }
  </style>
</head>
<body>
<div class="card">

  <div class="card-header">
    <div class="badge-row">
      <span class="badge badge-php">PHP</span>
      <span class="badge badge-api">REST API</span>
      <span class="badge badge-cobol">GNU COBOL</span>
    </div>
    <div class="card-title">Calculadora COBOL</div>
    <div class="card-subtitle">Interface PHP → API Node.js → calc.cob</div>
  </div>

  <div class="card-body">
    <form method="POST" action="">

      <div class="form-row">
        <div class="form-group">
          <label for="num1">Número 1</label>
          <input type="number" id="num1" name="num1" step="any"
                 placeholder="0"
                 value="<?= esc($formData['num1']) ?>"
                 required>
        </div>
        <div class="form-group">
          <label for="num2">Número 2</label>
          <input type="number" id="num2" name="num2" step="any"
                 placeholder="0"
                 value="<?= esc($formData['num2']) ?>"
                 required>
        </div>
      </div>

      <div class="op-label">Operação</div>
      <div class="op-grid">
        <?php foreach ($opMap as $code => $info): ?>
        <label>
          <input class="op-option" type="radio" name="operacao" value="<?= $code ?>"
            <?= $formData['operacao'] === $code ? 'checked' : '' ?>>
          <div class="op-btn">
            <span class="op-symbol"><?= $info['symbol'] ?></span>
            <span class="op-name"><?= $info['label'] ?></span>
          </div>
        </label>
        <?php endforeach; ?>
      </div>

      <button type="submit" class="btn-submit">Executar Cálculo</button>

    </form>

    <?php if ($apiError): ?>
    <div class="result-box error">
      <div class="error-msg"><?= esc($apiError) ?></div>
    </div>
    <?php endif; ?>

    <?php if ($result): ?>
    <div class="result-box success">
      <?php
        $sym = $opMap[$result['op']]['symbol'];
        $expr = number_format($result['a'], 2, '.', '') . ' '
              . $sym . ' '
              . number_format($result['b'], 2, '.', '');
      ?>

      <?php if ($result['status'] === 'DIV0'): ?>
        <div class="result-expression"><?= esc($expr) ?></div>
        <div class="div0-msg">Divisão por zero</div>

      <?php elseif ($result['status'] === 'ERR'): ?>
        <div class="error-msg">Operação inválida retornada pelo COBOL</div>

      <?php else: ?>
        <div class="result-expression"><?= esc($expr) ?> =</div>
        <div class="result-value <?= $result['valor'] < 0 ? 'neg' : '' ?>">
          <?= number_format($result['valor'], 2, '.', ',') ?>
        </div>
        <?php if ($result['status'] === 'NEGATIVE' || $result['valor'] < 0): ?>
          <div style="font-size:11px;color:#fb923c;margin-top:4px;">resultado negativo</div>
        <?php endif; ?>
      <?php endif; ?>

      <div class="result-meta">
        COBOL exit=0 &nbsp;|&nbsp;
        <span>exec <?= (int)$result['durationMs'] ?>ms</span> &nbsp;|&nbsp;
        status: <?= esc($result['status']) ?>
      </div>
    </div>
    <?php endif; ?>

  </div>

  <div class="card-footer">
    <div class="flow">
      <span class="flow-item">PHP form</span>
      <span class="flow-sep"> → </span>
      <span class="flow-item">POST /api/run/calc</span>
      <span class="flow-sep"> → </span>
      <span class="flow-item">calc.cob</span>
      <span class="flow-sep"> → </span>
      <span class="flow-item">stdout</span>
      <span class="flow-sep"> → </span>
      <span class="flow-item">JSON</span>
    </div>
    <span style="color:#1e3a5f">localhost:8080/calc</span>
  </div>

</div>
</body>
</html>
