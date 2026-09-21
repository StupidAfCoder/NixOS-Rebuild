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
 const ctx=vm.createContext({popupScreen:'',popupAnchorY:-1,popupAnchorX:-1,pendingAnchorX:-1,pendingAnchorY:-1,pendingScreen:'',TrayMenu:{requestedScreen:''},Hyprland:{focusedMonitor:{name:'DP-1'}},closeAll(){}});
 for(const name of ['toggleFrom','activate']) {
  const match=source.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));assert.ok(match,name);vm.runInContext(match[0],ctx);
 }
 const panel={shown:false,open(){this.shown=true;ctx.activate(this)},hide(){this.shown=false}};
 const origin={width:36,height:32,mapToItem(item,x,y){assert.equal(x,18);assert.equal(y,16);return {x:188,y:712}}};
 ctx.toggleFrom(panel,origin,'DP-2');assert.equal(ctx.popupScreen,'DP-2');assert.equal(ctx.popupAnchorY,712);assert.equal(ctx.popupAnchorX,188);assert.equal(ctx.pendingAnchorY,-1);
 ctx.toggleFrom(panel,origin,'DP-1');assert.ok(panel.shown);assert.equal(ctx.popupScreen,'DP-1');
 ctx.toggleFrom(panel,origin,'DP-1');assert.equal(panel.shown,false);
 panel.open();assert.equal(ctx.popupAnchorY,-1);assert.equal(ctx.popupAnchorX,-1);assert.equal(ctx.popupScreen,'DP-1');
});
test('library selection uses desktop-entry identity across reorder, duplicates and removal',()=>{
 const a={id:'org.a.App',name:'Editor'},b={id:'org.b.App',name:'Editor'},shell={name:'Settings',shellAction:'settings'};
 assert.notEqual(apps.identity(a),apps.identity(b));assert.equal(apps.identity(shell),'shell:settings');
 assert.equal(apps.indexFor([b,shell,a],apps.identity(a)),2);
 assert.equal(apps.indexFor([b,shell],apps.identity(a)),0);
 assert.equal(apps.indexFor([],apps.identity(a)),-1);
});
test('actual launcher restores identity after model reset and deliberately resets for a new query',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../quickshell/launcher/AppLauncherContent.qml'),'utf8');
 const ctx=vm.createContext({Library:apps,GridView:{Contain:0},applications:[{id:'b',name:'B'},{id:'a',name:'A'}],selectedId:'desktop:a',results:{currentIndex:0,positionViewAtIndex(){}}});
 for(const name of ['select','restoreSelection','resetSelection','move']) {
  const match=source.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));assert.ok(match,name);vm.runInContext(match[0],ctx);
 }
 ctx.restoreSelection();assert.equal(ctx.results.currentIndex,1);assert.equal(ctx.selectedId,'desktop:a');
 ctx.resetSelection();assert.equal(ctx.results.currentIndex,0);assert.equal(ctx.selectedId,'desktop:b');
 ctx.applications=[];ctx.restoreSelection();assert.equal(ctx.results.currentIndex,-1);assert.equal(ctx.selectedId,'');
});
test('nested tray routing keeps the parent monitor and clears its captured origin when closed',()=>{
 const traySource=fs.readFileSync(path.join(__dirname,'../quickshell/bar/TrayMenu.qml'),'utf8');
 const frameSource=fs.readFileSync(path.join(__dirname,'../quickshell/bar/ShellFrame.qml'),'utf8');
 const tray=vm.createContext({shown:false,requestedScreen:'',stack:[]});
 for(const name of ['openFor','openSubmenu','hide']) {
  const match=traySource.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));assert.ok(match,name);vm.runInContext(match[0],tray);
 }
 tray.openFor({menu:'handle'},320,500,'DP-2');assert.equal(tray.requestedScreen,'DP-2');
 const ctx=vm.createContext({TrayMenu:tray,popupScreen:'',popupAnchorY:-1,popupAnchorX:-1,pendingAnchorX:-1,pendingScreen:'',pendingAnchorY:-1,Hyprland:{focusedMonitor:{name:'DP-1'}},closeAll(){}});
 vm.runInContext(frameSource.match(/    function activate\([^]*?\n    \}/)[0],ctx);ctx.activate(tray);
 assert.equal(ctx.popupScreen,'DP-2');assert.equal(tray.stack[0].y,500);
 tray.openSubmenu('child',580,510,1);assert.equal(tray.requestedScreen,'DP-2');assert.equal(tray.stack.length,2);
 tray.hide();assert.equal(tray.requestedScreen,'');assert.equal(tray.stack.length,0);
 tray.openFor({menu:'fallback'},0,0);ctx.activate(tray);assert.equal(ctx.popupScreen,'DP-1');
});

