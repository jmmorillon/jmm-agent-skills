<?php
/**
 * Excerpt of a WordPress plugin that exposes REST routes and consumes an upstream API.
 */

add_action('rest_api_init', function () {
    // Public webhook — Meta verification handshake (GET) + inbound events (POST)
    register_rest_route('whatsapp/v1', '/webhook', [
        [
            'methods'             => 'GET',
            'callback'            => 'wa_webhook_verify',
            'permission_callback' => '__return_true',
        ],
        [
            'methods'             => 'POST',
            'callback'            => 'wa_webhook_receive',
            'permission_callback' => '__return_true',
        ],
    ]);

    // Authenticated self-update endpoint (fail-closed via x-api-key header)
    register_rest_route('wa-client/v1', '/update-plugin', [
        'methods'             => 'POST',
        'callback'            => 'wa_client_update_plugin',
        'permission_callback' => '__return_true',
    ]);
});

function wa_webhook_verify($request) {
    $mode      = $request->get_param('hub.mode');
    $token     = $request->get_param('hub.verify_token');
    $challenge = $request->get_param('hub.challenge');
    if ($mode === 'subscribe' && $token === WA_VERIFY_TOKEN) {
        return $challenge;
    }
    return new WP_Error('forbidden', 'bad token', ['status' => 403]);
}

/**
 * Outbound call to the PulseMsg / Meta WhatsApp Cloud API to send a template message.
 */
function wa_send_template($to, $template) {
    $response = wp_remote_post('https://pulsemsg.com/' . WA_PHONE_ID . '/messages', [
        'headers' => [
            'Authorization' => 'Bearer ' . WA_ACCESS_TOKEN,
            'Content-Type'  => 'application/json',
        ],
        'body' => wp_json_encode([
            'messaging_product' => 'whatsapp',
            'to'                => $to,
            'type'              => 'template',
            'template'          => ['name' => $template, 'language' => ['code' => 'fr']],
        ]),
    ]);
    return $response;
}
