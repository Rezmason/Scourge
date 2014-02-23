package net.rezmason.ds;

class ShitList<T> {

    // A fast FIFO data structure that doesn't give a fuck until you reach its end.

    public var length(get, null):Int;
    var arr:Array<T>;
    var index:Int;

    public function new(it:Iterable<T> = null):Void {
        arr = [];
        if (it != null) for (el in it) arr.push(el);
        index = 0;
    }

    public inline function add(el:T):Void arr.push(el);

    public inline function pop():T {
        var el:T = arr[index];
        index++;
        if (length == 0) {
            index = 0;
            if (arr.length > 0) arr.splice(0, arr.length);
        }
        return el;
    }

    inline function get_length():Int return arr.length - index;

    public function iterator():Iterator<T> {
        var index:Int = this.index;
        function hasNext():Bool return index < arr.length;
        function next():T {
            var el:T = arr[index];
            index++;
            return el;
        }

        return { hasNext:hasNext, next:next };
    }
}
