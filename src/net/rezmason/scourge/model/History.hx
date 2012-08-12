package net.rezmason.scourge.model;

typedef Changeset<T> = IntHash<Change<T>>;

using Lambda;

class History<T> {

    private var changesets:Array<Changeset<T>>;
    private var firstChangeset:Changeset<T>;
    private var records:Array<Record<T>>;
    private var oldValues:IntHash<T>;

    public var revision(default, null):Int;

    public function new():Void {
        changesets = []; // there's always the first one
        records = [];
        revision = 0;
        wipe();
    }

    public function wipe():Void {
        changesets.splice(0, revision + 1);
        firstChangeset = new Changeset<T>();
        changesets[0] = firstChangeset;

        revision = 0;

        records.splice(0, records.length);
        oldValues = new IntHash<T>();
    }

    public function reset():Void {
        for (record in findChangedRecords()) record.value = oldValues.get(record.id);
    }

    public function revert(goalRev:Int):Void {

        if (goalRev == revision) return;

        if (goalRev < 0 || goalRev > revision) {
            throw "Invalid revision " + goalRev + " falls out of range 0-" + revision;
        }

        #if SAFE_HISTORY
            if (findChangedRecords().length > 0) throw "Uncommitted changes";
        #end

        var combinedChanges:Changeset<T> = new Changeset<T>();
        var combinedChangeRevs:IntHash<Int> = new IntHash<Int>();
        while (revision >= goalRev) {
            var changeset:Changeset<T> = changesets[revision];
            for (change in changeset) {
                var id:Int = change.record.id;
                combinedChanges.set(id, change);
                combinedChangeRevs.set(id, revision);
            }
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

        var changedRecords:Array<Record<T>> = findChangedRecords();

        if (changedRecords.length > 0) {
            revision++;

            var changeset:Changeset<T> = new Changeset<T>();
            for (record in changedRecords) {
                var id:Int = record.id;
                changeset.set(id, new Change<T>(record, oldValues.get(id)));
                oldValues.set(id, record.value);
            }
            changesets[revision] = changeset;
        }

        return revision;
    }

    public function add(record:Record<T>):Void {
        if (records.has(record)) return;
        oldValues.set(record.id, record.value);
        firstChangeset.set(record.id, new Change<T>(record, record.value));
        records.push(record);
    }

    private function findChangedRecords():Array<Record<T>> {
        var currentChangeset:Changeset<T> = changesets[revision];
        var changedRecords:Array<Record<T>> = [];
        for (record in records) if (oldValues.get(record.id) != record.value) changedRecords.push(record);
        return changedRecords;
    }
}

class Change<T> {
    public var record:Record<T>;
    public var oldValue:T;
    public var newValue:T;

    public function new(record:Record<T>, oldValue:T):Void {
        this.record = record;
        this.oldValue = oldValue;
        newValue = record.value;
    }
}
