// Service worker de Firebase Cloud Messaging (push en navegador). [G-1]
//
// FCM web exige este archivo en la raíz del sitio: sin un service worker
// registrado, `getToken()` falla y el usuario web nunca registra su token. El
// plugin `firebase_messaging` (web) lo registra automáticamente desde esta ruta.
//
// Los valores de abajo son la **config web pública** de Firebase (las mismas que
// ya se exponen al cliente en `lib/firebase_options.dart`); no son secretos.

importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyDyLmyBjZ2Kz17ROMYtVW5DYJNtVp9t4MI',
  authDomain: 'errr-a6946.firebaseapp.com',
  projectId: 'errr-a6946',
  storageBucket: 'errr-a6946.firebasestorage.app',
  messagingSenderId: '583041509305',
  appId: '1:583041509305:web:cfa700d1d80e723eccf868',
  measurementId: 'G-CE98KJ6RNY',
});

// Habilita el manejo de mensajes en background. El backend envía payloads con
// bloque `notification` (adminBroadcast / pushNotifications), así que el
// navegador muestra la notificación automáticamente. No agregamos un handler
// `onBackgroundMessage` propio para evitar notificaciones duplicadas.
firebase.messaging();
