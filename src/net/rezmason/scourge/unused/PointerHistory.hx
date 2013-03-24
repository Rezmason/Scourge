package net.rezmason.scourge.unused;

import haxe.ds.IntMap;

using Lambda;

typedef Diff<T> = IntMap<Change<T>>;

class PointerHistory<T> {

    private var diffs:Array<Diff<T>>;
    private var firstDiff:Diff<T>;
    private var pointers:Array<Pointer<T>>;
    private var oldValues:IntMap<T>;

    public var revision(default, null):Int;

    public function new():Void {
        diffs = []; // there's always the first one
        pointers = [];
        revision = 0;
        wipe();
    }

    public function wipe():Void {
        diffs.splice(0, revision + 1);
        firstDiff = new Diff<T>();
        diffs[0] = firstDiff;

        revision = 0;

        pointers.splice(0, pointers.length);
        oldValues = new IntMap<T>();
    }

    public function reset():Void {
        for (pointer in findChangedPointers()) pointer.value = oldValues.get(pointer.id);
    }

    public function revert(goalRev:Int):Void {

        if (goalRev == revision) return;

        if (goalRev < 0 || goalRev > revision) {
            throw "Invalid revision " + goalRev + " falls out of range 0-" + revision;
        }

        #if SAFE_HISTORY
            if (findChangedPointers().length > 0) throw "Uncommitted changes";
        #end

        var combinedChanges:Diff<T> = new Diff<T>();
        var combinedChangeRevs:IntMap<Int> = new IntMap<Int>();
        while (revision > goalRev) {
            var diff:Diff<T> = diffs[revision];
            for (change in diff) {
                var id:Int = change.pointer.id;
                combinedChanges.set(id, change);
                combinedChangeRevs.set(id, revision);
            }
            diffs[revision] = null;
            revision--;
        }

        for (id in combinedChanges.keys()) {
            var change:Change<T> = combinedChanges.get(id);
            var lateChange:Bool = combinedChangeRevs.get(id) != goalRev;
            var value:T = lateChange ? change.oldValue : change.newValue;
            change.pointer.value = value;
            oldValues.set(id, value);
        }

        revision = goalRev;
    }

    public function commit():Int {

        var changedPointers:Array<Pointer<T>> = findChangedPointers();

        if (changedPointers.length > 0) {
            revision++;

            var diff:Diff<T> = new Diff<T>();
            for (pointer in changedPointers) {
                var id:Int = pointer.id;
                diff.set(id, new Change<T>(pointer, oldValues.get(id)));
                oldValues.set(id, pointer.value);
            }
            diffs[revision] = diff;
        }

        return revision;
    }

    public function add(pointer:Pointer<T>):Void {
        if (pointers.has(pointer)) return;
        oldValues.set(pointer.id, pointer.value);
        firstDiff.set(pointer.id, new Change<T>(pointer, pointer.value));
        pointers.push(pointer);
    }

    private function findChangedPointers():Array<Pointer<T>> {
        var currentDiff:Diff<T> = diffs[revision];
        var changedPointers:Array<Pointer<T>> = [];
        for (pointer in pointers) if (oldValues.get(pointer.id) != pointer.value) changedPointers.push(pointer);
        return changedPointers;
    }
}

class Change<T> {
    public var pointer:Pointer<T>;
    public var oldValue:T;
    public var newValue:T;

    public function new(pointer:Pointer<T>, oldValue:T):Void {
        this.pointer = pointer;
        this.oldValue = oldValue;
        newValue = pointer.value;
    }
}
