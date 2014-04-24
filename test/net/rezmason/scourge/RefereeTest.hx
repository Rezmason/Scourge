package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

import net.rezmason.scourge.tools.Resource;

import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ControllerTypes;

using net.rezmason.scourge.model.BoardUtils;
class RefereeTest {

    var referee:Referee;
    var playerDefs:Array<PlayerDef>;

    public function new() {

    }

    @BeforeClass
    public function beforeClass():Void {
        referee = new Referee();
    }

    @AfterClass
    public function afterClass():Void {

    }

    #if neko @Ignore('Runs too slow on NekoVM') #end
    @Test
    public function serializeTest():Void {

        function noop(game:Game, func:Void->Void) {}

        playerDefs = [Test(noop), Test(noop), Test(noop), Test(noop)];
        var config:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        referee.beginGame({playerDefs:playerDefs, randGen:randGen, gameConfig:config});

        var savedGame = referee.saveGame();
        var data:String = savedGame.state.data;

        var prevData:String = Resource.getString('tables/serializedState.txt');
        if (prevData.charAt(prevData.length - 1) == '\n') prevData = prevData.substr(0, -1);

        // trace(prevData);
        // trace(data);

        var ike:Int = 0;
        while (ike < prevData.length) {
            Assert.areEqual('$ike: ' + prevData.substr(ike, 200), '$ike: ' + data.substr(ike, 200));
            ike += 200;
        }

        // Assert.areEqual(prevData, data);
    }

    #if neko @Ignore('Runs too slow on NekoVM') #end
    @Test
    public function saveTest():Void {

        var deferredCalls = [];

        function defer(game:Game, func:Void->Void) {
            deferredCalls.push(func);
        }

        playerDefs = [Test(defer), Test(defer), Test(defer), Test(defer)];

        Assert.isFalse(referee.gameBegun);
        var config:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        var refereeParams = {playerDefs:playerDefs, randGen:randGen, gameConfig:config, savedGame:null};
        referee.beginGame(refereeParams);
        Assert.isTrue(referee.gameBegun);

        for (ike in 0...10)
        {
            var oldDeferredCalls = deferredCalls;
            deferredCalls = [];
            var then = Timer.stamp();
            //trace('$ike ${oldDeferredCalls.length} ${Std.int(then * 1000)}');

            for (call in oldDeferredCalls) {
                call();

                var now = Timer.stamp();
                //trace(Std.int((now - then) * 1000));
                then = now;
            }
        }

        refereeParams.savedGame = referee.saveGame();
        var board = referee.spitBoard();

        //trace(board);

        var moves:String = referee.spitMoves();
        // trace(moves);

        // trace(referee.spitPlan());

        referee.endGame();
        Assert.isFalse(referee.gameBegun);

        referee.beginGame(refereeParams);
        Assert.isTrue(referee.gameBegun);

        Assert.areEqual(board, referee.spitBoard());

        referee.endGame();
        Assert.isFalse(referee.gameBegun);
    }

    private function randGen():Float { return 0; }
}
