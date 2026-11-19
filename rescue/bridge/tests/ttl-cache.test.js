'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {TtlCache} = require('../ttl-cache');

test('Long session caches expire below capacity and stay bounded during bursts',()=>{
  let now=0;
  const cache=new TtlCache(500,120000,()=>now);
  cache.set('first','event');
  assert.equal(cache.get('first'),'event');
  now=120001;
  assert.equal(cache.get('first'),undefined);
  for(let i=0;i<100000;i++)cache.set('user_'+i,i);
  assert.equal(cache.size,500);
  assert.equal(cache.get('user_0'),undefined);
  assert.equal(cache.get('user_99999'),99999);
  cache.set('user_99999','latest');
  now+=120001;
  assert.equal(cache.get('user_99999'),undefined);
});
