package;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.events.Event;
import flash.geom.Point;
import flash.Lib.current;
import Math.*;
import Std.int;

@:bitmap("rm.png") class BMP extends BitmapData {}

typedef Datum = { dx:Float, dy:Float, rad2:Float, row:Int, col:Int, pending:Bool, side:Int }

class SDF {

    inline static var FREQUENCY:Float = 0.1;
    inline static var AMPLITUDE:Float = 1.0;

    var pendingData:Array<Datum>;
    var dataMatrix:Array<Array<Datum>>;
    var innerData:Array<Datum>;
    var allData:Array<Datum>;
    var w:Int;
    var h:Int;
    var cutoff:Int;

    var source:BitmapData;
    var distOffset:Int;

    var t:Float;

    inline static function main():Void (new SDF()).process(new BMP(0, 0), 40, true);

    public function new():Void {}

    public function process(source:BitmapData, cutoff:Int, show:Bool):BitmapData {

        this.cutoff = cutoff;
        this.source = padBD(source, cutoff);

        computeSDF();

        var maxInnerDist:Float = 0;
        for (datum in innerData) if (maxInnerDist < datum.rad2) maxInnerDist = datum.rad2;
        distOffset = int(sqrt(maxInnerDist) + 1);

        var sdf:BitmapData = exportStuff();

        if (show) viewStuff();

        return sdf;
    }

    inline function exportStuff():BitmapData {

        var sdf:BitmapData = new BitmapData(w, h, true, 0x0);

        for (datum in allData) {
            var distance:Float = sqrt(datum.rad2) * datum.side;
            sdf.setPixel32(datum.col, datum.row, 0xFF000000 | int((distance + distOffset)));
        }

        return sdf;
    }

    inline function viewStuff():Void {

        var sdf:BitmapData = exportStuff();
        var sdfView:BitmapData = new BitmapData(w, h, true, 0x0);
        var output:BitmapData = new BitmapData(w, h, true, 0x0);

        [source, sdfView, output].map(addBitmap);

        for (datum in allData) {
            var distance:Float = sqrt(datum.rad2) * datum.side;
            sdfView.setPixel32(datum.col, datum.row, 0xFF000000 | int((distance + distOffset) * 3));
        }

        sdfView.copyChannel(sdfView, sdfView.rect, sdfView.rect.topLeft, BitmapDataChannel.BLUE, BitmapDataChannel.GREEN);
        sdfView.copyChannel(sdfView, sdfView.rect, sdfView.rect.topLeft, BitmapDataChannel.BLUE, BitmapDataChannel.RED);

        t = 0;

        function update(event:Event):Void {
            t += 1.0;

            var v:Float = (sin(t * FREQUENCY) * 0.5 + 0.5) * (cutoff + distOffset);
            v = distOffset * (1 - AMPLITUDE) + v * AMPLITUDE;

            output.fillRect(output.rect, 0x0);
            output.threshold(sdf, sdf.rect, sdf.rect.topLeft, "<", int(v), 0xFFFFFFFF, 0xFFFFFF);
        }

        current.addEventListener(Event.ENTER_FRAME, update);
    }

    inline function addBitmap(bd:BitmapData):Void {
        var bmp:Bitmap = new Bitmap(bd);
        bmp.x = current.width;
        current.addChild(bmp);
    }

    inline function computeSDF():Void {
        dataMatrix = [];
        allData = [];
        innerData = [];
        pendingData = [];

        w = source.width;
        h = source.height;

        // Build the matrix and initialize the propagation algo
        for (row in 0...h) {
            dataMatrix[row] = [];
            for (col in 0...w) {
                var datum:Datum = {row:row, col:col, dx:NaN, dy:NaN, rad2:NaN, pending:false, side:1};
                if (source.getPixel32(col, row) & 0xFF > 0xF0) {
                    datum.dx = datum.dy = datum.rad2 = 0;
                    datum.side = -1;
                    datum.pending = true;
                    pendingData.push(datum);
                    innerData.push(datum);
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

    inline function neighborsFor(datum:Datum):Array<Datum> {
        var neighbors:Array<Datum> = [];

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
