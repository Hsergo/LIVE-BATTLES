'use strict';

const aliases = new Map([
  ['!join','!join'],['!play','!join'],['!jouer','!join'],
  ['!build','!build'],['!construire','!build'],
  ['!repair','!repair'],['!reparer','!repair'],['!réparer','!repair'],
  ['!rescue','!rescue'],['!sauver','!rescue'],
  ['!regles','!rules'],['!règles','!rules'],['!rules','!rules'],['!aide','!rules'],['!help','!rules'],
  ['!escort','!special'],['!pump','!special'],['!signal','!special'],['!valve','!special'],['!launch','!special'],['!special','!special'],
  ['1','1'],['2','2'],['3','3'],
  ['!vote 1','1'],['!vote 2','2'],['!vote 3','3'],
  ['!voter 1','1'],['!voter 2','2'],['!voter 3','3'],
]);
function commandOf(comment) {
  const text = String(comment || '').trim().toLowerCase().replace(/\s+/g,' ');
  return aliases.get(text) || null;
}
function userOf(value) {
  return String(value||'').replace(/[\r\n\t<>]/g,'').trim().slice(0,24);
}
function giftMaterials(name, settings, repeat = 1) {
  const key = String(name || '').toLowerCase().trim().normalize('NFKC');
  const alias = settings.aliases?.[key] || key;
  const perGift = Number(settings.gifts?.[alias] || 0);
  const count = Math.min(1000,Math.max(1,Math.floor(Number(repeat)||1)));
  return Math.max(0,Math.floor(perGift))*count;
}
function giftCompleted(event) {
  const type = Number(event.giftDetails?.giftType ?? event.gift?.giftDetails?.giftType ?? event.giftType ?? 0);
  return !(type === 1 && !Boolean(event.repeatEnd));
}
module.exports={commandOf,userOf,giftMaterials,giftCompleted};
