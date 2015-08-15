package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.IPlayer;
import net.rezmason.praxis.play.Referee;
import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.build.PetriBoardFactory;
import net.rezmason.scourge.game.test.TestPlayer;
import net.rezmason.utils.openfl.Resource;

using net.rezmason.scourge.game.BoardUtils;
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

        var random:Void->Float = function() return 0.5;

        players = [];
        for (ike in 0...4) players.push(new TestPlayer(ike, noop, random));
        var config:ScourgeGameConfig = new ScourgeGameConfig();
        config.buildParams.cells = PetriBoardFactory.create(2);
        referee.beginGame(players, randGen, config);

        var savedGame = referee.saveGame();
        var data:String = savedGame.state.data;

        var prevData:String = Resource.getString('tables/serializedState.txt');
        if (prevData.charAt(prevData.length - 1) == '\n') prevData = prevData.substr(0, -1);

        trace(data);

        var ike:Int = 0;
        while (ike < prevData.length) {
            Assert.areEqual('$ike: ' + prevData.substr(ike, 200), '$ike: ' + data.substr(ike, 200));
            ike += 200;
        }
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

        var random:Void->Float = function() return 0.5;

        players = [];
        for (ike in 0...4) players.push(new TestPlayer(ike, defer, random));

        Assert.isFalse(referee.gameBegun);
        var config:ScourgeGameConfig = new ScourgeGameConfig();
        config.buildParams.cells = PetriBoardFactory.create(2);
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
