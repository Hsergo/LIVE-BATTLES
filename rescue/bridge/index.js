'use strict';
const http = require('node:http');
const path = require('node:path');
const fs = require('node:fs');
const { WebSocketServer, WebSocket } = require('ws');
const { commandOf, userOf, giftMaterials } = require('./rules');
const { LiveProvider, PROVIDERS } = require('./providers');

const HOST = '127.0.0.1';
const PORT = 8766;
const gifts = JSON.parse(fs.readFileSync(path.join(__dirname,'gifts.json'),'utf8'));
const metrics = { chat: 0, gift: 0, like: 0, follow: 0, share: 0, rejected: 0 };
const seen = new Map(), cooldown = new Map();
let state = 'PASSERELLE DISPONIBLE • CHOISIS UN CONNECTEUR';
let wss;
function send(data) {
  if (!wss) return;
  const out = JSON.stringify({ ...data, timestamp: new Date().toISOString() });
  for (const client of wss.clients) if (client.readyState === WebSocket.OPEN) client.send(out);
}
function updateStatus(message) {
  state = String(message).slice(0, 200);
  process.stdout.write('[SAUVETAGE] ' + state + '\n');
  send({type:'status',message:state});
}
function alreadySeen(id) {
  if (!id) return false;
  const now = Date.now();
  if (seen.size > 1500) for (const [k,t] of seen) if (now-t > 120000) seen.delete(k);
  if (seen.has(id)) return true;
  seen.set(id, now);
  return false;
}
function pushCommand(user, comment, id=null, source='live') {
  const command = commandOf(comment), name = userOf(user);
  if (!name || !command || alreadySeen(id)) { metrics.rejected++; return false; }
  const key = name + '|' + command, now = Date.now();
  if (command !== '!join' && now - (cooldown.get(key) || 0) < 850) return false;
  cooldown.set(key, now);
  send({type:'event',event:'chat',user:name,text:command,source});
  metrics.chat++;
  return true;
}
function pushGift(user, name, count, id=null, source='live') {
  const username = userOf(user), giftName = String(name||'').slice(0,64);
  if (!username || !giftMaterials(giftName,gifts,count) || alreadySeen(id)) { metrics.rejected++; return false; }
  send({type:'event',event:'gift',user:username,gift_name:giftName,count:Math.min(1000,Math.max(1,Number(count)||1)),source});
  metrics.gift++;
  return true;
}
function ingest(event, source='live') {
  if (!event || typeof event !== 'object') return false;
  if (event.event === 'chat') return pushCommand(event.user,event.text,event.id,source);
  if (event.event === 'gift') return pushGift(event.user,event.gift_name,event.count,event.id,source);
  if (['follow','share','like','room'].includes(event.event)) {
    if (event.id && alreadySeen(event.id)) return false;
    if (metrics[event.event] !== undefined) metrics[event.event]++;
    send({type:'event',event:event.event,user:userOf(event.user||''),count:Number(event.count)||0,source});
    return true;
  }
  return false;
}
const live = new LiveProvider(ingest, updateStatus);
function simulate(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return false;
  const user=userOf(body.username || 'TEST');
  if (body.type === 'comment') return pushCommand(user,body.text||'',null,'simulator');
  if (body.type === 'gift') return pushGift(user,body.gift_name||'',body.count||1,null,'simulator');
  return false;
}
const server=http.createServer((req,res) => {
  const respond=(code,obj) => {
    res.writeHead(code,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});
    res.end(JSON.stringify(obj));
  };
  if (req.method === 'GET' && req.url === '/health') {
    return respond(200,{ok:true,status:state,providers:Object.keys(PROVIDERS),
      connection:live.connectionStatus(),events:metrics,version:'0.3.0'});
  }
  if (req.method === 'POST' && req.url === '/simulate') {
    let input='';
    req.on('data',x=>{ input+=x; if (input.length>8192) req.destroy(); });
    req.on('end',()=>{
      let accepted=false;
      try { accepted=simulate(JSON.parse(input)); } catch (_) {}
      respond(accepted?200:400,{ok:accepted});
    });
    return;
  }
  respond(404,{ok:false});
});
wss=new WebSocketServer({server,maxPayload:8192});
wss.on('connection', (socket, request)=>{
  // The Windows game has no browser Origin header. Reject cross-site browser control.
  if (request.headers.origin) { socket.close(1008,'Browser origin forbidden'); return; }
  socket.send(JSON.stringify({type:'status',message:state}));
  socket.send(JSON.stringify({type:'providers',items:Object.keys(PROVIDERS)}));
  socket.on('message', raw=>{
    let request;
    try { request=JSON.parse(String(raw)); } catch (_) { return; }
    if (request.type !== 'control') return;
    if (request.action === 'connect') {
      const provider = ['tikfinity','tiktools'].includes(request.provider) ? request.provider : 'tikfinity';
      live.start(provider, request.username, request.apiKey);
    } else if (request.action === 'disconnect') live.stop();
    else if (request.action === 'simulate') simulate(request.payload);
  });
});
server.listen(PORT,HOST,()=>updateStatus('PASSERELLE V0.3 • TIKFINITY / TIKTOOLS DISPONIBLES'));
process.on('SIGINT',()=>{live.stop(false);server.close();});
