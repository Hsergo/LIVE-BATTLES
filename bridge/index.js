'use strict';

const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const { WebSocketServer, WebSocket } = require('ws');
const { normalizeCommand, giftPoints, shouldCountGift, sanitizedUsername } = require('./src/rules');

const HOST = '127.0.0.1';
const PORT = 8765;
const config = JSON.parse(fs.readFileSync(path.join(__dirname, 'config', 'gifts.json'), 'utf8'));
const commandTimes = new Map();
const seenIds = new Map();

let connector = null;
let requestedUser = '';
let retryTimer = null;
let status = 'SIMULATION';

function broadcast(payload) {
  const data = JSON.stringify(payload);
  for (const client of wss.clients) {
    if (client.readyState === WebSocket.OPEN) client.send(data);
  }
}
function message(text) {
  status = text;
  console.log('[LIVE BATTLES]', text);
  broadcast({ type: 'status', message: text });
}
function event(payload, unique = null) {
  const now = Date.now();
  for (const [id, timestamp] of seenIds) {
    if (now - timestamp > 300000) seenIds.delete(id);
  }
  if (unique && seenIds.has(unique)) return;
  if (unique) seenIds.set(unique, now);
  broadcast({ type: 'event', timestamp: new Date().toISOString(), ...payload });
}
function chat(username, content, id = null) {
  if (!normalizeCommand(content)) return;
  const who = sanitizedUsername(username);
  const now = Date.now();
  const last = commandTimes.get(who) ?? 0;
  if (now - last < 700) return;
  commandTimes.set(who, now);
  event({ event: 'chat', user: who, text: String(content).trim().toLowerCase() }, id);
}
function gift(username, title, count, id = null) {
  const points = Math.min(1000, giftPoints(title, config, count));
  event({
    event: 'gift',
    user: sanitizedUsername(username),
    gift_name: String(title).slice(0, 64),
    count: Number(count) || 1,
    points
  }, id);
}
function simulate(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) return false;
  const user = sanitizedUsername(input.username || 'Demo');
  switch (String(input.type ?? '')) {
    case 'comment':
      chat(user, input.text || '');
      return true;
    case 'gift':
      gift(user, input.gift_name || 'Rose', input.count || 1);
      return true;
    case 'like':
      event({ event: 'like', user, count: Math.min(10000, Math.max(1, Number(input.count) || 1)) });
      return true;
    case 'follow':
      event({ event: 'follow', user });
      return true;
    default:
      return false;
  }
}
async function stopConnection() {
  requestedUser = '';
  if (retryTimer) clearTimeout(retryTimer);
  retryTimer = null;
  const old = connector;
  connector = null;
  if (old) {
    try { await old.disconnect(); } catch (e) { console.error(e.message); }
  }
  message('SIMULATION');
}
function planRetry() {
  if (!requestedUser || retryTimer) return;
  retryTimer = setTimeout(() => {
    retryTimer = null;
    connectTikTok(requestedUser).catch(e => message('Erreur TikTok: ' + e.message));
  }, 15000);
}
async function connectTikTok(userValue) {
  const name = String(userValue ?? '').trim().replace(/^@/, '').replace(/[^A-Za-z0-9_.]/g, '').slice(0, 32);
  if (!name) { message('Identifiant TikTok incorrect'); return; }
  requestedUser = name;

  if (connector) {
    try { await connector.disconnect(); } catch (_) {}
    connector = null;
  }
  message('Connexion TikTok : @' + name);

  let TikTokLiveConnection;
  try {
    ({ TikTokLiveConnection } = await import('tiktok-live-connector'));
  } catch (e) {
    message('Module TikTok indisponible');
    console.error(e.message);
    return;
  }

  const active = new TikTokLiveConnection(name);
  connector = active;

  active.on('chat', e => chat(e.user?.uniqueId || e.uniqueId || e.user?.nickname || e.nickname, e.comment, (e.common?.msgId || e.msgId) ? String(e.common?.msgId || e.msgId) : null));
  active.on('gift', e => {
    if (!shouldCountGift(e)) return;
    gift(
      e.uniqueId || e.nickname,
      e.gift?.name || e.gift?.giftDetails?.giftName || e.giftName || 'Cadeau',
      e.repeatCount || e.repeat_count || 1,
      (e.common?.msgId || e.msgId) ? String(e.common?.msgId || e.msgId) : null
    );
  });
  active.on('like', e => event({
    event: 'like',
    user: sanitizedUsername(e.uniqueId || e.nickname),
    count: Number(e.likeCount || e.count) || 1
  }));
  active.on('social', e => {
    const action = String(e.displayType || e.label || '').toLowerCase();
    if (action.includes('follow') || action.includes('abonn')) {
      event({
        event: 'follow',
        user: sanitizedUsername(e.user?.uniqueId || e.uniqueId || e.user?.nickname || e.nickname)
      });
    }
  });

  active.on('disconnected', () => {
    if (connector === active) {
      message('TikTok deconnecte, nouvelle tentative...');
      planRetry();
    }
  });
  active.on('error', e => console.error('TikTok:', e.message));

  try {
    await active.connect();
    if (connector === active) message('TikTok connecte : @' + name);
  } catch (e) {
    if (connector === active) {
      message('TikTok non disponible : ' + e.message);
      planRetry();
    }
  }
}

const server = http.createServer((req, res) => {
  const reply = (code, data) => {
    res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(data));
  };
  if (req.method === 'GET' && req.url === '/health') {
    return reply(200, { ok: true, status });
  }
  // Bind to loopback only; no external network access.
  if (req.method === 'POST' && req.url === '/simulate') {
    let raw = '';
    req.on('data', chunk => {
      raw += chunk;
      if (raw.length > 16000) req.destroy();
    });
    req.on('end', () => {
      try {
        const accepted = simulate(JSON.parse(raw));
        reply(accepted ? 200 : 400, { ok: accepted });
      } catch (_) {
        reply(400, { ok: false, error: 'JSON invalide' });
      }
    });
    return;
  }
  reply(404, { ok: false });
});

const wss = new WebSocketServer({ server, maxPayload: 8192 });
wss.on('connection', ws => {
  ws.send(JSON.stringify({ type: 'status', message: status }));
  ws.on('message', async raw => {
    try {
      const request = JSON.parse(String(raw));
      if (request.type !== 'control') return;
      if (request.action === 'connect') await connectTikTok(request.username);
      else if (request.action === 'disconnect') await stopConnection();
      else if (request.action === 'simulate') simulate(request.payload || {});
    } catch (e) {
      console.error('Message invalide:', e.message);
    }
  });
});

server.listen(PORT, HOST, () => message('Passerelle locale prete (simulation)'));
