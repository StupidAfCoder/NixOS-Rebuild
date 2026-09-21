// Exercises the actual QML JavaScript job transitions with inert process objects.
// No desktop commands run; this does not replace Quickshell runtime validation.
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const source=fs.readFileSync(path.join(__dirname,'../quickshell/wallpaper/WallpaperBackend.qml'),'utf8');
function harness() {
 const events=[];
 const ctx=vm.createContext({
  Settings:{previewMode:false,repo:'/repo/',themeRoot:'/private/'},
  previewRevision:0,previewColors:{accent:'#old'},previewError:'old error',previewResult:'',pendingPreview:null,
  previewProc:{running:false,revision:-1},previewApply:{running:false},applyProc:{running:false},appColors:{running:false},trashProc:{running:false},
  applying:false,tryingColors:false,syncingApps:false,trashing:false,
  actionError:'untouched action error',scanError:'untouched scan error',appSyncMessage:'',
  previewDelay:{restart(){events.push('delay')},stop(){events.push('stop')}},
  wallpaperTrashed(p){events.push(['trashed',p])},refresh(){events.push('refresh')}
 });
 for(const name of ['argumentsFor','preview','runPreview','cancelPreview','finishPreview','tryColors','apply','syncLiveApps','trash','finishTrash']) {
  const match=source.match(new RegExp('    function '+name+'\\([^]*?\\n    \\}'));
  assert.ok(match,name);vm.runInContext(match[0],ctx);
 }
 return {ctx,events};
}
const args=p=>[p,'balanced',0,1,'representative',0];
const palette=JSON.stringify({background:'#101110',surface_container:'#181918',outline:'#888888',accent:'#bbddaa',on_surface:'#eeeeee'});
test('preview queue publishes only the newest request, never the old in-flight palette',()=>{
 const {ctx}=harness();ctx.preview(...args('/first'));ctx.runPreview();const first=ctx.previewProc.revision;
 ctx.preview(...args('/second'));ctx.preview(...args('/latest'));
 assert.equal(ctx.previewProc.command[2],'/first');assert.equal(ctx.pendingPreview[2],'/latest');
 ctx.finishPreview(0,first,palette);assert.equal(Object.keys(ctx.previewColors).length,0);
 ctx.previewProc.running=false;ctx.runPreview();assert.equal(ctx.previewProc.command[2],'/latest');
 ctx.finishPreview(0,ctx.previewProc.revision,palette);assert.equal(ctx.previewColors.accent,'#bbddaa');
 assert.equal(ctx.actionError,'untouched action error');assert.equal(ctx.scanError,'untouched scan error');
});
test('clearing or closing cancels queued publication, without stopping an apply or a running read',()=>{
 const {ctx,events}=harness();ctx.preview(...args('/image'));ctx.runPreview();const revision=ctx.previewProc.revision;
 ctx.preview(...args('/queued'));ctx.previewApply.running=true;ctx.cancelPreview();
 assert.equal(ctx.pendingPreview,null);assert.equal(events.at(-1),'stop');
 assert.equal(ctx.previewApply.running,true);assert.equal(ctx.previewProc.running,true);
 ctx.finishPreview(0,revision,palette);ctx.finishPreview(1,revision,'');
 assert.equal(Object.keys(ctx.previewColors).length,0);assert.equal(ctx.previewError,'');
 ctx.previewProc.running=false;ctx.runPreview();assert.equal(ctx.previewProc.running,false);
 ctx.preview(...args(''));assert.equal(ctx.pendingPreview,null);
});
test('newest palette rejects null, arrays, incomplete roles, invalid colors and malformed output',()=>{
 for(const output of ['null','[]','{}','{"accent":"red"}','bad json',palette.replace('#eeeeee','not-a-color')]) {
  const {ctx}=harness();ctx.preview(...args('/image'));ctx.runPreview();ctx.finishPreview(0,ctx.previewProc.revision,output);
  assert.equal(Object.keys(ctx.previewColors).length,0);assert.equal(ctx.previewError,'Preview was not valid');
 }
 const {ctx}=harness();ctx.preview(...args('/image'));ctx.runPreview();ctx.finishPreview(1,ctx.previewProc.revision,'');
 assert.equal(ctx.previewError,'No preview available for this image');
});
test('Trash is blocked during apply, private try, live sync, other Trash and native preview',()=>{
 for(const flag of ['applying','tryingColors','syncingApps','trashing']) {
  const {ctx}=harness();ctx[flag]=true;ctx.trash('/keep.png');assert.equal(ctx.trashProc.running,false,flag);
 }
 const {ctx}=harness();ctx.Settings.previewMode=true;ctx.trash('/keep.png');
 assert.equal(ctx.trashProc.running,false);assert.match(ctx.actionError,/disabled/);
 ctx.Settings.previewMode=false;ctx.trash('');assert.equal(ctx.trashProc.running,false);
});
test('every mutating job is blocked while Trash owns its captured path',()=>{
 const {ctx}=harness();ctx.trashing=true;ctx.apply(...args('/image'));ctx.syncLiveApps('/image');
 ctx.Settings.previewMode=true;ctx.tryColors(...args('/image'));
 assert.equal(ctx.applyProc.running,false);assert.equal(ctx.appColors.running,false);assert.equal(ctx.previewApply.running,false);
});
test('Trash reports success only after exit, and failure does not signal removal',()=>{
 const {ctx,events}=harness();ctx.trash('/path with spaces.png');
 assert.deepEqual(Array.from(ctx.trashProc.command),['gio','trash','--','/path with spaces.png']);
 assert.equal(ctx.trashProc.wallpaperPath,'/path with spaces.png');assert.deepEqual(events,[]);
 ctx.finishTrash(1,ctx.trashProc.wallpaperPath);assert.deepEqual(events,['refresh']);assert.match(ctx.actionError,/Could not/);
 events.length=0;ctx.finishTrash(0,ctx.trashProc.wallpaperPath);
 assert.deepEqual(events,[['trashed','/path with spaces.png'],'refresh']);assert.equal(ctx.actionError,'');
});
test('actual editor completion handler clears only the successfully removed selection',()=>{
 const editor=fs.readFileSync(path.join(__dirname,'../quickshell/wallpaper/WallpaperLauncherContent.qml'),'utf8');
 const handler=editor.match(/function onWallpaperTrashed\(path\) \{[^\n]+\}/);assert.ok(handler);
 const view=vm.createContext({root:{selectedPath:'/new.png'}});vm.runInContext(handler[0],view);
 view.onWallpaperTrashed('/old.png');assert.equal(view.root.selectedPath,'/new.png');
 view.onWallpaperTrashed('/new.png');assert.equal(view.root.selectedPath,'');
});
