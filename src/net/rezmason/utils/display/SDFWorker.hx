package net.rezmason.utils;

import Math.*;
import Std.int;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.utils.ByteArray;
import flash.Vector;
import haxe.Timer;
import net.rezmason.utils.workers.BasicWorker;

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

typedef SerializedBitmap = {
    var width:Int;
    var height:Int;
    var bytes:ByteArray;
}

typedef Work = {source:SerializedBitmap, cutoff:Int};

class SDFWorker extends BasicWorker<Work, SerializedBitmap> {
    override function receive(data:Work):Void {
        #if debug
            try {
                send(SDF.process(data));
            } catch (error:Dynamic) {
                sendError(error);
            }
        #else
            send(SDF.process(data));
        #end
    }
}

class SDF {

    var pendingData:Vector<Datum>;
    var dataMatrix:Vector<Vector<Datum>>;
    var innerData:Vector<Datum>;
    var allData:Vector<Datum>;
    var source:BitmapData;
    var w:Int;
    var h:Int;
    var cutoff:Int;
    var output:BitmapData;

    public static function process(input:Work):SerializedBitmap {
        var bd:BitmapData = new BitmapData(input.source.width, input.source.height, true, 0x0);
        bd.setPixels(bd.rect, input.source.bytes);

        var output:BitmapData = (new SDF(bd, input.cutoff)).output;

        return {width:output.width, height:output.height, bytes:output.getPixels(output.rect)};
    }

    function new(_source:BitmapData, _cutoff:Int):Void {

        this.cutoff = _cutoff;
        this.source = padBD(_source, _cutoff);

        dataMatrix = new Vector();
        allData = new Vector();
        innerData = new Vector();
        pendingData = new Vector();

        w = source.width;
        h = source.height;

        // Build the matrix and initialize the propagation algo
        for (row in 0...h) {
            dataMatrix[row] = new Vector();
            for (col in 0...w) {
                var datum:Datum = new Datum();
                if (source.getPixel32(col, row) & 0xFF > 0xF0) {
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

        output = new BitmapData(w, h, true, 0x0);

        for (datum in allData) {
            var distance:Float = datum.side;
            if (!_isNaN(datum.rad2)) distance *= sqrt(datum.rad2) / cutoff;
            var val:Int = int(distance * 0x80 + 0x7F);
            if (val < 0x00) val = 0x00;
            if (val > 0xFF) val = 0xFF;
            output.setPixel32(datum.col, datum.row, 0xFF000000 | val);
        }
    }

    function neighborsFor(datum:Datum):Vector<Datum> {
        var neighbors:Vector<Datum> = new Vector();

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

            var newNeighbors:Vector<Datum> = new Vector();

            for (neighbor in neighborsFor(datum)) {
                if (_isNaN(neighbor.rad2) && !neighbor.pending) {
                    newNeighbors.push(neighbor);
                } else {
                    var dx:Float = neighbor.dx + (neighbor.col - col);
                    var dy:Float = neighbor.dy + (neighbor.row - row);
                    var rad2:Float = dx * dx + dy * dy;
                    if (_isNaN(datum.rad2) || rad2 < datum.rad2) {
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

    function padBD(src:BitmapData, padding:Int):BitmapData {
        var dest:BitmapData = new BitmapData(src.width + 2 * padding, src.height + 2 * padding, true, 0x0);
        dest.copyPixels(src, src.rect, new Point(padding, padding), null, null, true);
        return dest;
    }

    inline function _isNaN(i:Float):Bool return untyped __global__["isNaN"](i);
}
