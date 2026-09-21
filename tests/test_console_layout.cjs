const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'), vm=require('node:vm'), path=require('node:path');
function load(file) {const ctx=vm.createContext({});vm.runInContext(fs.readFileSync(path.join(__dirname,'..',file),'utf8').replace(/^\.pragma library\s*/,''),ctx);return ctx;}
const modules=load('quickshell/common/ModuleCatalog.js');
const apps=load('quickshell/launcher/AppLibrary.js');
test('layout migration retains all modules once and drops unknown/duplicate IDs',()=>{
 const migrated=modules.layout({top:['clock','clock','unknown'],bottom:['settings']});
 const keys=Object.values(migrated).flat();assert.equal(keys.length,13);assert.equal(new Set(keys).size,13);
 assert.equal(migrated.top[0],'clock');assert.equal(migrated.bottom[0],'settings');
 assert.ok(!keys.includes('unknown'));
});
test('placement moves and reorders without mutating original settings or losing hidden modules',()=>{
 const original=modules.layoutDefaults();const result=modules.relocate(original,'clock','bottom',0);
 assert.ok(original.middle.includes('clock'));assert.ok(!result.middle.includes('clock'));
 assert.equal(result.bottom.at(-1),'clock');
 const moved=modules.relocate(result,'clock','bottom',-1);assert.equal(moved.bottom.at(-2),'clock');
 assert.equal(Object.values(moved).flat().filter(k=>k==='settings').length,1);
 assert.equal(modules.relocate(moved,'audio','bottom',-100).bottom[0],'audio');
});
test('library categories, desktop string/list categories, search ranking and shell recovery',()=>{
 const entries=[{name:'Settings',shellAction:'settings'},{name:'Steam',categories:['Game']},{name:'Terminal',categories:'System;Utility;'}, {name:'Hidden',noDisplay:true},{name:'Code',categories:{0:'Development',length:1}}, {name:'Web search',genericName:'Firefox'}, {name:'Firefox'}];
 assert.equal(apps.filter(entries,'','Games')[0].name,'Steam');
 assert.equal(apps.filter(entries,'','Create')[0].name,'Code');
 assert.equal(apps.filter(entries,'','Tools').length,2);
 assert.equal(apps.filter(entries,'fire','All')[0].name,'Firefox');
 assert.equal(apps.filter(entries,'settings','All')[0].shellAction,'settings');
 assert.equal(apps.filter(entries,'unknown','All').length,0);
 assert.equal(apps.move(0,-10,6),0);assert.equal(apps.move(2,4,6),5);assert.equal(apps.move(0,1,0),-1);
});
const placement=load('quickshell/common/PopupGeometry.js');
test('popup follows origin and clamps to frame at both ends, including short screens',()=>{
 assert.equal(placement.popupY(1080,300,18,540),390);
 assert.equal(placement.popupY(1080,300,18,48),18);
 assert.equal(placement.popupY(1080,300,18,1050),762);
 assert.equal(placement.popupY(400,364,18,380),18);
 assert.equal(placement.popupY(1080,300,18,-1),390);
});
test('actual popup manager captures click screen, clears origin for IPC and transfers between monitors',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../quickshell/bar/ShellFrame.qml'),'utf8');
 const ctx=vm.createContext({popupScreen:'',popupAnchorY:-1,pendingAnchorY:-1,pendingScreen:'',Hyprland:{focusedMonitor:{name:'DP-1'}},closeAll(){}});
 for(const name of ['toggleFrom','activate']) {
  const match=source.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));assert.ok(match,name);vm.runInContext(match[0],ctx);
 }
 const panel={shown:false,open(){this.shown=true;ctx.activate(this)},hide(){this.shown=false}};
 const origin={height:32,mapToItem(item,x,y){assert.equal(y,16);return {y:712}}};
 ctx.toggleFrom(panel,origin,'DP-2');assert.equal(ctx.popupScreen,'DP-2');assert.equal(ctx.popupAnchorY,712);assert.equal(ctx.pendingAnchorY,-1);
 ctx.toggleFrom(panel,origin,'DP-1');assert.ok(panel.shown);assert.equal(ctx.popupScreen,'DP-1');
 ctx.toggleFrom(panel,origin,'DP-1');assert.equal(panel.shown,false);
 panel.open();assert.equal(ctx.popupAnchorY,-1);assert.equal(ctx.popupScreen,'DP-1');
});
