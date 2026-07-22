<?php
// Newly added route to be reflected in the bruno collection:
register_rest_route('whatsapp/v1', '/contacts/(?P<id>\d+)', [
    'methods'             => 'DELETE',
    'callback'            => 'wa_delete_contact_rest',
    'permission_callback' => 'wa_rest_require_api_key', // expects x-api-key header
]);
