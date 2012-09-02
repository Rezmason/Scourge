package net.rezmason.scourge.tools;

import massive.munit.Assert;

import net.rezmason.scourge.tools.PieceGenerator;

class PieceGeneratorTest {

    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace(time);
    }

    @Test
    public function genTest1():Void {

        // PieceGenerator should create all one-sided polyominoes with no duplicates

        // http://mathworld.wolfram.com/Polyomino.html
        var expectedCounts:Array<Array<Int>> = [
            [ 1, 2, 6, 19, 63, 216, 760, 2725, 9910, 36446, ],
            [ 1, 1, 2,  7, 18,  60, 196,  704, 2500,  9189, ],
            [ 1, 1, 2,  5, 12,  35, 108,  369, 1285,  4655, ],
        ];

        var max:Int = 4;

        for (pieceType in 0...expectedCounts.length) {
            var counts:Array<Int> = expectedCounts[pieceType];
            for (size in 0...max) {
                var count:Int = counts[size];
                var pieces:Array<Piece> = PieceGenerator.generate(size + 1, pieceType);
                Assert.isNotNull(pieces);
                Assert.areEqual(count, pieces.length);
                for (piece in pieces) {
                    Assert.isNotNull(piece);
                    Assert.areEqual(size + 1, piece[0].length);
                }
            }
        }

        var count:Int = 5;
        var pieceGroups:Array<PieceGroup> = PieceGenerator.generateGroups(4);
        Assert.isNotNull(pieceGroups);
        Assert.areEqual(count, pieceGroups.length);

        var str:String = "\n";

        for (group in pieceGroups) {
            var left:Array<Piece> = group[0];
            var right:Array<Piece> = group[1];

            if (right != null) Assert.areEqual(left.length, right.length);

            for (ike in 0...left.length) {
                str += "\n" + spitPiece(left[ike]);
                if (right != null) {
                    Assert.areNotEqual(Std.string(left[ike]), Std.string(right[ike]));
                    str += "\n" + spitPiece(right[ike]);
                }
                str += "\n" + " ";
            }
            str += "\n" + "____";
        }

        //trace(str);
    }

    private function spitPiece(piece:Piece):String {
        var max:Int = piece[0].length + 2;

        var str:String = "";
        for (ike in 0...max * max) {
            str += "-";
        }

        for (coord in piece[0]) {
            var index:Int = max * (coord.y + 1) + coord.x + 1;
            str = str.substr(0, index) + "O" + str.substr(index + 1);
        }

        for (coord in piece[1]) {
            var index:Int = max * (coord.y + 1) + coord.x + 1;
            str = str.substr(0, index) + "." + str.substr(index + 1);
        }

        for (ike in 0...max) {
            var index:Int = ike * max + ike;
            str = str.substr(0, index) + "\n" + str.substr(index);
        }

        return str;
    }
}
