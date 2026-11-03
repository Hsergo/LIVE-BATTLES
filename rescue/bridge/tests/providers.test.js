'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeEvent,LiveProvider,PROVIDERS} = require('../providers');
const config=require('../gifts.json');
const {giftMaterials,commandOf} = require('../rules');
test('TikFinity chat normalise avec pseudo reel',()=>{
  assert.deepEqual(normalizeEvent({event:'chat',data:{user:{uniqueId:'alice'},comment:'!build',msgId:'a1'}}),
    {event:'chat',user:'alice',text:'!build',id:'a1'});
});
test('TikFinity cadeau Rose 4, final seulement',()=>{
  assert.equal(normalizeEvent({event:'gift',data:{user:{uniqueId:'bob'},giftName:'Rose',giftType:1,repeatCount:5,repeatEnd:false}}),null);
  const gift=normalizeEvent({event:'gift',data:{user:{uniqueId:'bob'},giftName:'Rose',giftType:1,repeatCount:5,repeatEnd:true,groupId:'g1'}});
  assert.equal(gift.count,5);
  assert.equal(giftMaterials(gift.gift_name,config,gift.count),20);
  assert.equal(gift.id,'g1:bob:Rose');
});
test('TikTools cadeau Galaxy evenement JSON',()=>{
 const gift=normalizeEvent(JSON.stringify({event:'gift',data:{user:{uniqueId:'eva'},giftName:'Galaxy',giftType:0,repeatCount:1,msgId:'42'}}));
 assert.equal(gift.gift_name,'Galaxy');
 assert.equal(gift.id,'42');
});
test('Eviter noms sans auteur, sans commenter pour une personne fictive',()=>{
 assert.equal(normalizeEvent({event:'chat',data:{comment:'!build'}}),null);
});
test('TikFinity follow et share',()=>{
 assert.equal(normalizeEvent({event:'social',data:{user:{uniqueId:'sam'},action:'follow'}}).event,'follow');
 assert.equal(normalizeEvent({event:'share',data:{user:{uniqueId:'sam'}}}).event,'share');
});
test('Options de fournisseurs fixes',()=>assert.deepEqual(Object.keys(PROVIDERS),['tikfinity','tiktools']));
test('TikTools exige pseudo et cle, TikFinity pas de compte secret',()=>{
 const status=[];
 const provider=new LiveProvider(()=>{},t=>status.push(t));
 assert.equal(provider.start('tiktools','alice',''),false);
 assert.match(status[status.length-1],/cle API/);
 provider.stop(false);
});
test('Commandes gratuites restent disponibles',()=>assert.equal(commandOf('!construire'),'!build'));
