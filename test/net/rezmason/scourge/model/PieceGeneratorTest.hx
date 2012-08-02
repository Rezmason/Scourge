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

        var pieces:Array<Piece>;

        var expectedCounts:Array<Array<Int>> = [
            [1, 1, 2,  5, 12,  35],
            [1, 1, 2,  7, 18,  60],
            [1, 2, 6, 19, 63, 216],
        ];

        for (type in 0...expectedCounts.length) {
            for (size in expectedCounts[type]) {
                pieces = PieceGenerator.generate(size, type);
                Assert.isNotNull(pieces);
                Assert.areEqual(expectedCounts[type][size], pieces.length);
                for (piece in pieces) {
                    Assert.isNotNull(piece);
                    Assert.areEqual(piece.length, size);
                }
            }
        }
    }
}
