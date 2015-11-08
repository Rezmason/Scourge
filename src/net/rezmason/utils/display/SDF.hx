package net.rezmason.utils.display;

import Math.*;
import Std.int;
import haxe.io.Bytes;
import lime.graphics.Image;

class Datum {
    public var dx:Float;
    public var dy:Float;
    public var rad2:Float;
    public var row:Int;
    public var col:Int;
    public var pending:Bool;
    public var side:Int;

    public function new():Void {}

    public function pop(row, col, dx, dy, rad2, pending, side):Void {
        this.dx = dx;
        this.dy = dy;
        this.rad2 = rad2;
        this.row = row;
        this.col = col;
        this.pending = pending;
        this.side = side;
    }
}

class SDF {

    var pendingData:Array<Datum>;
    var dataMatrix:Array<Array<Datum>>;
    var innerData:Array<Datum>;
    var allData:Array<Datum>;
    var source:Image;
    var w:Int;
    var h:Int;
    var cutoff:Int;
    public var output(default, null):Image;

    public function new(source:Image, cutoff:Int):Void {

        this.cutoff = cutoff;

        dataMatrix = [];
        allData = [];
        innerData = [];
        pendingData = [];

        w = source.width;
        h = source.height;

        // Build the matrix and initialize the propagation algo
        for (row in 0...h) {
            dataMatrix[row] = new Array();
            for (col in 0...w) {
                var datum:Datum = new Datum();
                if (source.getPixel32(col, row) & 0xFF00 > 0xF000) {
                    datum.pop(row, col, 0, 0, 0, true, -1);
                    pendingData.push(datum);
                    innerData.push(datum);
                } else {
                    datum.pop(row, col, NaN, NaN, NaN, false, 1);
                }
                dataMatrix[row][col] = datum;
                allData.push(datum);
            }
        }

        // Compute the distances of outer cells
        findPendingDistances();

        // Find the inner data that aren't on a boundary
        for (datum in innerData) {
            var neighborSum:Float = 0;
            for (neighbor in neighborsFor(datum)) neighborSum += neighbor.rad2;
            if (neighborSum != 0) {
                pendingData.push(datum);
                datum.pending = true;
            }
        }

        // ...and then remove their distances
        for (datum in innerData) {
            datum.rad2 = NaN;
            datum.dx = NaN;
            datum.dy = NaN;
        }

        // ...and recompute them.
        findPendingDistances();

        output = new Image(null, 0, 0, w, h, 0xFF);

        for (datum in allData) {
            var distance:Float = datum.side;
            if (!isNaN(datum.rad2)) distance *= sqrt(datum.rad2) / cutoff;
            var val:Int = int(distance * 0x80 + 0x7F);
            if (val < 0x00) val = 0x00;
            if (val > 0xFF) val = 0xFF;
            output.setPixel32(datum.col, datum.row, 0xFF | (val << 8));
        }
    }

    function neighborsFor(datum:Datum):Array<Datum> {
        var neighbors:Array<Datum> = new Array();

        var row:Int = datum.row;
        var col:Int = datum.col;

        var left:Bool = col > 0;
        var right:Bool = col < w - 1;
        var up:Bool = row > 0;
        var down:Bool = row < h - 1;

        if (left) neighbors.push(dataMatrix[row][col - 1]);
        if (right) neighbors.push(dataMatrix[row][col + 1]);
        if (up) neighbors.push(dataMatrix[row - 1][col]);
        if (down) neighbors.push(dataMatrix[row + 1][col]);

        if (left && up) neighbors.push(dataMatrix[row - 1][col - 1]);
        if (right && up) neighbors.push(dataMatrix[row - 1][col + 1]);
        if (left && down) neighbors.push(dataMatrix[row + 1][col - 1]);
        if (right && down) neighbors.push(dataMatrix[row + 1][col + 1]);

        return neighbors;
    }

    function findPendingDistances():Void {
        var datum:Datum;
        while ((datum = pendingData.shift()) != null) {
            datum.pending = false;

            var row:Int = datum.row;
            var col:Int = datum.col;

            var newNeighbors:Array<Datum> = new Array();

            for (neighbor in neighborsFor(datum)) {
                if (isNaN(neighbor.rad2) && !neighbor.pending) {
                    newNeighbors.push(neighbor);
                } else {
                    var dx:Float = neighbor.dx + (neighbor.col - col);
                    var dy:Float = neighbor.dy + (neighbor.row - row);
                    var rad2:Float = dx * dx + dy * dy;
                    if (isNaN(datum.rad2) || rad2 < datum.rad2) {
                        datum.dx = dx;
                        datum.dy = dy;
                        datum.rad2 = rad2;
                    }
                }
            }

            if (datum.rad2 <= cutoff * cutoff) {
                for (neighbor in newNeighbors) {
                    pendingData.push(neighbor);
                    neighbor.pending = true;
                }
            }
        }
    }
}
