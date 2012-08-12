package net.rezmason.scourge.tools;

import massive.munit.Assert;

import net.rezmason.scourge.tools.PieceGenerator;

class PieceGeneratorTest {

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    //@Test                             // slowing me down
    public function genTest1():Void {

        // PieceGenerator should create all one-sided polyominoes with no duplicates

        // http://mathworld.wolfram.com/Polyomino.html
        var expectedCounts:Array<Array<Int>> = [
            [ 1, 2, 6, 19, 63, 216, 760, 2725, 9910, 36446, ],
            [ 1, 1, 2,  7, 18,  60, 196,  704, 2500,  9189, ],
            [ 1, 1, 2,  5, 12,  35, 108,  369, 1285,  4655, ],
        ];

        var max:Int = 6;

        for (pieceType in 0...expectedCounts.length) {
            var counts:Array<Int> = expectedCounts[pieceType];
            for (size in 0...max) {
                var count:Int = counts[size];
                var pieces:Array<Piece> = PieceGenerator.generate(size + 1, pieceType);
                Assert.isNotNull(pieces);
                Assert.areEqual(count, pieces.length);
                for (piece in pieces) {
                    Assert.isNotNull(piece);
                    Assert.areEqual(size + 1, piece.length);
                }
            }
        }
    }
}
