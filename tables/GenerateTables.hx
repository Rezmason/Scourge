package tables;

import sys.FileSystem;
import sys.io.File;

import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.tools.PieceGenerator;

using haxe.Json;

class GenerateTables {

    static function main():Void {
        generatePieceTable();
    }

    static function generatePieceTable():Void {
        var pieceGroupsBySize:Array<Array<PieceGroup>> = [];
        for (size in 0...4) {
            pieceGroupsBySize.push(PieceGenerator.generateGroups(size + 1));
        }

        File.write("./tables/pieces.json", false).writeString(pieceGroupsBySize.stringify());
    }
}
