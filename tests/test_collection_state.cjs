const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const root=path.join(__dirname,'..');
const state=vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(root,'quickshell/common/CollectionState.js'),'utf8').replace(/^\.pragma library\s*/,''),state);
test('selection survives reordering and falls back to the applied image after removal',()=>{
 const items=[{path:'/c'},{path:'/b'},{path:'/a'}];
 assert.equal(state.indexFor(items,'/a','/b'),2);
 assert.equal(state.indexFor(items,'/gone','/b'),1);
 assert.equal(state.indexFor(items,'/gone','/also-gone'),0);
 assert.equal(state.indexFor([], '/a','/b'),-1);
});
test('keyboard selection is bounded, including an empty collection',()=>{
 assert.equal(state.boundedIndex(0,0),-1);
 assert.equal(state.boundedIndex(3,-2),0);
 assert.equal(state.boundedIndex(3,50),2);
});
test('picker parent paths preserve root, spaces and literal percent characters',()=>{
 assert.equal(state.parentPath('/portrait.png','/home/user'),'/');
 assert.equal(state.parentPath('/','/home/user'),'/');
 assert.equal(state.parentPath('/home/user/100% photos/a b.png','/home/user'),'/home/user/100% photos');
 assert.equal(state.parentPath('','/home/user'),'/home/user');
 assert.equal(state.parentPath('relative.png','/home/user'),'/home/user');
});
function qmlFunction(source,name) {
 const match=source.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));
 assert.ok(match,name);return match[0];
}
test('actual QML scan queue coalesces requests without changing the running process',()=>{
 const source=fs.readFileSync(path.join(root,'quickshell/wallpaper/WallpaperBackend.qml'),'utf8');
 // refresh is one-line, runScan is extracted from the actual QML implementation.
 const ctx=vm.createContext({scan:{running:true,directory:'/old',output:'old data',errorOutput:'old error'},Settings:{wallpaperDir:'/new'},rescanRequested:true,scanning:true,scanError:'old error'});
 vm.runInContext(qmlFunction(source,'runScan'),ctx);ctx.runScan();
 assert.equal(ctx.scan.directory,'/old');assert.equal(ctx.rescanRequested,true);
 ctx.Settings.wallpaperDir='/newest';ctx.scan.running=false;ctx.runScan();
 assert.equal(ctx.scan.directory,'/newest');assert.equal(ctx.rescanRequested,false);
 assert.equal(ctx.scan.output,'');assert.equal(ctx.scan.running,true);
});
test('actual QML apply function defers settings persistence and blocks competing syncs',()=>{
 const source=fs.readFileSync(path.join(root,'quickshell/wallpaper/WallpaperBackend.qml'),'utf8');
 const writes=[];const ctx=vm.createContext({Settings:{previewMode:false,repo:'/checkout/',patch:p=>writes.push(p)},applyProc:{running:false},applying:false,tryingColors:false,syncingApps:true,actionError:''});
 vm.runInContext(qmlFunction(source,'apply'),ctx);
 ctx.apply('/image','wallpaper',0,1,'representative',0);assert.equal(ctx.applyProc.running,false);
 ctx.syncingApps=false;ctx.apply('/image','wallpaper',0,1,'representative',0);
 assert.equal(ctx.applyProc.running,true);assert.equal(ctx.applyProc.settingsPatch.recipe,'wallpaper');assert.equal(writes.length,0);
});
test('actual picker arrows preview the current file and clear stale file selection on a folder',()=>{
 const source=fs.readFileSync(path.join(root,'quickshell/common/PathPicker.qml'),'utf8');
 const ctx=vm.createContext({CollectionState:state,FolderListModel:{Ready:1},GridView:{Contain:0},files:{status:1,count:3,isFolder:i=>i===0,get:i=>['/folder','/a.png','/b.png'][i]},list:{currentIndex:0,positionViewAtIndex(){}},selectedPath:''});
 vm.runInContext(qmlFunction(source,'move'),ctx);
 ctx.move(1);assert.equal(ctx.selectedPath,'/a.png');ctx.move(1);assert.equal(ctx.selectedPath,'/b.png');
 ctx.move(-2);assert.equal(ctx.selectedPath,'');assert.equal(ctx.list.currentIndex,0);
 ctx.files.status=0;ctx.move(2);assert.equal(ctx.list.currentIndex,0);
});
