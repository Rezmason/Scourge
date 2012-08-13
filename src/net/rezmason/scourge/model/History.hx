package net.rezmason.scourge.model;

typedef Diff<T> = IntHash<Change<T>>;

using Lambda;

class History<T> {

    private var diffs:Array<Diff<T>>;
    private var firstDiff:Diff<T>;
    private var records:Array<Pointer<T>>;
    private var oldValues:IntHash<T>;

    public var revision(default, null):Int;

    public function new():Void {
        diffs = []; // there's always the first one
        records = [];
        revision = 0;
        wipe();
    }

    public function wipe():Void {
        diffs.splice(0, revision + 1);
        firstDiff = new Diff<T>();
        diffs[0] = firstDiff;

        revision = 0;

        records.splice(0, records.length);
        oldValues = new IntHash<T>();
    }

    public function reset():Void {
        for (record in findChangedPointers()) record.value = oldValues.get(record.id);
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
        var combinedChangeRevs:IntHash<Int> = new IntHash<Int>();
        while (revision > goalRev) {
            var diff:Diff<T> = diffs[revision];
            for (change in diff) {
                var id:Int = change.record.id;
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
            change.record.value = value;
            oldValues.set(id, value);
        }

        revision = goalRev;
    }

    public function commit():Int {

        var changedPointers:Array<Pointer<T>> = findChangedPointers();

        if (changedPointers.length > 0) {
            revision++;

            var diff:Diff<T> = new Diff<T>();
            for (record in changedPointers) {
                var id:Int = record.id;
                diff.set(id, new Change<T>(record, oldValues.get(id)));
                oldValues.set(id, record.value);
            }
            diffs[revision] = diff;
        }

        return revision;
    }

    public function add(record:Pointer<T>):Void {
        if (records.has(record)) return;
        oldValues.set(record.id, record.value);
        firstDiff.set(record.id, new Change<T>(record, record.value));
        records.push(record);
    }

    private function findChangedPointers():Array<Pointer<T>> {
        var currentDiff:Diff<T> = diffs[revision];
        var changedPointers:Array<Pointer<T>> = [];
        for (record in records) if (oldValues.get(record.id) != record.value) changedPointers.push(record);
        return changedPointers;
    }
}

class Change<T> {
    public var record:Pointer<T>;
    public var oldValue:T;
    public var newValue:T;

    public function new(record:Pointer<T>, oldValue:T):Void {
        this.record = record;
        this.oldValue = oldValue;
        newValue = record.value;
    }
}
