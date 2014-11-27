package tables;

import sys.io.File;

import net.rezmason.polyform.PolyformGenerator;

using haxe.Json;

class GenerateTables {

    static function main():Void {
        File.saveContent("./tables/pieces.json.txt", PolyformGenerator.generate(4, true, true).stringify());
    }
}
