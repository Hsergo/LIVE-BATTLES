'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const {WebSocketServer}=require('ws');
const {LiveProvider}=require('../providers');

test('TikFinity Desktop : vrai protocole WebSocket local reproduit sans TikTok', {timeout: 7500}, async ()=>{
  const packets=[], statuses=[];
  const server=new WebSocketServer({host:'127.0.0.1',port:21213});
  await new Promise((resolve,reject)=>{
    server.once('listening',resolve);
    server.once('error',reject);
  });
  const provider=new LiveProvider(p=>packets.push(p),s=>statuses.push(s));
  try{
    const source=new Promise(resolve=>{
      server.once('connection',socket=>{
        socket.send(JSON.stringify({event:'chat',data:{user:{uniqueId:'alice'},comment:'!build',msgId:'100'}}));
        socket.send(JSON.stringify({event:'gift',data:{user:{uniqueId:'alice'},giftName:'Rose',giftType:1,repeatCount:3,repeatEnd:false,groupId:'series'}}));
        socket.send(JSON.stringify({event:'gift',data:{user:{uniqueId:'alice'},giftName:'Rose',giftType:1,repeatCount:3,repeatEnd:true,groupId:'series'}}));
        resolve();
      });
    });
    assert.equal(provider.start('tikfinity','streamer'),true);
    await source;
    await new Promise((resolve,reject)=>{
      const start=Date.now();
      const poll=setInterval(()=>{
        if(packets.length>=2){clearInterval(poll);resolve();}
        else if(Date.now()-start>2500){clearInterval(poll);reject(new Error('No fake TikFinity events received'));}
      },15);
    });
    assert.deepEqual(packets.map(x=>x.event),['chat','gift']);
    assert.equal(packets[1].count,3,'One final gift streak only');
    assert.equal(provider.connectionStatus().liveConfirmed,true);
    assert.ok(statuses.some(s=>s.includes('TIKTOK LIVE CONNECTE')));
  } finally {
    provider.stop(false);
    await new Promise(resolve=>server.close(resolve));
  }
});
