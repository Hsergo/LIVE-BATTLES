'use strict';

const VALID = /^!(?:join\s+(red|blue)|attack|defend|heal|status)$/;

function normalizeCommand(text) {
  const value = String(text ?? '').trim().toLowerCase();
  const match = VALID.exec(value);
  if (!match) return null;
  return { command: value.startsWith('!join') ? 'join' : value.slice(1), team: match[1] ?? null };
}

function giftPoints(name, config, repeatCount = 1) {
  const key = String(name ?? '').toLowerCase();
  const unit = Number(config.gifts?.[key]?.points ?? config.default_points ?? 1);
  const quantity = Math.min(1000, Math.max(1, Math.floor(Number(repeatCount) || 1)));
  return Math.max(1, Math.floor(unit || 1)) * quantity;
}

function shouldCountGift(event) {
  return !(Number(event.giftType) === 1 && !Boolean(event.repeatEnd));
}

function sanitizedUsername(value) {
  return String(value ?? 'Spectateur').replace(/[\r\n\t]/g, '').slice(0, 48) || 'Spectateur';
}

module.exports = { normalizeCommand, giftPoints, shouldCountGift, sanitizedUsername };
