<?php
/**
 * Copyright 2026 Emilian Scibisz
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// Cloudflare Turnstile - token verifier
// Config: edit TURNSTILE_SECRET below or set env var TURNSTILE_SECRET
define('TURNSTILE_SECRET', getenv('TURNSTILE_SECRET') ?: '1x0000000000000000000000000000000AA');

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$token = trim($_POST['token'] ?? '');
if (empty($token)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing token']);
    exit;
}

$ch = curl_init('https://challenges.cloudflare.com/turnstile/v0/siteverify');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => http_build_query([
        'secret'   => TURNSTILE_SECRET,
        'response' => $token,
        'remoteip' => $_SERVER['REMOTE_ADDR'] ?? '',
    ]),
    CURLOPT_TIMEOUT        => 10,
]);

$result  = curl_exec($ch);
$curlErr = curl_error($ch);
curl_close($ch);

if ($curlErr || $result === false) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Verification service unavailable']);
    exit;
}

$data = json_decode($result, true);

if (!empty($data['success'])) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(403);
    echo json_encode(['success' => false, 'error' => $data['error-codes'][0] ?? 'Verification failed']);
}