test('four-edge rail and content bounds agree across landscape, portrait and small screens',()=>{
 for(const [vw,vh] of [[1920,1080],[1080,1920],[640,480],[320,240],[3440,1440]])
 for(const edge of ['left','right','top','bottom']) for(const rail of [36,44,64]) for(const frame of [4,6,10]) {
  const inset=placement.insets(edge,rail,frame),bar=placement.barRect(vw,vh,edge,rail),area=placement.bounds(vw,vh,inset,12);
  assert.equal(inset[edge],rail);
  assert.equal(Object.values(inset).filter(v=>v===rail).length,1);
  assert.ok(bar.x>=0&&bar.y>=0&&bar.x+bar.width<=vw&&bar.y+bar.height<=vh);
  assert.equal(edge==='top'||edge==='bottom'?bar.height:bar.width,rail);
  const w=Math.min(820,area.width),h=Math.min(790,area.height);
  for(const [x,y] of [[-1,-1],[0,0],[vw,vh],[vw/2,vh/2]]) for(const centered of [false,true]) {
   const p=placement.panelPosition(area,w,h,edge,centered,x,y);
   assert.ok(p.x>=area.x&&p.y>=area.y,JSON.stringify({edge,p,area}));
   assert.ok(p.x+w<=vw-inset.right-12&&p.y+h<=vh-inset.bottom-12);
  }
 }
});
test('module panels attach to rail edge and follow the relevant origin axis',()=>{
 for(const edge of ['left','right','top','bottom']) {
  const a=placement.bounds(1920,1080,placement.insets(edge,44,6),12);
  const p=placement.panelPosition(a,300,200,edge,false,900,500);
  if(edge==='left'||edge==='right') {assert.equal(p.y,400);assert.equal(p.x,edge==='left'?a.x:a.x+a.width-300)}
  else {assert.equal(p.x,750);assert.equal(p.y,edge==='top'?a.y:a.y+a.height-200)}
  const centered=placement.panelPosition(a,300,200,edge,true,0,0);
  assert.equal(centered.x,Math.round(a.x+(a.width-300)/2));assert.equal(centered.y,Math.round(a.y+(a.height-200)/2));
 }
});
const workspace=load('quickshell/workspaces/WorkspaceState.js');
test('workspace overview includes twelve open spaces, named/special spaces and configured empty slots',()=>{
 const open=Array.from({length:12},(_,i)=>({id:i+1}));
 assert.deepEqual(Array.from(workspace.ids(open,5)),Array.from({length:12},(_,i)=>i+1));
 assert.deepEqual(Array.from(workspace.ids([{id:12},{id:12},{id:-1337,name:'Code'},{id:-99,name:'special:scratch'},{id:0},{id:NaN},{id:'8'}],3)),[1,2,3,12,-1337,-99]);
 assert.equal(workspace.nextId([1,2,4,12,-99]),3);
});
test('rail preserves its slot count while exposing focused workspaces outside the configured range',()=>{
 assert.deepEqual(Array.from(workspace.slots(5,12)),[1,2,3,4,12]);
 assert.deepEqual(Array.from(workspace.slots(5,3)),[1,2,3,4,5]);
 assert.deepEqual(Array.from(workspace.slots(1,12)),[12]);
 assert.deepEqual(Array.from(workspace.slots(5,-1337)),[1,2,3,4,-1337]);
 assert.deepEqual(Array.from(workspace.slots(5,0)),[1,2,3,4,5]);
});
test('workspace dispatch validates IDs and exact window addresses, never falling back to activewindow',()=>{
 assert.equal(workspace.focusWorkspace(12),'hl.dsp.focus({ workspace = 12 })');
 assert.equal(workspace.focusWindow('ABC123'),'hl.dsp.focus({ window = "address:0xabc123" })');
 assert.equal(workspace.moveWindow('0xABC123',12),'hl.dsp.window.move({ window = "address:0xabc123", workspace = 12, follow = false })');
 for(const bad of [0,-1,NaN,Infinity,1.5,2147483648,'12','1 }); os.execute("bad")']) {
  assert.equal(workspace.focusWorkspace(bad),'');assert.equal(workspace.moveWindow('abc',bad),'');
 }
 for(const bad of ['',null,'0','0x000','activewindow','class:firefox','abc" }); bad()', 'a'.repeat(17)]) {
  assert.equal(workspace.focusWindow(bad),'');assert.equal(workspace.moveWindow(bad,3),'');
 }
});
test('named and special workspace selectors are escaped Lua literals, including control characters',()=>{
 const list=[{id:-1337,name:'Code "two"\\desk\n9'},{id:-99,name:'special:scratch'},{id:-98,name:'special'}];
 assert.equal(workspace.focusWorkspace(-1337,list),'hl.dsp.focus({ workspace = "name:Code \\"two\\"\\\\desk\\0109" })');
 assert.equal(workspace.focusWorkspace(-99,list),'hl.dsp.workspace.toggle_special("scratch")');
 assert.equal(workspace.focusWorkspace(-98,list),'hl.dsp.workspace.toggle_special("")');
 assert.equal(workspace.moveWindow('abc',-99,list),'hl.dsp.window.move({ window = "address:0xabc", workspace = "special:scratch", follow = false })');
 assert.equal(workspace.luaString('日本語\u00001'),'"日本語\\0001"');
});
test('actual quick-strip scrubber jumps through 1000 images without applying, and handles empty collections',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../quickshell/wallpaper/QuickWallpapersContent.qml'),'utf8');
 const collections=load('quickshell/common/CollectionState.js');const positioned=[];
 const ctx=vm.createContext({CollectionState:collections,ListView:{Center:1},selectedPath:'',WallpaperBackend:{wallpapers:Array.from({length:1000},(_,i)=>({path:`/${i}.png`}))},carousel:{count:1000,currentIndex:0,userScrolling:true,cancelFlick(){},positionViewAtIndex(i){positioned.push(i)}}});
 vm.runInContext(source.match(/    function scrubTo\([^]*?\n    \}/)[0],ctx);
 ctx.scrubTo(950);assert.equal(ctx.selectedPath,'/950.png');assert.equal(ctx.carousel.userScrolling,false);assert.equal(positioned.at(-1),950);
 ctx.scrubTo(2000);assert.equal(ctx.selectedPath,'/999.png');ctx.scrubTo(-10);assert.equal(ctx.selectedPath,'/0.png');
 ctx.carousel.count=0;ctx.WallpaperBackend.wallpapers=[];ctx.scrubTo(0);assert.equal(ctx.carousel.currentIndex,-1);
});
test('actual workspace move rejects vanished windows and preview mode',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../quickshell/workspaces/WorkspacePanelContent.qml'),'utf8');const dispatched=[];
 const ctx=vm.createContext({State:workspace,Settings:{previewMode:false},selectedId:1,movingAddress:'abc',Hyprland:{workspaces:{values:[{id:12}]},toplevels:{values:[{address:'abc'}]},dispatch(c){dispatched.push(c)},refreshToplevels(){}}});
 vm.runInContext(source.match(/    function select\([^]*?\n    \}/)[0],ctx);
 ctx.select(12);assert.equal(dispatched.length,1);assert.equal(ctx.selectedId,12);assert.equal(ctx.movingAddress,'');
 ctx.movingAddress='abc';ctx.Settings.previewMode=true;ctx.select(3);assert.equal(dispatched.length,1);
 ctx.movingAddress='abc';ctx.Settings.previewMode=false;ctx.Hyprland.toplevels.values=[];ctx.select(4);assert.equal(dispatched.length,1);assert.equal(ctx.movingAddress,'');
});

