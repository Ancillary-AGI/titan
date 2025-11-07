# Web API Quick Reference

Quick reference for using Titan Browser's implemented Web APIs.

---

## 📋 Clipboard API

```javascript
// Copy text
await navigator.clipboard.writeText('Hello World');

// Paste text
const text = await navigator.clipboard.readText();
```

**Requirements**: HTTPS or localhost  
**Permission**: No  
**Platform**: All

---

## 📤 Web Share API

```javascript
await navigator.share({
  title: 'My Title',
  text: 'Check this out!',
  url: 'https://example.com'
});
```

**Requirements**: User gesture (click/tap)  
**Permission**: No  
**Platform**: All

---

## 📍 Geolocation API

```javascript
// Get current position
navigator.geolocation.getCurrentPosition(
  (pos) => console.log(pos.coords.latitude, pos.coords.longitude),
  (err) => console.error(err),
  { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
);

// Watch position
const watchId = navigator.geolocation.watchPosition(
  (pos) => console.log('Update:', pos.coords),
  (err) => console.error(err)
);

// Stop watching
navigator.geolocation.clearWatch(watchId);
```

**Requirements**: HTTPS or localhost  
**Permission**: Yes (location)  
**Platform**: All

---

## 🔔 Notifications API

```javascript
// Request permission
const permission = await Notification.requestPermission();

// Show notification
if (permission === 'granted') {
  const notif = new Notification('Title', {
    body: 'Message body',
    icon: 'https://example.com/icon.png',
    badge: 'https://example.com/badge.png',
    tag: 'unique-id',
    requireInteraction: false
  });
  
  notif.onclick = () => console.log('Clicked!');
  notif.onclose = () => console.log('Closed!');
}
```

**Requirements**: HTTPS or localhost  
**Permission**: Yes (notifications)  
**Platform**: All

---

## 📳 Vibration API

```javascript
// Single vibration (200ms)
navigator.vibrate(200);

// Pattern: vibrate 100ms, pause 50ms, vibrate 200ms
navigator.vibrate([100, 50, 200]);

// Cancel vibration
navigator.vibrate(0);
```

**Requirements**: None  
**Permission**: No  
**Platform**: Mobile (gracefully ignored on desktop)

---

## 🛠️ Console API

```javascript
console.log('Debug message');
console.info('Info message');
console.warn('Warning message');
console.error('Error message');
console.table([{a: 1, b: 2}, {a: 3, b: 4}]);
console.group('Group');
console.log('Inside group');
console.groupEnd();
```

**Requirements**: None  
**Permission**: No  
**Platform**: All  
**Note**: All messages forwarded to Flutter DevTools

---

## 💾 localStorage (Built-in)

```javascript
// Store data
localStorage.setItem('key', 'value');
localStorage.setItem('user', JSON.stringify({name: 'John'}));

// Retrieve data
const value = localStorage.getItem('key');
const user = JSON.parse(localStorage.getItem('user'));

// Remove data
localStorage.removeItem('key');

// Clear all
localStorage.clear();

// Get number of items
const count = localStorage.length;

// Get key by index
const key = localStorage.key(0);
```

---

## 🌐 Fetch API (Built-in)

```javascript
// GET request
const response = await fetch('https://api.example.com/data');
const data = await response.json();

// POST request
const response = await fetch('https://api.example.com/data', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'John' })
});

// With error handling
try {
  const response = await fetch('https://api.example.com/data');
  if (!response.ok) throw new Error('HTTP error ' + response.status);
  const data = await response.json();
} catch (error) {
  console.error('Fetch error:', error);
}
```

---

## 🔌 WebSocket (Built-in)

```javascript
const ws = new WebSocket('wss://echo.websocket.org');

ws.onopen = () => {
  console.log('Connected');
  ws.send('Hello Server!');
};

ws.onmessage = (event) => {
  console.log('Received:', event.data);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected');
};

// Close connection
ws.close();
```

