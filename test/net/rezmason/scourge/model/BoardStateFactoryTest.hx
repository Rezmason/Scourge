package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;

using Reflect;
using net.rezmason.scourge.model.GridUtils;

typedef BoardNode = GridNode<Cell>;

class BoardStateFactoryTest {

    private static var board1:String = "\n" +
        "• • • • • • • • • • • • • • • • • • • • • • • • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•           1                     2           • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•           0                     3           • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "•                                             • \n" +
        "• • • • • • • • • • • • • • • • • • • • • • • • ";

    private static var board2:String = "\n" +
        "• • • • • • • • • • • • • \n" +
        "• • • •           • • • • \n" +
        "• • •               • • • \n" +
        "• •                   • • \n" +
        "•                       • \n" +
        "•                       • \n" +
        "•           0           • \n" +
        "•                       • \n" +
        "•                       • \n" +
        "• •                   • • \n" +
        "• • •               • • • \n" +
        "• • • •           • • • • \n" +
        "• • • • • • • • • • • • • ";

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {
        var factory:BoardStateFactory = new BoardStateFactory();
        var cfg:BoardStateConfig = new BoardStateConfig();
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
            Assert.areEqual(-1, neighbor.value.occupier);
            neighbor.value.occupier = 0;
        }

        Assert.areEqual(0, playerHead.nw().value.occupier);
        Assert.areEqual(0, playerHead.n().value.occupier);
        Assert.areEqual(0, playerHead.ne().value.occupier);
        Assert.areEqual(0, playerHead.e().value.occupier);
        Assert.areEqual(0, playerHead.se().value.occupier);
        Assert.areEqual(0, playerHead.s().value.occupier);
        Assert.areEqual(0, playerHead.sw().value.occupier);
        Assert.areEqual(0, playerHead.w().value.occupier);
    }

    @Test
    public function configTest2():Void {
        var factory:BoardStateFactory = new BoardStateFactory();
        var cfg:BoardStateConfig = new BoardStateConfig();
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

    private function spitGrid(head:BoardNode):String {
        var str:String = "";

        var grid:BoardNode = head.run(Gr.nw).run(Gr.w).run(Gr.n);

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {
                str += cellToString(column.value);
                str += " ";
            }
        }

        return str;
    }

    private function cellToString(cell:Cell):String {
        if (cell.occupier > -1) return Std.string(cell.occupier);
        if (cell.isFilled) return "•";

        return " ";
    }
}
