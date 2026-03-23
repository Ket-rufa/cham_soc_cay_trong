<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'], // Cho phép mọi phương thức (GET, POST...)

    'allowed_origins' => ['*'], // <--- QUAN TRỌNG NHẤT: Cho phép mọi nguồn (Web, Mobile...)

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'], // Cho phép mọi Header

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];