package net.rezmason.scourge.model;

using net.rezmason.utils.Pointers;

class History<T> {

    public var length(default, null):Int;
    public var revision(default, null):Int;

    private var array:Array<T>;
    private var oldArray:Array<T>;
    private var changeCount:Int;
    private var fullChanges:Array<Array<T>>;
    private var incrementalChanges:Array<IntHash<T>>;

    public function new():Void {
        length = 0;
        revision = 0;
        changeCount = 0;
        array = [];
        oldArray = [];
        incrementalChanges = [];
        fullChanges = [[]];
    }

    public function wipe():Void {
        revert(0);
        array.splice(0, length);
        oldArray.splice(0, length);
        length = 0;
        changeCount = 0;
    }

    public function forget():Void {
        incrementalChanges.splice(0, revision + 1);
        fullChanges.splice(0, revision + 1);
        for (ike in 0...length) oldArray[ike] = array[ike];
        fullChanges[0] = array.copy();
        revision = 0;
        changeCount = 0;
    }

    public function reset():Void {
        for (ike in 0...length) if (array[ike] != oldArray[ike]) array[ike] = oldArray[ike];
    }

    public function revert(goalRev:Int):Void {

        if (goalRev < 0 || goalRev > revision) {
            throw "Invalid revision " + goalRev + " falls out of range 0-" + revision;
        }

        if (goalRev == revision) {
            reset();
        } else {
            var fullRev:Int = goalRev;
            while (fullChanges[fullRev] == null) fullRev--;
            var fullChange:Array<T> = fullChanges[fullRev];
            for (ike in 0...length) array[ike] = oldArray[ike] = fullChange[ike];
            if (goalRev > fullRev) {
                var incrRev:Int = fullRev + 1;
                for (ike in incrRev...goalRev + 1) {
                    var incrementalChange:IntHash<T> = incrementalChanges[ike];
                    for (key in incrementalChange.keys()) {
                        array[key] = oldArray[key] = incrementalChange.get(key);
                    }
                }
            }
            var deadRev:Int = goalRev + 1;
            fullChanges.splice(deadRev, revision - deadRev + 1);
            incrementalChanges.splice(deadRev, revision - deadRev + 1);
            revision = goalRev;
        }
    }

    public function commit():Int {

        revision++;

        // heuristic
        if (changeCount > length) {
            changeCount = 0;
            fullChanges[revision] = array.copy();
        } else {
            var hash:IntHash<T> = new IntHash<T>();
            for (ike in 0...length) {
                if (oldArray[ike] != array[ike]) {
                    hash.set(ike, array[ike]);
                    oldArray[ike] = array[ike];
                    changeCount++;
                }
            }
            incrementalChanges[revision] = hash;
        }

        return revision;
    }

    public inline function alloc(val:Null<T>):Ptr<T> {
        array[length] = val;
        return array.ptr(length++);
    }

    public inline function get(ptr:Ptr<T>):Null<T> {
        if (length == 0) throw "Invalid get : no data allocated";
        return ptr.dref(array);
    }

    public inline function set(ptr:Ptr<T>, val:Null<T>):Null<T> {
        if (length == 0) throw "Invalid set : no data allocated";
        return ptr.mod(array, val);
    }
}
