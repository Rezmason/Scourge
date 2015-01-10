package net.rezmason.scourge.tools;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.Pieces;
import net.rezmason.polyform.PolyformGenerator;
import net.rezmason.scourge.tools.Resource;

import haxe.JSON;

class PolyformGeneratorTest {

    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end

    @Test
    public function jsonTest():Void {

        var json:String = Resource.getString('tables/pieces.json.txt');
        var pieces:Pieces = new Pieces(json);

        var str:String = '\n';

        for (size in 0...pieces.maxSize()) {

            str += '$size\n__\n';

            var freePieces:Array<FreePiece> = pieces.getAllPiecesOfSize(size);

            for (freePiece in freePieces) {
                for (ike in 0...freePiece.numRotations) {
                    var piece = freePiece.getPiece(0, ike);
                    Assert.areEqual(size, piece.cells.length);
                    str += '\n' + spitPiece(piece);
                    if (freePiece.numReflections > 1) {
                        var mirrorPiece = freePiece.getPiece(1, ike);
                        Assert.areEqual(size, mirrorPiece.cells.length);
                        Assert.areNotEqual(Std.string(piece.cells), Std.string(mirrorPiece.cells));
                        str += '\n' + spitPiece(mirrorPiece);
                    }
                    str += '\n ';
                }
                str += '\n____\n';
            }
            VisualAssert.assert('all rotations and reflections of pieces of sizes 0-$size', str);
        }
    }

    @Test
    public function genTest1():Void {

        // PolyformGenerator should create all free polyominoes with no duplicates

        var expectedCounts:Array<Array<Int>> = [
            [ 1, 1, 1, 2,  5, 12,  35, 107,  363, 1248, ], // https://oeis.org/A000104
            [ 1, 1, 2, 6, 19, 63, 216, 756, 2684, 9638, ], // https://oeis.org/A006724
        ];

        var polyominoes = PolyformGenerator.generate(4, true);
        Assert.areEqual(Std.string(Json.parse(Resource.getString('tables/pieces.json.txt'))), Std.string(polyominoes));
        var freePiecesBySize = [for (series in polyominoes) [for (datum in series) new FreePiece(datum)]];
        for (size in 0...polyominoes.length) {
            var series = freePiecesBySize[size];
            var count = 0;
            for (freePiece in series) {
                count += freePiece.numReflections * freePiece.numRotations;
                for (reflection in 0...freePiece.numReflections) {
                    for (rotation in 0...freePiece.numRotations) {
                        Assert.areEqual(freePiece.getPiece(reflection, rotation).cells.length, size);
                    }
                }
            }
            Assert.areEqual(expectedCounts[0][size], series.length);
            Assert.areEqual(expectedCounts[1][size], count);
        }
    }

    private function spitPiece(piece:Piece):String {
        var max:Int = piece.cells.length + 2;

        var minX = max;
        var minY = max;
        for (coord in piece.corners) {
            if (minX > coord.x) minX = coord.x;
            if (minY > coord.y) minY = coord.y;
        }

        var str:String = '';
        for (ike in 0...max * max) {
            str += ' ';
        }

        for (coord in piece.cells) {
            var index:Int = max * (coord.y - minY) + coord.x - minX;
            str = str.substr(0, index) + 'X' + str.substr(index + 1);
        }

        for (coord in piece.edges) {
            var index:Int = max * (coord.y - minY) + coord.x - minX;
            str = str.substr(0, index) + 'o' + str.substr(index + 1);
        }

        for (coord in piece.corners) {
            var index:Int = max * (coord.y - minY) + coord.x - minX;
            str = str.substr(0, index) + '+' + str.substr(index + 1);
        }

        for (ike in 0...max + 1) {
            var index:Int = ike * max + ike;
            str = str.substr(0, index) + '\n' + str.substr(index);
        }

        return str;
    }
}