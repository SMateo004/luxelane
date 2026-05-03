importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

// Replace with your Firebase config values (same as firebase_config.dart)
firebase.initializeApp({
  apiKey: "AIzaSyBkEwrqa7umZjRv91CR3YKaHLAkdBjNvoM",
  authDomain: "luxelane-4e7ae.firebaseapp.com",
  projectId: "luxelane-4e7ae",
  storageBucket: "luxelane-4e7ae.firebasestorage.app",
  messagingSenderId: "51157842817",
  appId: "1:51157842817:web:ab1b8de63c50c095ee4680",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (title) {
    self.registration.showNotification(title, {
      body: body ?? '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
    });
  }
});
