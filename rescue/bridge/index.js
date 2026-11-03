'use strict';
const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {WebSocketServer,WebSocket}=require('ws');
const {commandOf,userOf,giftMaterials,giftCompleted}=require('./rules');

const HOST='127.0.0.1';
const PORT=8766;
const gifts=JSON.parse(fs.readFileSync(path.join(__dirname,'gifts.json'),'utf8'));
let status='MODE DEMO • PASSERELLE PRETE';
let currentConnection=null;
let username='';
let retry=null;
const seen=new Map();
const cooldown=new Map();
let wss;

function publish(data) {
  const packet=JSON.stringify({...data,timestamp:new Date().toISOString()});
  for(const client of wss.clients) {
    if(client.readyState===WebSocket.OPEN)client.send(packet);
  }
}
function info(message) {
  status=message;
  process.stdout.write('[SAUVETAGE] '+status+'\n');
  publish({type:'status',message});
}
function dedupe(eventId) {
  if(!eventId)return false;
  const now=Date.now();
  for(const [id,time] of seen)if(now-time>600000)seen.delete(id);
  if(seen.has(eventId))return true;
  seen.set(eventId,now);
  return false;
}
function onComment(user,comment,id=null) {
  const cmd=commandOf(comment), who=userOf(user);
  if(!cmd||!who||dedupe(id))return false;
  const now=Date.now();
  if(cmd!=='!join'&&now-(cooldown.get(who+'|'+cmd)||0)<950)return false;
  cooldown.set(who+'|'+cmd,now);
  publish({type:'event',event:'chat',user:who,text:cmd,source:id?'live':'simulator'});
  return true;
}
function onGift(user,title,amount=1,id=null) {
  const who=userOf(user),name=String(title||'').slice(0,64);
  if(!who||giftMaterials(name,gifts,amount)<=0||dedupe(id))return false;
  publish({type:'event',event:'gift',user:who,gift_name:name,count:Math.min(1000,Math.max(1,Math.floor(Number(amount)||1))),source:id?'live':'simulator'});
  return true;
}
function simulate(input) {
  if(!input||typeof input!=='object'||Array.isArray(input))return false;
  const user=userOf(input.username||'Demo');
  switch(input.type) {
    case 'comment':return onComment(user,input.text||'');
    case 'gift':return onGift(user,input.gift_name||'',input.count||1);
    default:return false;
  }
}

async function closeLive() {
  username='';
  if(retry){clearTimeout(retry);retry=null;}
  const previous=currentConnection;currentConnection=null;
  if(previous)try{await previous.disconnect();}catch(_){}
  info('DECONNECTE • DEMONSTRATION DISPONIBLE');
}
function reconnectLater() {
  if(!username||retry)return;
  retry=setTimeout(()=>{retry=null;connectLive(username).catch(e=>info(e.message));},15000);
}
async function connectLive(value) {
  const next=String(value||'').replace(/^@/,'').trim().replace(/[^A-Za-z0-9_.]/g,'').slice(0,32);
  if(!next){info('IDENTIFIANT TIKTOK INVALIDE');return;}
  username=next;
  if(currentConnection){try{await currentConnection.disconnect();}catch(_){}currentConnection=null;}
  info('TENTATIVE DE CONNEXION : @'+username);
  let TikTokLiveConnection;
  try {({TikTokLiveConnection}=await import('tiktok-live-connector'));}
  catch(e){info('CONNECTEUR TIKTOK NON DISPONIBLE');return;}
  const client=new TikTokLiveConnection(next);
  currentConnection=client;
  const who=(e)=>userOf(e.user?.uniqueId||e.uniqueId||e.user?.nickname||e.nickname);
  client.on('chat',e=>onComment(who(e),e.comment||'',String(e.common?.msgId||e.msgId||'')||null));
  client.on('gift',e=>{
    if(!giftCompleted(e))return;
    const name=e.giftDetails?.giftName||e.gift?.giftDetails?.giftName||e.gift?.name||e.giftName||'';
    onGift(who(e),name,e.repeatCount||e.repeat_count||1,String(e.common?.msgId||e.msgId||'')||null);
  });
  client.on('disconnected',()=>{
    if(currentConnection===client){info('LIVE DECONNECTE : RECONNEXION');reconnectLater();}
  });
  client.on('error',e=>process.stderr.write('[TikTok] '+String(e.message||e)+'\n'));
  try{await client.connect();if(currentConnection===client)info('TIKTOK LIVE CONNECTE @'+next);}
  catch(e){if(currentConnection===client){info('LIVE INDISPONIBLE : '+String(e.message||e));reconnectLater();}}
}
const server=http.createServer((req,res)=>{
  const reply=(code,payload)=>{res.writeHead(code,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(payload));};
  if(req.method==='GET'&&req.url==='/health')return reply(200,{ok:true,status,version:'0.1.0'});
  if(req.method==='POST'&&req.url==='/simulate'){
    let raw='';
    req.on('data',chunk=>{raw+=chunk;if(raw.length>8192)req.destroy();});
    req.on('end',()=>{try{const accepted=simulate(JSON.parse(raw));reply(accepted?200:400,{ok:accepted});}catch(_){reply(400,{ok:false});}});
    return;
  }
  reply(404,{ok:false});
});
wss=new WebSocketServer({server,maxPayload:8192});
wss.on('connection',socket=>{
  socket.send(JSON.stringify({type:'status',message:status}));
  socket.on('message',async raw=>{
    try {
      const request=JSON.parse(String(raw));
      if(request.type!=='control')return;
      if(request.action==='connect')await connectLive(request.username);
      else if(request.action==='disconnect')await closeLive();
      else if(request.action==='simulate')simulate(request.payload);
    }catch(e){process.stderr.write('WS error: '+e.message+'\n');}
  });
});
server.listen(PORT,HOST,()=>info('PASSERELLE LOCALE '+HOST+':'+PORT));
