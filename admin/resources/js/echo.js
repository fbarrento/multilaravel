import Echo from 'laravel-echo';

import Pusher from 'pusher-js';
window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST ?? 'localhost',
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 6002,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 6002,
    forceTLS: false, // Disable TLS for local development
    enabledTransports: ['ws', 'wss'],
    enableLogging: true, // Enable logging for debugging
});
