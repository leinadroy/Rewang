<?php
// Salin file ini menjadi config.php lalu isi sesuai server.
// config.php TIDAK ikut ke git dan TIDAK ikut ter-copy saat build.
return [
    'app' => [
        'debug'    => false,          // true hanya di lokal
        'timezone' => 'Asia/Jakarta',
    ],
    'db' => [
        'host'    => 'localhost',
        'port'    => 3306,
        'name'    => 'rewang',
        'user'    => 'root',
        'pass'    => '',
        'charset' => 'utf8mb4',
    ],
];