---

## 🗄️ IndexedDB (Built-in)

```javascript
// Open database
const request = indexedDB.open('myDatabase', 1);

request.onupgradeneeded = (event) => {
  const db = event.target.result;
  const store = db.createObjectStore('users', { keyPath: 'id' });
  store.createIndex('name', 'name', { unique: false });
};

request.onsuccess = (event) => {
  const db = event.target.result;
  
  // Add data
  const transaction = db.transaction(['users'], 'readwrite');
  const store = transaction.objectStore('users');
  store.add({ id: 1, name: 'John', email: 'john@example.com' });
  
  // Get data
  const getRequest = store.get(1);
  getRequest.onsuccess = () => {
    console.log('User:', getRequest.result);
  };
};
```

---

## 👷 Service Workers (Built-in)

```javascript
// Register service worker
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js')
    .then(reg => console.log('SW registered:', reg))
    .catch(err => console.error('SW registration failed:', err));
}

// In sw.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('v1').then(cache => {
      return cache.addAll(['/index.html', '/styles.css', '/app.js']);
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then(response => {
      return response || fetch(event.request);
    })
  );
});
```

---

## 🎨 Canvas API (Built-in)

```javascript
const canvas = document.getElementById('myCanvas');
const ctx = canvas.getContext('2d');

// Draw rectangle
ctx.fillStyle = 'blue';
ctx.fillRect(10, 10, 100, 100);

// Draw circle
ctx.beginPath();
ctx.arc(75, 75, 50, 0, Math.PI * 2);
ctx.fillStyle = 'red';
ctx.fill();

// Draw text
ctx.font = '30px Arial';
ctx.fillStyle = 'black';
ctx.fillText('Hello', 10, 50);

// Draw image
const img = new Image();
img.onload = () => ctx.drawImage(img, 0, 0);
img.src = 'image.png';
```

---

## 🎵 Web Audio API (Built-in)

```javascript
const audioContext = new AudioContext();

// Play oscillator
const oscillator = audioContext.createOscillator();
oscillator.type = 'sine';
oscillator.frequency.value = 440; // A4 note
oscillator.connect(audioContext.destination);
oscillator.start();
oscillator.stop(audioContext.currentTime + 1); // Stop after 1 second

// Play audio file
fetch('audio.mp3')
  .then(response => response.arrayBuffer())
  .then(buffer => audioContext.decodeAudioData(buffer))
  .then(audioBuffer => {
    const source = audioContext.createBufferSource();
    source.buffer = audioBuffer;
    source.connect(audioContext.destination);
    source.start();
  });
```

---

## 📹 getUserMedia (Built-in)

```javascript
// Get camera and microphone
navigator.mediaDevices.getUserMedia({ video: true, audio: true })
  .then(stream => {
    const video = document.getElementById('video');
    video.srcObject = stream;
    video.play();
  })
  .catch(err => console.error('Media error:', err));

// Get screen capture
navigator.mediaDevices.getDisplayMedia({ video: true })
  .then(stream => {
    const video = document.getElementById('screen');
    video.srcObject = stream;
    video.play();
  });

// Stop stream
stream.getTracks().forEach(track => track.stop());
```

---

## 📱 Fullscreen API (Built-in)

```javascript
const elem = document.getElementById('myElement');

// Enter fullscreen
elem.requestFullscreen()
  .then(() => console.log('Entered fullscreen'))
  .catch(err => console.error('Fullscreen error:', err));

// Exit fullscreen
document.exitFullscreen();

// Check if fullscreen
if (document.fullscreenElement) {
  console.log('In fullscreen mode');
}

// Listen for fullscreen changes
document.addEventListener('fullscreenchange', () => {
  if (document.fullscreenElement) {
    console.log('Entered fullscreen');
  } else {
    console.log('Exited fullscreen');
  }
});
```

---

## 🔍 Intersection Observer (Built-in)

