/**
 * Sirve las builds web del modo emuladores: pasajero y panel en :5050,
 * chófer en :5051. Rutas desconocidas → index.html (la app enruta).
 * Comprime como un hosting (brotli o gzip según Accept-Encoding) los
 * tipos de texto y wasm; las imágenes y vídeos van tal cual.
 */
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const COMPRESSIBLE = /\.(html|js|mjs|json|css|wasm|svg|otf|ttf)$/;
const cache = new Map();

const ROOT = path.join(__dirname, '../../build');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.wasm': 'application/wasm',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.ico': 'image/x-icon', '.mp4': 'video/mp4', '.webp': 'image/webp' };

function serve(dir, port) {
  http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    let file = path.join(dir, path.normalize(url).replace(/^(\.\.[/\\])+/, ''));
    if (!file.startsWith(dir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(dir, 'index.html');
    const type = TYPES[path.extname(file)] || 'application/octet-stream';
    const accept = String(req.headers['accept-encoding'] || '');
    const enc = !COMPRESSIBLE.test(file) ? null : accept.includes('br') ? 'br' : accept.includes('gzip') ? 'gzip' : null;
    if (!enc) {
      res.writeHead(200, { 'Content-Type': type });
      fs.createReadStream(file).pipe(res);
      return;
    }
    const key = `${enc}:${file}:${fs.statSync(file).mtimeMs}`;
    if (!cache.has(key)) {
      const buf = fs.readFileSync(file);
      cache.set(key, enc === 'br' ? zlib.brotliCompressSync(buf) : zlib.gzipSync(buf, { level: 9 }));
    }
    res.writeHead(200, { 'Content-Type': type, 'Content-Encoding': enc, Vary: 'Accept-Encoding' });
    res.end(cache.get(key));
  }).listen(port, () => console.log(`Sirviendo ${path.basename(dir)} en http://localhost:${port}`));
}

serve(path.join(ROOT, 'web-emu'), 5050);
serve(path.join(ROOT, 'web-emu-driver'), 5051);
