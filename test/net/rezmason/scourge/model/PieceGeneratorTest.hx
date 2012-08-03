package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.PieceGenerator;

class PieceGeneratorTest {

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function genTest1():Void {

        // PieceGenerator should create all one-sided polyominoes with no duplicates

        // http://mathworld.wolfram.com/Polyomino.html
        var expectedCounts:Array<Array<Int>> = [
            [1, 2, 6, 19, 63, 216],
            [1, 1, 2,  7, 18,  60],
            [1, 1, 2,  5, 12,  35],
        ];

        for (pieceType in 0...expectedCounts.length) {
            var counts:Array<Int> = expectedCounts[pieceType];
            for (size in 0...expectedCounts[pieceType].length) {
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
