<?php
/**
 * Router — COBOL Web Frontend (PHP)
 * Inicie com: php -S localhost:8080 router.php
 *
 * Rotas disponíveis:
 *   GET  /           → home (lista de programas)
 *   GET  /calc       → Calculadora COBOL
 *   (adicionar novas rotas aqui conforme novos programas)
 */

$routes = [
    '/'     => __DIR__ . '/pages/home.php',
    '/calc' => __DIR__ . '/pages/calc.php',
];

$path = rtrim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
if ($path === '') $path = '/';

// Serve arquivos estáticos existentes (css, js, imagens) diretamente
if ($path !== '/' && file_exists(__DIR__ . $path)) {
    return false;
}

$page = $routes[$path] ?? null;

if ($page && file_exists($page)) {
    require $page;
} else {
    http_response_code(404);
    require __DIR__ . '/pages/404.php';
}
