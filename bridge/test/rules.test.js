'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeCommand, giftPoints, shouldCountGift, sanitizedUsername } = require('../src/rules');
const gifts = { default_points: 1, gifts: { rose: { points: 3 } } };

test('joins red', () => assert.deepEqual(normalizeCommand(' !join RED '), {command:'join',team:'red'}));
test('joins blue', () => assert.equal(normalizeCommand('!join blue').team, 'blue'));
test('attack recognized', () => assert.equal(normalizeCommand('!attack').command,'attack'));
test('invalid command rejected', () => assert.equal(normalizeCommand('!erase all'),null));
test('gift multiplier', () => assert.equal(giftPoints('Rose',gifts,3),9));
test('unknown gift fallback', () => assert.equal(giftPoints('Unknown',gifts),1));
test('unfinished streak ignored', () => assert.equal(shouldCountGift({giftType:1,repeatEnd:false}),false));
test('completed streak counted', () => assert.equal(shouldCountGift({giftType:1,repeatEnd:true}),true));
test('username single line', () => assert.equal(sanitizedUsername('hello\nworld'),'helloworld'));
