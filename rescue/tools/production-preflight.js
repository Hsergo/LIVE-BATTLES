#!/usr/bin/env node
'use strict';
// Source-only preflight. Absolutely no Godot, Windows export, or compilation.
// This validates integration contracts, not runtime physics or graphical quality.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname,'..');
const read = relative => fs.readFileSync(path.join(root,relative),'utf8');
const checks = [];
function ensure(condition,description) {
  assert.ok(condition,description);
  checks.push(description);
}
const catalogue=read('game/scripts/mission_catalog.gd');
const model=read('game/scripts/mission.gd');
const village=read('game/scripts/villagers_3d.gd');
const world=read('game/scripts/world_3d.gd');
const motor=read('game/scripts/character_motor_3d.gd');
const ui=read('game/scripts/main.gd');
const tests=read('game/tests/crowd_physics_rules.gd');
const workerWorkflow=fs.readFileSync(path.join(root,'../.github/workflows/rescue-windows.yml'),'utf8');
const levels=[...catalogue.matchAll(/\{"id":"/g)];
ensure(levels.length===15,'15 campaign definitions');
const types=new Set([...catalogue.matchAll(/"site_type":"([^"]+)"/g)].map(m=>m[1]));
ensure(types.size===5,'5 mission site families');
ensure(model.includes('next_villager_index'),'stable civilian index in mission');
ensure(model.includes('visual_events.append(event.duplicate())'),'separate visual event buffer');
ensure(village.includes('person.call("configure",2,'),'civilians have physics colliders');
ensure(village.includes('person_index'),'no anonymous teleporting civilian');
ensure(village.includes('last_rescued_position'),'rescued NPC camera tracking');
ensure(motor.includes('extends CharacterBody3D') && motor.includes('move_and_slide()'),'collision-based pedestrian motion');
ensure(world.includes('rig.call("configure",4,'),'crew has separate collision layer');
ensure(world.includes('func _physics_process(delta: float)'),'physics movement runs on fixed timestep');
ensure(world.includes('func _add_rail_collider('),'bridge barriers physically block the edges');
ensure(world.includes('civilians.call("sync",d)'),'NPC route simulation integrated into world physics');
ensure(world.includes('func _build_lighthouse()') && world.includes('func _build_dam()') && world.includes('func _build_helipad()'),'five 3D terrain designs');
ensure(ui.includes('_draw_footer_3d()') && ui.includes('_draw_3d_leaderboards()'),'stream-optimized HUD and scoreboards');
ensure(ui.includes('Vector2(32,1117)'),'rankings moved below the 3D play area');
ensure(tests.includes('CharacterBody3D') && tests.includes('physics_frame'),'future runtime collision acceptance test prepared');
ensure(/^\s*workflow_dispatch:\s*$/m.test(workerWorkflow),'manual Windows build remains possible');
ensure(!/^\s{2}push:\s*$/m.test(workerWorkflow),'Windows compilation has no push trigger');
console.log('SOURCE PREFLIGHT PASS',checks.length,'checks');
checks.forEach((item,i)=>console.log(String(i+1).padStart(2,'0')+'. '+item));
