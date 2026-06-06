<?php
/**
 * Home — lista de programas COBOL disponíveis na interface web
 */
$API_URL = 'http://localhost:3000/api/programs';

$programs = [];
$apiOk = false;

$ch = curl_init($API_URL);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 3,
]);
$raw = curl_exec($ch);
curl_close($ch);

if ($raw) {
    $data     = json_decode($raw, true);
    $programs = $data['programs'] ?? [];
    $apiOk    = true;
}

$programMeta = [
    'calc' => [
        'icon'        => '×',
        'title'       => 'Calculadora',
        'description' => 'Soma, subtrai, multiplica e divide dois números.',
        'route'       => '/calc',
    ],
    // Adicione novos programas aqui conforme forem criados
];
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>COBOL Web — Programas disponíveis</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: #0f1923;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 32px 24px;
    }

    .shell {
      width: 100%;
      max-width: 560px;
    }

    .header {
      text-align: center;
      margin-bottom: 32px;
    }

    .logo {
      font-size: 13px;
      font-family: monospace;
      font-weight: 700;
      letter-spacing: 2px;
      color: #4ade80;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .title {
      font-size: 26px;
      font-weight: 800;
      color: #f1f5f9;
    }

    .subtitle {
      font-size: 13px;
      color: #475569;
      margin-top: 6px;
    }

    .api-status {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      font-family: monospace;
      padding: 4px 10px;
      border-radius: 6px;
      margin-top: 12px;
    }

    .api-status.ok  { background: #0a2318; color: #4ade80; border: 1px solid #166534; }
    .api-status.err { background: #2d0f0f; color: #f87171; border: 1px solid #7f1d1d; }

    .dot { width: 7px; height: 7px; border-radius: 50%; }
    .dot.green { background: #4ade80; }
    .dot.red   { background: #f87171; }

    .grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 12px;
    }

    .card {
      background: #1a2535;
      border: 1px solid #2a3a50;
      border-radius: 12px;
      padding: 20px 22px;
      display: flex;
      align-items: center;
      gap: 18px;
      text-decoration: none;
      transition: border-color 0.15s, background 0.15s;
    }

    .card:hover {
      border-color: #3b82f6;
      background: #1e2f47;
    }

    .card-icon {
      width: 48px;
      height: 48px;
      background: #0d1f33;
      border: 1px solid #2a3a50;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
      font-weight: 800;
      color: #3b82f6;
      flex-shrink: 0;
    }

    .card-body { flex: 1; min-width: 0; }

    .card-title {
      font-size: 15px;
      font-weight: 700;
      color: #f1f5f9;
      margin-bottom: 3px;
    }

    .card-desc {
      font-size: 12px;
      color: #64748b;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .card-badge {
      font-size: 10px;
      font-family: monospace;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 4px;
      background: #1e3a5f;
      color: #60a5fa;
      border: 1px solid #1d4ed8;
      white-space: nowrap;
    }

    .card-badge.interactive {
      background: #1e3d2b;
      color: #4ade80;
      border-color: #166534;
    }

    .card-arrow {
      font-size: 18px;
      color: #2a3a50;
      transition: color 0.15s;
    }

    .card:hover .card-arrow { color: #3b82f6; }

    .empty {
      text-align: center;
      padding: 40px;
      color: #374151;
      font-size: 13px;
      border: 1px dashed #1e2d3d;
      border-radius: 12px;
    }

    footer {
      margin-top: 28px;
      text-align: center;
      font-size: 11px;
      color: #1e2d3d;
      font-family: monospace;
    }
  </style>
</head>
<body>
<div class="shell">

  <div class="header">
    <div class="logo">GNU COBOL</div>
    <div class="title">COBOL Web Programs</div>
    <div class="subtitle">Escolha um programa para executar</div>
    <div class="api-status <?= $apiOk ? 'ok' : 'err' ?>">
      <span class="dot <?= $apiOk ? 'green' : 'red' ?>"></span>
      API <?= $apiOk ? 'online' : 'offline' ?> — localhost:3000
    </div>
  </div>

  <div class="grid">
    <?php if (empty($programs)): ?>
    <div class="empty">
      <?= $apiOk
          ? 'Nenhum programa registrado na API ainda.'
          : 'Não foi possível conectar à API em localhost:3000.' ?>
    </div>
    <?php else: ?>
    <?php foreach ($programs as $prog):
      $meta  = $programMeta[$prog['name']] ?? null;
      $route = $meta['route'] ?? '/' . $prog['name'];
      $icon  = $meta['icon']  ?? '▶';
      $title = $meta['title'] ?? ucfirst($prog['name']);
      $desc  = $meta['description'] ?? ($prog['description'] ?? '');
      $isInteractive = $prog['type'] === 'interactive';
    ?>
    <a class="card" href="<?= htmlspecialchars($route) ?>">
      <div class="card-icon"><?= $icon ?></div>
      <div class="card-body">
        <div class="card-title"><?= htmlspecialchars($title) ?></div>
        <div class="card-desc"><?= htmlspecialchars($desc) ?></div>
      </div>
      <span class="card-badge <?= $isInteractive ? 'interactive' : '' ?>">
        <?= $isInteractive ? 'interativo' : 'one-shot' ?>
      </span>
      <span class="card-arrow">›</span>
    </a>
    <?php endforeach; ?>
    <?php endif; ?>
  </div>

  <footer>PHP form → POST /api/run/:program → GNU COBOL → JSON</footer>
</div>
</body>
</html>
