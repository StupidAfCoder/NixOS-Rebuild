// Run with Node >=18. Exercises the actual pure QML JavaScript, not a copy.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
function library(relative) {
    const context = vm.createContext({});
    vm.runInContext(fs.readFileSync(path.join(root, relative), 'utf8').replace(/^\.pragma library\s*/, ''), context);
    return context;
}
const m = library('quickshell/wellbeing/UsageMath.js');
const modules = library('quickshell/common/ModuleCatalog.js');
const plain = value => JSON.parse(JSON.stringify(value));
test('local dates survive leap day, month/year boundaries and invalid input', () => {
    for (const day of ['2024-02-29', '2026-09-21', '2025-12-31']) assert.equal(m.key(m.dateFor(day)), day);
    for (const day of ['2026-02-29', '2026-09-31', '2026-9-1', 'invalid', null]) assert.equal(m.dateFor(day), null);
    const result = m.series({}, '2026-01-03', 7);
    assert.equal(result[0].day, '2025-12-28'); assert.equal(result.at(-1).day, '2026-01-03');
});
test('sanitize corrupt values, preserve explicitly recorded zero and reject dangerous keys', () => {
    const input = JSON.parse('{"2026-09-21":{"firefox":120,"bad":"42","__proto__":5,"constructor":8,"negative":-1,"huge":86401},"2026-09-20":{},"2026-09-31":{},"bad":{},"2026-09-19":[]}');
    input['2026-09-21'].infinite = Infinity;
    assert.deepEqual(plain(m.sanitizeDays(input)), {'2026-09-21': {firefox:120}, '2026-09-20': {}});
});
test('7/14/30-day series distinguish missing from recorded zero', () => {
    const days = {'2026-09-20': {}, '2026-09-21': {foot: 120, firefox: 180}};
    for (const count of [7,14,30]) {
        const result = m.series(days, '2026-09-21', count);
        assert.equal(result.length, count);
        assert.equal(result.at(-1).seconds, 300);
        assert.equal(result.at(-2).recorded, true);
        assert.equal(result.at(-2).seconds, 0);
        assert.equal(result.at(-3).recorded, false);
    }
    assert.equal(m.series({}, 'bad', 7).length, 0);
    assert.equal(m.series({}, '2026-09-21', 8).length, 0);
});
test('fixed heat thresholds and readable durations', () => {
    assert.deepEqual([0,1,3600,3601,7200,7201,14400,14401].map(s => m.heatLevel(s,240)), [0,1,1,2,2,3,3,4]);
    assert.equal(m.duration(0), '0m'); assert.equal(m.duration(30), '<1m'); assert.equal(m.duration(3660), '1h 1m');
});
test('ranking aggregates range, reverses order, computes shares, handles prototype-named app', () => {
    const days = {'2026-09-20': {firefox:60, foot:120, toString:30}, '2026-09-21': {firefox:90, foot:30, zero:0}};
    const ranking = m.ranking(days, Object.keys(days), true);
    assert.deepEqual(plain(ranking.map(x => [x.app,x.seconds])), [['firefox',150],['foot',150],['toString',30]]);
    assert.ok(Math.abs(ranking.reduce((n,x) => n+x.share,0)-1) < 1e-9);
    assert.equal(m.ranking(days, Object.keys(days), false)[0].app, 'toString');
    assert.equal(m.ranking(days, ['2026-09-22'], true).length, 0);
});
test('every module has a unique key and a real bundled icon; defaults match Python', () => {
    const entries = modules.entries();
    assert.equal(entries.length, 12);
    assert.equal(new Set(entries.map(x => x.key)).size, 12);
    const source = fs.readFileSync(path.join(root, 'scripts/shell-state.py'),'utf8');
    const pythonKeys = source.match(/BAR_MODULES = \(([^\n]+)\)/)[1].match(/"[^"]+"/g).map(x => JSON.parse(x));
    assert.deepEqual(plain(entries.map(x=>x.key)), pythonKeys);
    for (const entry of entries) {
        assert.equal(modules.defaults()[entry.key], true);
        assert.ok(fs.existsSync(path.join(root, 'quickshell/bar/assets/icons',entry.icon)), entry.icon);
    }
});
test('actual settings merge overlays optimistic patches without dropping sibling modules', () => {
    const source = fs.readFileSync(path.join(root,'quickshell/common/Settings.qml'),'utf8');
    const match = source.match(/function merge\(base, changes\) \{[\s\S]*?\n    \}/);
    assert.ok(match);
    const ctx=vm.createContext({}); vm.runInContext(match[0],ctx);
    const persisted={barModules:{wizard:true,clock:true},frameWidth:6};
    const inFlight={barModules:{clock:false},frameWidth:8};
    const pending={barModules:{wizard:false},frameWidth:10};
    assert.deepEqual(plain(ctx.merge(ctx.merge(persisted,inFlight),pending)),{barModules:{wizard:false,clock:false},frameWidth:10});
    assert.equal(persisted.barModules.clock,true);
    assert.equal(inFlight.frameWidth,8);
});
