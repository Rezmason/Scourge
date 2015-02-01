package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

import net.rezmason.scourge.tools.Resource;

import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

import net.rezmason.scourge.controller.IPlayer;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.TestPlayer;

using net.rezmason.scourge.model.BoardUtils;
class RefereeTest {

    var referee:Referee;
    var players:Array<IPlayer>;

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

        var random:Void->Float = Math.random;

        players = [];
        for (ike in 0...4) players.push(new TestPlayer(ike, noop, random));
        var config:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        referee.beginGame(players, randGen, config);

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

        var watchedGame:Game = null;

        function defer(game:Game, func:Void->Void) {
            if (watchedGame == null) watchedGame = game;
            deferredCalls.push(func);
        }

        var random:Void->Float = Math.random;

        players = [];
        for (ike in 0...4) players.push(new TestPlayer(ike, defer, random));

        Assert.isFalse(referee.gameBegun);
        var config:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        referee.beginGame(players, randGen, config);
        Assert.isTrue(referee.gameBegun);

        for (ike in 0...10)
        {
            var oldDeferredCalls = deferredCalls;
            deferredCalls = [];
            for (call in oldDeferredCalls) call();
        }

        var savedGame = referee.saveGame();
        var board = watchedGame.state.spitBoard(watchedGame.plan);

        referee.endGame();
        Assert.isFalse(referee.gameBegun);

        referee.beginGame(players, randGen, config, savedGame);
        Assert.isTrue(referee.gameBegun);

        Assert.areEqual(board, watchedGame.state.spitBoard(watchedGame.plan));

        referee.endGame();
        Assert.isFalse(referee.gameBegun);
    }

    private function randGen():Float { return 0; }
}
