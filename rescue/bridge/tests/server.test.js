'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {spawn} = require('node:child_process');
const path = require('node:path');
const WebSocket = require('ws');
const delay = ms => new Promise(resolve => setTimeout(resolve,ms));

test('packaged entry point exposes health, simulation, connection status and origin protection', {timeout:12000}, async()=>{
  const child=spawn(process.execPath,['index.js'],{cwd:path.join(__dirname,'..'),stdio:['ignore','pipe','pipe']});
  let logs=''; child.stdout.on('data',b=>logs+=b); child.stderr.on('data',b=>logs+=b);
  let socket;
  try {
    let health;
    for(let i=0;i<60;i++) {
      if(child.exitCode!==null) throw new Error('Bridge exited: '+logs);
      try { health=await (await fetch('http://127.0.0.1:8766/health')).json(); break; } catch { await delay(50); }
    }
    assert.equal(health?.app,'mission-sauvetage-live');
    assert.equal(health.version,'0.5.0');
    assert.equal(health.connection.liveConfirmed,false);
    assert.equal(health.cache.seen,0);
    const packets=[];
    socket=new WebSocket('ws://127.0.0.1:8766');
    socket.on('message',raw=>packets.push(JSON.parse(String(raw))));
    await new Promise((resolve,reject)=>{socket.once('open',resolve);socket.once('error',reject);});
    const response=await fetch('http://127.0.0.1:8766/simulate',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({type:'comment',username:'qa_user',text:'!build'})});
    assert.equal(response.status,200);
    await delay(80);
    assert.ok(packets.some(p=>p.type==='status'&&p.connection.liveConfirmed===false));
    assert.ok(packets.some(p=>p.event==='chat'&&p.user==='qa_user'&&p.source==='simulator'));
    const invalid=await fetch('http://127.0.0.1:8766/simulate',{method:'POST',body:'{bad json'});
    assert.equal(invalid.status,400);
    const browser=new WebSocket('ws://127.0.0.1:8766',{origin:'https://unrelated.example'});
    const code=await new Promise((resolve,reject)=>{browser.once('close',resolve);browser.once('error',reject);});
    assert.equal(code,1008);
    socket.send(JSON.stringify({type:'control',action:'disconnect'}));
    await delay(80);
    assert.equal(packets.at(-1).connection.liveConfirmed,false);
  } finally {
    if(socket)socket.terminate();
    child.kill();
    await new Promise(resolve=>{if(child.exitCode!==null)resolve();else child.once('exit',resolve);});
  }
});
