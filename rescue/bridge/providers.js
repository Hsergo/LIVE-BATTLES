'use strict';
const WebSocket = require('ws');

function safeId(value) {
  return String(value ?? '').replace(/[\r\n\t<>]/g, '').trim().slice(0, 32);
}
function userId(data) {
  return safeId(data?.user?.uniqueId || data?.user?.unique_id || data?.uniqueId || data?.user?.nickname || data?.nickname);
}
function eventId(data) {
  const raw = data?.msgId ?? data?.common?.msgId ?? data?.messageId ?? data?.transactionId ?? null;
  return raw === null || raw === '' ? null : String(raw).slice(0, 128);
}
function normalizeEvent(raw) {
  let message;
  try { message = typeof raw === 'string' ? JSON.parse(raw) : raw; } catch (_) { return null; }
  if (!message || typeof message !== 'object') return null;
  const type = String(message.event || message.type || '').toLowerCase();
  const d = message.data && typeof message.data === 'object' ? message.data : message;
  const user = userId(d);
  const id = eventId(d);
  if (['chat', 'comment'].includes(type)) {
    const comment = String(d.comment ?? d.text ?? '').slice(0, 180);
    return user && comment ? { event: 'chat', user, text: comment, id } : null;
  }
  if (type === 'gift') {
    const giftName = String(d.giftName || d.gift?.name || d.gift?.giftDetails?.giftName || '').slice(0, 64);
    const giftType = Number(d.giftType ?? d.gift?.giftType ?? d.gift?.giftDetails?.giftType ?? 0);
    const repeatEnd = d.repeatEnd ?? d.repeat_end ?? d.gift?.repeatEnd;
    if (giftType === 1 && !(repeatEnd === true || repeatEnd === 1)) return null;
    const count = Math.min(1000, Math.max(1, Math.floor(Number(d.repeatCount ?? d.repeat_count ?? 1) || 1)));
    // Do not use a changing repeatCount as a dedupe key on a streak.
    const dedupeKey = id || (d.groupId ? String(d.groupId) + ':' + user + ':' + giftName : null);
    return user && giftName ? { event: 'gift', user, gift_name: giftName, count, id: dedupeKey } : null;
  }
  if (['follow', 'share', 'social'].includes(type)) {
    const action = type === 'social' ? String(d.action || d.displayType || d.label || '').toLowerCase() : type;
    if (!['follow', 'share'].some(x => action.includes(x))) return null;
    return user ? { event: action.includes('follow') ? 'follow' : 'share', user, id } : null;
  }
  if (type === 'like') return user ? { event: 'like', user, count: Math.max(0, Math.min(10000, Number(d.likeCount || d.count || 1))), id } : null;
  if (['roomuser', 'roomuserseq', 'viewer', 'roominfo'].includes(type)) return { event: 'room', count: Number(d.viewerCount || d.viewer_count || 0) || 0, id };
  return null;
}
const PROVIDERS = Object.freeze({
  tikfinity: { label: 'TikFinity Desktop', endpoint: 'ws://127.0.0.1:21213/' },
  tiktools: { label: 'TikTools API', endpoint: 'wss://api.tik.tools' }
});
class LiveProvider {
  constructor(onPacket, onStatus) {
    this.onPacket = onPacket;
    this.onStatus = onStatus;
    this.socket = null;
    this.timer = null;
    this.provider = 'tikfinity';
    this.username = '';
    this.apiKey = '';
    this.connected = false;
    this.confirmed = false;
    this.attempt = 0;
    this.stopped = true;
    this.generation = 0;
    this.lastEventAt = null;
  }
  info(message) { this.onStatus(message); }
  connectionStatus() {
    return { provider: this.provider, transportConnected: this.connected, liveConfirmed: this.confirmed,
      username: this.username, lastEventAt: this.lastEventAt, attempts: this.attempt };
  }
  start(provider = 'tikfinity', username = '', apiKey = '') {
    this.stop(false);
    this.stopped = false;
    this.provider = PROVIDERS[provider] ? provider : 'tikfinity';
    this.username = safeId(username).replace(/^@/, '');
    this.apiKey = String(apiKey || process.env.TIKTOOLS_API_KEY || '').trim().slice(0, 256);
    this.attempt = 0;
    if (this.provider === 'tiktools' && (!this.username || !this.apiKey)) {
      this.stopped = true;
      this.info('TIKTOOLS : pseudo ET cle API necessaires (cle non enregistree)');
      return false;
    }
    this._open(++this.generation);
    return true;
  }
  _open(generation) {
    if (this.stopped || generation !== this.generation) return;
    const host = this.provider === 'tikfinity' ? PROVIDERS.tikfinity.endpoint :
      PROVIDERS.tiktools.endpoint + '?uniqueId=' + encodeURIComponent(this.username) +
      '&apiKey=' + encodeURIComponent(this.apiKey);
    this.info('CONNEXION ' + this.provider.toUpperCase() + ' EN COURS...');
    const socket = new WebSocket(host, { handshakeTimeout: 7500 });
    this.socket = socket;
    socket.on('open', () => {
      if (this.stopped || generation !== this.generation) return;
      this.connected = true;
      this.attempt = 0;
      this.info('SOURCE ' + this.provider.toUpperCase() + ' CONNECTEE • ATTENTE EVENEMENTS LIVE');
    });
    socket.on('message', raw => {
      if (this.stopped || generation !== this.generation) return;
      const normalized = normalizeEvent(String(raw));
      if (!normalized) return;
      if (!this.confirmed) {
        this.confirmed = true;
        this.info('TIKTOK LIVE CONNECTE VIA ' + this.provider.toUpperCase() + ' • EVENEMENTS RECUS');
      }
      this.lastEventAt = new Date().toISOString();
      this.onPacket(normalized, this.provider);
    });
    socket.on('error', () => { /* Close path emits a concise status and reconnects. */ });
    socket.on('close', () => {
      if (this.stopped || generation !== this.generation) return;
      this.connected = false;
      this.confirmed = false;
      this.attempt++;
      const delay = Math.min(30000, 2500 * Math.min(8, this.attempt));
      this.info(this.provider === 'tikfinity' ?
        'TIKFINITY DECONNECTE : ouvre TikFinity Desktop et connecte ton LIVE ; nouvelle tentative automatique' :
        'TIKTOOLS DECONNECTE : verifie cle API, quota et LIVE ; nouvelle tentative automatique');
      this.timer = setTimeout(() => {
        this.timer = null;
        this._open(generation);
      }, delay);
    });
  }
  stop(report = true) {
    this.stopped = true;
    this.generation++;
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    if (this.socket) {
      this.socket.removeAllListeners('close');
      this.socket.removeAllListeners('message');
      this.socket.terminate();
    }
    this.socket = null;
    this.connected = false;
    this.confirmed = false;
    this.apiKey = '';
    if (report) this.info('LIVE DECONNECTE • DEMONSTRATION DISPONIBLE');
  }
}
module.exports = { normalizeEvent, LiveProvider, PROVIDERS };
