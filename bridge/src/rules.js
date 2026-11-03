'use strict';
const VALID = /^!(?:join\s+(red|blue)|attack|defend|heal|status)$/;

function normalizeCommand(text) {
  const value = String(text ?? '').trim().toLowerCase();
  const match = VALID.exec(value);
  return match ? { command: value.startsWith('!join') ? 'join' : value.slice(1), team: match[1] ?? null } : null;
}

// Ce sont des AMES DE JEU, pas la valeur en coins ou le prix des cadeaux TikTok.
// Un cadeau non configure n'accorde aucune ressource.
function giftPoints(name, config, repeatCount = 1) {
  const key = String(name ?? '').trim().toLowerCase().normalize('NFKC');
  const gift = config.gifts?.[key];
  if (!gift) return 0;
  const unit = Math.max(0, Math.floor(Number(gift.souls ?? gift.points ?? 0) || 0));
  const quantity = Math.min(1000, Math.max(1, Math.floor(Number(repeatCount) || 1)));
  return unit * quantity;
}

// Les mises à jour cumulées des cadeaux en rafale ne doivent pas etre payées deux fois.
function shouldCountGift(event) {
  const giftType = Number(event.giftDetails?.giftType ?? event.gift?.giftDetails?.giftType ?? event.giftType ?? 0);
  return !(giftType === 1 && !Boolean(event.repeatEnd));
}
function sanitizedUsername(value) {
  return String(value ?? 'Spectateur').replace(/[\r\n\t]/g, '').slice(0, 48) || 'Spectateur';
}
module.exports = { normalizeCommand, giftPoints, shouldCountGift, sanitizedUsername };
