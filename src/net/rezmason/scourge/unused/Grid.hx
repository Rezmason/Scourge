package net.rezmason.scourge.unused;

class Grid<T> {

    public var disposed(default, null):Bool;
    public var width(default, null):Int;
    public var height(default, null):Int;

    private var array:Array<Null<T>>;

    public function new(width:Int, height:Int, generator:Int->Int->T):Void {
        disposed = true;
        if (width  <= 0) throw "Grid does not accept nonpositive values for width.";
        if (height <= 0) throw "Grid does not accept nonpositive values for height.";

        disposed = false;
        this.width = width;
        this.height = height;

        array = [];
        for (row in 0...height) {
            for (column in 0...width) {
                array[row * width + column] = generator(column, row);
            }
        }
    }

    public function spit(printer:T->String):String {
        var str:String = null;
        if (!disposed) {
            str = "";
            for (row in 0...height) {
                for (column in 0...width) {
                    str += printer(array[row * width + column]);
                    str += " ";
                }
                str += "\n";
            }
        }
        return str;
    }

    public function iterator():Iterator<T> {
        return array.iterator();
    }

    public function dispose():Void {
        disposed = true;
        array.splice(0, array.length);
    }

    public function getOrthogonalSlicesForIndex(index:Int):Iterable<GridIterator<T>> {
        return orthoInternal(index);
    }

    public function getDiagonalSlicesForIndex(index:Int):Iterable<GridIterator<T>> {
        return diagInternal(index);
    }

    public function getSlicesForIndex(index:Int):Iterable<GridIterator<T>> {
        return orthoInternal(index).concat(diagInternal(index));
    }

    inline function orthoInternal(index:Int):Array<GridIterator<T>> {
        var x:Int = index % width;
        var y:Int = Std.int(index / width);

        var horizontalSlice:GridIterator<T> = new GridIterator(array, y * width, 1, (y + 1) * width);
        var verticalSlice:GridIterator<T>   = new GridIterator(array, x, width, width * height);
        return [horizontalSlice, verticalSlice];
    }

    inline function diagInternal(index:Int):Array<GridIterator<T>> {
        var x:Int = index % width;
        var y:Int = Std.int(index / width);

        var startUp:Int = (Std.int(index - (Math.min(x, y)) * (width + 1)));
        var stepUp:Int = width + 1;
        var endUp:Int = (Std.int(index + (Math.min(width - x, height - y)) * (width + 1)));

        var startDown:Int = (Std.int(index - (Math.min(width - x - 1, y)) * (width - 1)));
        var stepDown:Int = width - 1;
        var endDown:Int = (Std.int(index + (Math.min(x + 1, height - y)) * (width - 1)));

        var diagonalUpSlice:GridIterator<T> = new GridIterator(array, startUp, stepUp, endUp);
        var diagonalDownSlice:GridIterator<T> = new GridIterator(array, startDown, stepDown, endDown);
        return [diagonalUpSlice, diagonalDownSlice];
    }

}

class GridIterator<T> {
    var arr:Array<T>;
    var start:Int;
    var step:Int;
    var end:Int;

    public function new(arr:Array<T>, start:Int, step:Int, end:Int):Void {
        this.arr = arr;
        this.start = start;
        this.step = step;
        this.end = end;
    }

    public function hasNext():Bool { return start < end; }

    public function next():T {
        var element:T = arr[start];
        start += step;
        return element;
    }
}
