package net.rezmason.utils;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.Vector;
import Math.*;
import Std.int;

typedef Datum = { dx:Float, dy:Float, rad2:Float, row:Int, col:Int, pending:Bool, side:Int }

class SDF {

    var pendingData:Vector<Datum>;
    var dataMatrix:Vector<Vector<Datum>>;
    var innerData:Vector<Datum>;
    var allData:Vector<Datum>;
    var w:Int;
    var h:Int;
    var cutoff:Int;

    var distOffset:Int;

    var t:Float;

    public function new():Void {}

    public function process(source:BitmapData, cutoff:Int):BitmapData {

        this.cutoff = cutoff;
        computeSDF(padBD(source, cutoff));

        var maxInnerDist:Float = 0;
        for (datum in innerData) if (maxInnerDist < datum.rad2) maxInnerDist = datum.rad2;
        distOffset = int(sqrt(maxInnerDist) + 1);

        return exportStuff();
    }

    inline function exportStuff():BitmapData {

        var sdf:BitmapData = new BitmapData(w, h, true, 0x0);

        for (datum in allData) {
            var distance:Float = sqrt(datum.rad2) * datum.side;
            sdf.setPixel32(datum.col, datum.row, 0xFF000000 | int((distance + distOffset)));
        }

        return sdf;
    }

    inline function computeSDF(source:BitmapData):Void {
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
                var datum:Datum = null;
                if (source.getPixel32(col, row) & 0xFF > 0xF0) {
                    datum = {row:row, col:col, dx:0, dy:0, rad2:0, pending:true, side:-1};
                    pendingData.push(datum);
                    innerData.push(datum);
                } else {
                    datum = {row:row, col:col, dx:NaN, dy:NaN, rad2:NaN, pending:false, side:1};
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
    }

    inline function neighborsFor(datum:Datum):Vector<Datum> {
        var neighbors:Vector<Datum> = new Vector();

        var row:Int = datum.row;
        var col:Int = datum.col;

        if (col > 0    ) neighbors.push(dataMatrix[row][col - 1]);
        if (col < w - 1) neighbors.push(dataMatrix[row][col + 1]);
        if (row > 0    ) neighbors.push(dataMatrix[row - 1][col]);
        if (row < h - 1) neighbors.push(dataMatrix[row + 1][col]);

        if (col > 0     && row > 0    ) neighbors.push(dataMatrix[row - 1][col - 1]);
        if (col < w - 1 && row > 0    ) neighbors.push(dataMatrix[row - 1][col + 1]);
        if (col > 0     && row < h - 1) neighbors.push(dataMatrix[row + 1][col - 1]);
        if (col < w - 1 && row < h - 1) neighbors.push(dataMatrix[row + 1][col + 1]);

        return neighbors;
    }

    inline function findPendingDistances():Void {
        var datum:Datum;
        while ((datum = pendingData.shift()) != null) {
            datum.pending = false;

            for (neighbor in neighborsFor(datum)) {
                if (isNaN(neighbor.rad2) && !neighbor.pending) {
                    pendingData.push(neighbor);
                    neighbor.pending = true;
                } else {
                    var dx:Float = neighbor.dx + (neighbor.col - datum.col);
                    var dy:Float = neighbor.dy + (neighbor.row - datum.row);
                    var rad2:Float = dx * dx + dy * dy;
                    if (isNaN(datum.rad2) || rad2 < datum.rad2) {
                        datum.dx = dx;
                        datum.dy = dy;
                        datum.rad2 = rad2;
                    }
                }
            }
        }
    }

    inline function padBD(src:BitmapData, padding:Int):BitmapData {
        var dest:BitmapData = new BitmapData(src.width + 2 * padding, src.height + 2 * padding, true, 0x0);
        dest.copyPixels(src, src.rect, new Point(padding, padding), null, null, true);
        return dest;
    }
}
