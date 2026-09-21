// Optional browser-DOM checks: NODE_PATH=/path/to/node_modules node --test tests/test_tour.cjs
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {JSDOM,VirtualConsole}=require('jsdom');
const source=fs.readFileSync(path.join(__dirname,'../docs/tour/index.html'),'utf8');
function setup(){
 const errors=[];const console=new VirtualConsole();console.on('jsdomError',e=>errors.push(e.message));
 const dom=new JSDOM(source,{runScripts:'dangerously',url:'https://example.test/',virtualConsole:console});
 const doc=dom.window.document;
 const click=selector=>{const el=doc.querySelector(selector);assert.ok(el,selector);el.click()};
 return {dom,doc,errors,click};
}
test('all thirteen illustrated scenes open, close and have no JS errors',()=>{
 const {dom,doc,errors,click}=setup();
 const buttons=[...doc.querySelectorAll('#tabs button')];assert.equal(buttons.length,13);
 for(const b of buttons){b.click();assert.ok(doc.querySelector('.panel,.sheetempty'));}
 click('[data-close]');assert.ok(doc.querySelector('.sheetempty'));assert.deepEqual(errors,[]);dom.window.close();
});
test('library search, empty state, keyboard and placements',()=>{
 const {dom,doc,errors,click}=setup();click('#tabs [data-scene="Library"]');
 assert.equal(doc.activeElement.id,'search');
 const search=doc.getElementById('search');search.value='fire';search.dispatchEvent(new dom.window.Event('input'));
 assert.equal(doc.querySelectorAll('#results button').length,1);assert.match(doc.getElementById('results').textContent,/Firefox/);
 search.value='not an installed app';search.dispatchEvent(new dom.window.Event('input'));assert.match(doc.getElementById('results').textContent,/No matching/);
 for(const edge of ['top','bottom','center']){const el=doc.getElementById('edge');el.value=edge;el.dispatchEvent(new dom.window.Event('change'));assert.ok(doc.getElementById('stage').classList.contains(edge));}
 assert.deepEqual(errors,[]);dom.window.close();
});
test('connection and history flows; power focuses safe choice',()=>{
 const {dom,doc,errors,click}=setup();click('#tabs [data-scene="Wireless"]');click('[data-wifi="Scan"]');click('[data-wifi="Join"]');assert.ok(doc.querySelector('input[type=password]'));click('[data-wifi="Link"]');
 click('#tabs [data-scene="Your day"]');click('[data-day="History"]');assert.equal(doc.querySelectorAll('.calendar button').length,30);click('[data-date="17"]');assert.match(doc.querySelector('.panel').textContent,/September 17/);click('[data-day="Apps"]');assert.equal(doc.querySelectorAll('.progress').length,3);
 click('#tabs [data-scene="Session"]');click('[data-power="Shut down"]');assert.equal(doc.activeElement.id,'cancel');
 doc.dispatchEvent(new dom.window.KeyboardEvent('keydown',{key:'Escape'}));assert.equal(doc.getElementById('cancel'),null);assert.ok(doc.querySelector('[data-power="Shut down"]'));
 assert.deepEqual(errors,[]);dom.window.close();
});

test('quick ribbon selects scenes and wallpaper mode recolors the surface',()=>{
 const {dom,doc,errors,click}=setup();
 click('#tabs [data-scene="Quick wallpapers"]');
 assert.equal(doc.querySelectorAll('.poster').length,5);
 const before=doc.getElementById('desktop').style.getPropertyValue('--bg');
 click('[data-poster="2"]');
 assert.notEqual(doc.getElementById('desktop').style.getPropertyValue('--bg'),before);
 assert.equal(doc.getElementById('poster-name').textContent,'Blue hour');
 const theme=doc.getElementById('theme');theme.value='black';theme.dispatchEvent(new dom.window.Event('change'));
 assert.equal(doc.getElementById('desktop').style.getPropertyValue('--bg'),'#000000');
 assert.deepEqual(errors,[]);dom.window.close();
});
test('cartridge navigation, background-free ribbon keys, thumbnail preview and rail placement',()=>{
 const {dom,doc,errors,click}=setup();
 click('[data-app="1"]');assert.match(doc.getElementById('app-readout').textContent,/Firefox/);
 doc.activeElement.dispatchEvent(new dom.window.KeyboardEvent('keydown',{key:'ArrowRight',bubbles:true}));assert.match(doc.getElementById('app-readout').textContent,/Foot/);
 click('#tabs [data-scene="Quick wallpapers"]');assert.equal(doc.querySelector('.ribbon .panelhead'),null);assert.doesNotMatch(doc.querySelector('.ribbon').textContent,/Adjust colors/);
 doc.dispatchEvent(new dom.window.KeyboardEvent('keydown',{key:'ArrowRight'}));assert.equal(doc.getElementById('poster-name').textContent,'Blue hour');
 click('#tabs [data-scene="Image browser"]');click('[data-photo="3"]');assert.equal(doc.getElementById('photo-name').textContent,'Ember.png');
 click('#tabs [data-scene="Your corner"]');click('[data-corner="Bar"]');
 assert.equal(doc.querySelector('#rail [aria-label="Settings"]'),null);
 click('[data-relocate="clock"]');assert.ok(doc.querySelector('#rail [data-zone="bottom"] .clock'));
 click('#tabs [data-scene="Session"]');assert.equal(doc.querySelector('.session .profile'),null);
 assert.deepEqual(errors,[]);dom.window.close();
});

test('four rail edges, click-only wallpaper target, scrubber and overflow workspace illustration',()=>{
 const {dom,doc,errors,click}=setup();
 for(const edge of ['left','right','top','bottom']){const el=doc.getElementById('rail-edge');el.value=edge;el.dispatchEvent(new dom.window.Event('change'));assert.equal(doc.getElementById('desktop').dataset.rail,edge)}
 assert.equal(doc.getElementById('edge-trigger').onmouseenter,null);
 click('#edge-trigger');const scrub=doc.getElementById('poster-scrub');scrub.value='4';scrub.dispatchEvent(new dom.window.Event('input'));assert.equal(doc.getElementById('poster-name').textContent,'Stone');
 click('#tabs [data-scene="Workspaces"]');assert.equal(doc.querySelectorAll('[data-space]').length,12);click('[data-space="12"]');click('[data-open-space="12"]');
 assert.ok(doc.querySelector('#rail [data-workspace="12"] .gem.lit'));assert.equal(doc.querySelectorAll('#rail [data-workspace]').length,5);
 assert.deepEqual(errors,[]);dom.window.close();
});
