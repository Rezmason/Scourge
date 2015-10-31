package net.rezmason.scourge.tools;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.scourge.game.Piece;
import net.rezmason.scourge.game.PieceLibrary;
import net.rezmason.polyform.PolyformGenerator;
import net.rezmason.utils.openfl.Resource;

using haxe.Json;
using net.rezmason.polyform.PolyformPlotter;

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
        var pieceLib:PieceLibrary = new PieceLibrary(json);

        var str:String = '\n';

        for (size in 0...pieceLib.maxSize()) {

            str += '$size\n__\n';

            var freePieces:Array<Piece> = pieceLib.getPiecesOfSize(size);

            for (freePiece in freePieces) {
                for (ike in 0...freePiece.numRotations) {
                    var piece = freePiece.getVariant(0, ike);
                    Assert.areEqual(size, piece.cells.length);
                    str += '\n' + spitPiece(piece);
                    if (freePiece.numReflections > 1) {
                        var mirrorPiece = freePiece.getVariant(1, ike);
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

        var polyominoes = PolyformGenerator.generate(4);

        var json:String = Resource.getString('tables/pieces.json.txt');
        var data:Array<Array<Dynamic>> = json.parse();
        for (ike in 0...data.length) {
            var count = 0;
            for (jen in 0...data[ike].length) {
                var freePiece = new Piece(data[ike][jen]);
                var poly = polyominoes[ike][jen];
                count += poly.numReflections() * poly.numRotations();
                Assert.areEqual(freePiece.numReflections, poly.numReflections());
                Assert.areEqual(freePiece.numRotations, poly.numRotations());
                for (ref in 0...freePiece.numReflections) {
                    for (rot in 0...freePiece.numRotations) {
                        var piece = freePiece.getVariant(ref, rot);
                        var fixedPoly = freePiece.getVariant(ref, rot);
                        Assert.areEqual(Std.string(piece.cells), Std.string(fixedPoly.cells));
                        Assert.areEqual(piece.cells.length, ike);
                    }
                }
            }
            Assert.areEqual(expectedCounts[0][ike], data[ike].length);
            Assert.areEqual(expectedCounts[1][ike], count);
        }
    }

    function sortCoords(c1, c2) {
        if (c1.x != c2.x) return c1.x - c2.x;
        return c1.y - c2.y;
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
