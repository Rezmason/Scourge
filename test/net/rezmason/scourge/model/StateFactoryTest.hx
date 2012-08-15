package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;

import net.rezmason.scourge.model.aspects.Aspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Reflect;
using net.rezmason.scourge.model.GridUtils;

//typedef BoardNode = GridNode<IntHash<Aspect>>;

class StateFactoryTest {
/*
    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    private static var board1:String = "\n" +
        "X X X X X X X X X X X X X X X X X X X X X X X X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X           1                     2           X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X           0                     3           X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X                                             X \n" +
        "X X X X X X X X X X X X X X X X X X X X X X X X ";

    private static var board2:String = "\n" +
        "X X X X X X X X X X X X X \n" +
        "X X X X           X X X X \n" +
        "X X X               X X X \n" +
        "X X                   X X \n" +
        "X                       X \n" +
        "X                       X \n" +
        "X           0           X \n" +
        "X                       X \n" +
        "X                       X \n" +
        "X X                   X X \n" +
        "X X X               X X X \n" +
        "X X X X           X X X X \n" +
        "X X X X X X X X X X X X X ";

    private static var board3:String = "\n" +
        "XXXXXXXXXXXXXXXXXXXXXXXX\n" +
        "X1111112222222222222222X\n" +
        "X1111112222222222222222X\n" +
        "X1111112222222222222222X\n" +
        "X1111111111111111222222X\n" +
        "X1111111111111111222222X\n" +
        "X1111111111111111222222X\n" +
        "X111000   XXXX   222333X\n" +
        "X111000 11111111 222333X\n" +
        "X111000 00000001 222333X\n" +
        "X111000X01111101X222333X\n" +
        "X111000X01000101X222333X\n" +
        "X111000X01010101X222333X\n" +
        "X111000X01011101X222333X\n" +
        "X111000 01000001 222333X\n" +
        "X111000 01111111 222333X\n" +
        "X111000   XXXX   222333X\n" +
        "X0000003333333333333333X\n" +
        "X0000003333333333333333X\n" +
        "X0000003333333333333333X\n" +
        "X0000000000000000333333X\n" +
        "X0000000000000000333333X\n" +
        "X0000000000000000333333X\n" +
        "XXXXXXXXXXXXXXXXXXXXXXXX";

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {
        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        for (gene in ["a", "b", "c", "d"]) cfg.playerGenes.push(gene);
        cfg.rules.push(null);
        cfg.circular = false;
        var state:State = factory.makeState(cfg);

        Assert.areEqual(cfg.playerGenes.length, state.players.length);

        for (player in state.players) {
            Assert.isNotNull(player.head);
            for (aspect in player.aspects) {
                // TODO: Assert aspects?
            }
        }

        for (aspect in state.aspects) {
            // TODO: Assert aspects?
        }

        var playerHead:BoardNode = state.players[0].head;

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be four integers, equally spaced and equally distant from the edges of a box");
            trace(spitGrid(playerHead));
        #else
            Assert.areEqual(board1, spitGrid(playerHead));
        #end

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(-1, getOwner(neighbor).occupier);
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
    }

    @Test
    public function configTest2():Void {
        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        for (gene in ["a"]) cfg.playerGenes.push(gene);
        cfg.circular = true;
        var state:State = factory.makeState(cfg);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box");
            trace(spitGrid(state.players[0].head));
        #else
            Assert.areEqual(board2, spitGrid(state.players[0].head));
        #end
    }

    @Test
    public function configTest3():Void {
        var factory:BoardFactory = new BoardFactory();
        var cfg:BoardConfig = new BoardConfig();
        for (gene in ["a", "b", "c", "d"]) cfg.playerGenes.push(gene);
        cfg.initGrid = board3;
        var state:State = factory.makeState(cfg);

        // trace(spitGrid(state.players[0].head));

        Assert.areEqual(board3, spitGrid(state.players[0].head, false));
    }

    private function spitGrid(head:BoardNode, addSpaces:Bool = true):String {
        var str:String = "";

        var grid:BoardNode = head.run(Gr.nw).run(Gr.w).run(Gr.n);

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {
                str += nodeToString(column);
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }

    private function nodeToString(node:BoardNode):String {
        var ownerAspect:OwnershipAspect = getOwner(node);
        if (ownerAspect.occupier > -1) return Std.string(ownerAspect.occupier);
        if (ownerAspect.isFilled == 1) return "X";

        return " ";
    }

    private function getOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }
*/
}