test('actual wallpaper navigation handlers handle Home/End/Page keys without applying',()=>{
 const Qt={Key_PageUp:1,Key_PageDown:2,Key_Home:3,Key_End:4,Key_Tab:5,Key_Escape:6};
 for(const [file,expected] of [
  ['QuickWallpapersContent.qml', [['scrubTo',40],['scrubTo',60],['scrubTo',0],['scrubTo',999]]],
  ['WallpaperLauncherContent.qml', [['move',-8],['move',8],['select',0],['select',999]]],
 ]) {
  const calls=[];const ctx=vm.createContext({Qt,carousel:{currentIndex:50,count:1000},gallery:{columns:4,count:1000},root:{scrubTo(i){calls.push(['scrubTo',i])},move(i){calls.push(['move',i])},select(i){calls.push(['select',i])}}});
  const source=fs.readFileSync(path.join(__dirname,'../quickshell/wallpaper',file),'utf8');
  const handler=source.match(/        Keys\.onPressed: (event => \{[^]*?\n        \})/);assert.ok(handler,file);
  vm.runInContext('var handle = '+handler[1],ctx);
  for(const key of [Qt.Key_PageUp,Qt.Key_PageDown,Qt.Key_Home,Qt.Key_End]) {const event={key,accepted:false};ctx.handle(event);assert.equal(event.accepted,true)}
  assert.deepEqual(calls,expected);
  for(const key of [Qt.Key_Tab,Qt.Key_Escape,999]) {const event={key,accepted:true};ctx.handle(event);assert.equal(event.accepted,false)}
  assert.equal(calls.length,4);
  ctx.carousel.count=0;ctx.gallery.count=0;ctx.handle({key:Qt.Key_End});assert.equal(calls.at(-1)[1],-1);
 }
});
