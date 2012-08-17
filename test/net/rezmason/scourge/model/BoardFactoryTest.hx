package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.Aspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.scourge.model.GridUtils;

class BoardFactoryTest {

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {

        var history:History<Int> = new History<Int>();
        var historyArray:Array<Int> = history.array;

        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        cfg.numPlayers = 4;
        cfg.circular = false;
        var board:Array<BoardNode> = factory.makeBoard(cfg, history);

        Assert.areEqual(cfg.numPlayers, board.length);

        for (ike in 0...board.length) Assert.isNotNull(board[ike]);

        var playerHead:BoardNode = board[0];

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be four integers, equally spaced and equally distant from the edges of a box");
            trace(BoardUtils.spitGrid(playerHead, historyArray));
        #else
            Assert.areEqual(TestBoards.emptySquareFourPlayerSkirmish, BoardUtils.spitGrid(playerHead, historyArray, false));
        #end

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(-1, historyArray[getOwner(neighbor).occupier]);
            getOwner(neighbor).occupier = 0;
        }

        Assert.areEqual(0, getOwner(playerHead.nw()).occupier);
        Assert.areEqual(0, getOwner(playerHead.n()).occupier);
        Assert.areEqual(0, getOwner(playerHead.ne()).occupier);
        Assert.areEqual(0, getOwner(playerHead.e()).occupier);
        Assert.areEqual(0, getOwner(playerHead.se()).occupier);
        Assert.areEqual(0, getOwner(playerHead.s()).occupier);
        Assert.areEqual(0, getOwner(playerHead.sw()).occupier);
        Assert.areEqual(0, getOwner(playerHead.w()).occupier);

        history.wipe();

        var historyArray:Array<Int> = history.array;

        for (ike in historyArray) Assert.isNull(ike);

        for (node in board[0].getGraph()) {
            var ownerAspect:OwnershipAspect = getOwner(node);
            Assert.isNull(historyArray[ownerAspect.isFilled]);
            Assert.isNull(historyArray[ownerAspect.occupier]);
        }
    }

    @Test
    public function configTest2():Void {
        var history:History<Int> = new History<Int>();
        var historyArray:Array<Int> = history.array;
        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        cfg.numPlayers = 1;
        cfg.circular = true;
        var board:Array<BoardNode> = factory.makeBoard(cfg, history);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box");
            trace(BoardUtils.spitGrid(board[0], historyArray));
        #else
            Assert.areEqual(TestBoards.emptyPetri, BoardUtils.spitGrid(board[0], historyArray, false));
        #end
    }

    @Test
    public function configTest3():Void {
        var history:History<Int> = new History<Int>();
        var historyArray:Array<Int> = history.array;
        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        cfg.numPlayers = 4;
        cfg.initGrid = TestBoards.spiral;
        var board:Array<BoardNode> = factory.makeBoard(cfg, history);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be a four-player board with a spiral interior");
            trace(BoardUtils.spitGrid(board[0], historyArray));
        #end

        Assert.areEqual(TestBoards.spiral, BoardUtils.spitGrid(board[0], historyArray, false));
    }

    private function getOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }
}
