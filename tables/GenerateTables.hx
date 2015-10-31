package tables;

import sys.io.File;
import net.rezmason.polyform.Polyform;
import net.rezmason.polyform.Ornament;
import net.rezmason.polyform.PolyformGenerator;
import net.rezmason.scourge.game.PieceData;

using haxe.Json;
using net.rezmason.polyform.PolyformPlotter;

class GenerateTables {

    static function main():Void {
        var pieces = PolyformGenerator.generate(4, true);
        var pieceData = [for (series in pieces) [for (piece in series) toData(piece)]];
        var json = pieceData.stringify();
        File.saveContent("./tables/pieces.json.txt", json);
    }

    inline static function toData(piece:Polyform):PieceData {
        var compactDiagram:Array<Array<Ornament>> = piece.render().compact();
        var cells = [];
        var edges = [];
        var corners = [];
        var cx = 0;
        var cy = 0;
        var count = 0;
        for (row in 0...compactDiagram.length) {
            for (col in 0...compactDiagram[0].length) {
                switch (compactDiagram[row][col]) {
                    case CELL: cells.push({x:col, y:row});
                    case EDGE: edges.push({x:col, y:row});
                    case CORNER: corners.push({x:col, y:row});
                    case _:
                }
            }
        }
        var center = count == 0 ? {x:0, y:0} : {x:cx / count, y:cy / count};
        return {
            cells:cells,
            edges:edges,
            corners:corners,
            center:center,
            id:piece.toString(),
            numReflections:piece.numReflections(),
            numRotations:piece.numRotations()
        };
    }
}