```javascript
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      console.log('Element is visible:', entry.target);
      // Lazy load image
      entry.target.src = entry.target.dataset.src;
      observer.unobserve(entry.target);
    }
  });
}, {
  root: null,
  rootMargin: '0px',
  threshold: 0.1
});

// Observe elements
document.querySelectorAll('img[data-src]').forEach(img => {
  observer.observe(img);
});
```

---

## 📏 Resize Observer (Built-in)

```javascript
const observer = new ResizeObserver(entries => {
  entries.forEach(entry => {
    console.log('Size changed:', entry.contentRect.width, entry.contentRect.height);
  });
});

observer.observe(document.getElementById('myElement'));
```

---

## 🔬 Mutation Observer (Built-in)

```javascript
const observer = new MutationObserver(mutations => {
  mutations.forEach(mutation => {
    console.log('DOM changed:', mutation.type);
    if (mutation.type === 'childList') {
      console.log('Children changed:', mutation.addedNodes, mutation.removedNodes);
    }
  });
});

observer.observe(document.body, {
  childList: true,
  subtree: true,
  attributes: true,
  characterData: true
});
```

---

## ⚡ Performance API (Built-in)

```javascript
// Mark start
performance.mark('start');

// Do some work
await fetch('https://api.example.com/data');

// Mark end
performance.mark('end');

// Measure
performance.measure('fetch-time', 'start', 'end');

// Get measurements
const measures = performance.getEntriesByType('measure');
console.log('Fetch took:', measures[0].duration, 'ms');

// Navigation timing
const navTiming = performance.getEntriesByType('navigation')[0];
console.log('Page load time:', navTiming.loadEventEnd - navTiming.fetchStart, 'ms');
```

---

## 🔐 Crypto API (Built-in)

```javascript
// Generate random values
const array = new Uint32Array(10);
crypto.getRandomValues(array);

// Generate UUID
const uuid = crypto.randomUUID();

// Hash data (requires SubtleCrypto)
const data = new TextEncoder().encode('Hello World');
const hashBuffer = await crypto.subtle.digest('SHA-256', data);
const hashArray = Array.from(new Uint8Array(hashBuffer));
const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
```

---

## 📦 Error Handling Best Practices

```javascript
// Async/await with try-catch
async function fetchData() {
  try {
    const response = await fetch('https://api.example.com/data');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Fetch failed:', error);
    // Show user-friendly error
    showErrorMessage('Failed to load data. Please try again.');
    return null;
  }
}

// Promise with .catch()
fetch('https://api.example.com/data')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));

// Permission handling
async function requestNotificationPermission() {
  try {
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      new Notification('Success!', { body: 'Notifications enabled' });
    } else if (permission === 'denied') {
      console.log('Notification permission denied');
    }
  } catch (error) {
    console.error('Notification error:', error);
  }
}
```

---

## 🎯 Common Patterns

### Debouncing
```javascript
function debounce(func, wait) {
  let timeout;
  return function(...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

// Usage
const debouncedSearch = debounce((query) => {
  fetch(`/search?q=${query}`).then(/* ... */);
}, 300);

input.addEventListener('input', (e) => debouncedSearch(e.target.value));
```

### Throttling
```javascript
function throttle(func, limit) {
  let inThrottle;
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

// Usage
const throttledScroll = throttle(() => {
  console.log('Scroll position:', window.scrollY);
}, 100);

window.addEventListener('scroll', throttledScroll);
```

### Retry Logic
```javascript
async function fetchWithRetry(url, options = {}, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response;
      throw new Error(`HTTP ${response.status}`);
    } catch (error) {
      if (i === retries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
    }
  }
}
```

---

## 📚 Resources

- [MDN Web APIs](https://developer.mozilla.org/en-US/docs/Web/API)
- [Web API Testing Guide](./WEB_API_TESTING.md)
- [Implementation Status](./WEB_API_IMPLEMENTATION_STATUS.md)
- [Titan Browser README](../README.md)
