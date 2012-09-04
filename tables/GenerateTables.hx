package tables;

import neko.FileSystem;
import neko.io.File;

import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.tools.PieceGenerator;

using haxe.Json;

class GenerateTables {

    static function main():Void {
        generatePieceTable();
    }

    static function generatePieceTable():Void {
        var pieceGroups:Array<PieceGroup> = [];
        for (size in 0...4) {

            pieceGroups = pieceGroups.concat(PieceGenerator.generateGroups(size + 1));
        }

        File.write("./tables/pieces.json", false).writeString(pieceGroups.stringify());
    }
}
