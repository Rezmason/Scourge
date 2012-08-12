package net.rezmason.scourge.model;

typedef Changeset<T> = IntHash<Change<T>>;

class History<T> {

    private var changesets:Array<Changeset<T>>;
    private var records:Array<Record<T>>;

    public var currentRev(default, null):Int;
    public var latestRev(default, null):Int;

    public function new():Void {
        changesets = [new Changeset<T>()]; // there's always the first one
        records = [];
        latestRev = 0;
        wipe();
    }

    public function wipe():Void {
        currentRev = 0;
        cut();
        changesets[0] = new Changeset<T>();
        records.splice(0, records.length);
    }

    public function reset():Void {
        var currentChangeset:Changeset<T> = changesets[currentRev];
        var changedRecords:Array<Record<T>> = findChangedRecords();
        for (record in changedRecords) record.value = record.oldValue;
    }

    public function revert(goalRev:Int):Void {
        if (goalRev == currentRev) return;

        if (goalRev < 0 || goalRev > latestRev) {
            throw "Invalid revision " + goalRev + " falls out of range 0-" + latestRev;
        }

        #if SAFE_HISTORY
            if (recordsHaveChanged()) throw "Uncommitted changes"
        #end

        var backwards:Bool = goalRev < currentRev;

        var earliestRev:Int = backwards ? goalRev : currentRev;
        var latestRev:Int = backwards ? currentRev : goalRev;

        var combinedChanges:Changeset<T> = new Changeset<T>();
        var combinedChangeRevs:IntHash<Int> = new IntHash<Int>();
        for (rev in earliestRev...latestRev + 1) {
            var changeset:Changeset<T> = changesets[rev];
            for (change in changeset) {
                var id:Int = change.record.id;
                if (backwards && combinedChanges.exists(id)) continue;
                combinedChanges.set(id, change);
                combinedChangeRevs.set(id, rev);
            }
        }

        for (id in combinedChanges.keys()) {
            var change:Change<T> = combinedChanges.get(id);
            var lateChange:Bool = (backwards && combinedChangeRevs.get(id) != goalRev);
            var value:T = lateChange ? change.oldValue : change.newValue;
            change.record.value = value;
            change.record.oldValue = value;
        }
    }

    public function cut():Void {
        if (currentRev == latestRev) return;
        changesets.splice(currentRev + 1, latestRev - currentRev);
        latestRev = currentRev;
    }

    public function commit():Int {

        if (currentRev < latestRev) {
            // Not sure what to do
        }

        currentRev++; // Not sure
        latestRev++;

        var changedRecords:Array<Record<T>> = findChangedRecords();

        if (changedRecords.length > 0) {
            var changeset:Changeset<T> = new Changeset<T>();
            for (record in changedRecords) changeset.set(record.id, new Change<T>(record));
            changesets[latestRev] = changeset;
        }

        return latestRev;
    }

    public function add(record:Record<T>):Void {
        var firstChangeset:Changeset<T> = changesets[0];
        firstChangeset.set(record.id, new Change<T>(record));
    }

    #if SAFE_HISTORY
    private function recordsHaveChanged():Bool { return findChangedRecords().length > 0; }
    #end

    private function findChangedRecords():Array<Record<T>> {
        var currentChangeset:Changeset<T> = changesets[currentRev];
        var changedRecords:Array<Record<T>> = [];
        for (record in records) if (record.oldValue != record.value) changedRecords.push(record);
        return changedRecords;
    }
}

class Change<T> {
    public var record:Record<T>;
    public var oldValue:T;
    public var newValue:T;

    public function new(record:Record<T>):Void {
        this.record = record;
        oldValue = record.oldValue;
        newValue = record.value;
    }
}
