package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.scourge.components.*;
import net.rezmason.utils.Pointers;
import net.rezmason.utils.Zig;

class Sequencer extends Reckoner {

    var ecce:Ecce = null;
    var game:Game = null;
    var player:PlayerSystem = null;
    var boardEntities:Map<Int, Entity>;
    var qBoardSpaces:Query;
    var qAnimations:Query;
    var lastMaxFreshness:Int;
    public var gameStartSignal(default, null):Zig<Game->Ecce->Void> = new Zig();
    public var gameChangeSignal(default, null):Zig<String->Void> = new Zig();
    public var boardChangeSignal(default, null):Zig<String->Int->Entity->Void> = new Zig();

    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new(ecce:Ecce) {
        super();
        this.ecce = ecce;
        qBoardSpaces = ecce.query([BoardSpace]);
        qAnimations = ecce.query([GlyphAnimation]);
        boardEntities = new Map();
    }

    public function connect(player:PlayerSystem):Void {
        this.player = player;
        player.gameBegunSignal.add(onGameBegun);
        player.moveStartSignal.add(onMoveStart);
        player.moveStepSignal.add(onMoveStep);
        player.moveStopSignal.add(onMoveStop);
        player.gameEndedSignal.add(onGameEnded);
    }

    public function onGameEnded():Void {
        for (key in boardEntities.keys()) boardEntities.remove(key);
        for (entity in qBoardSpaces) ecce.collect(entity);

        player.gameBegunSignal.remove(onGameBegun);
        player.moveStartSignal.remove(onMoveStart);
        player.moveStepSignal.remove(onMoveStep);
        player.moveStopSignal.remove(onMoveStop);
        player.gameEndedSignal.remove(onGameEnded);
        this.player = null;
    }

    public function proceed():Void player.proceed();

    function onGameBegun(game) {
        this.game = game;
        primePointers(game.state, game.plan);

        for (node in state.nodes) {
            var e = ecce.dispense([BoardSpace]);
            var boardSpace = e.get(BoardSpace);
            boardSpace.ident = node[ident_];
            boardSpace.values = node;
            boardSpace.lastValues = node.copy();
        }
        gameStartSignal.dispatch(game, ecce);
        player.proceed();
    }

    function onMoveStart(currentPlayer:Int, actionID:String, move:Int) {
        trace('Player $currentPlayer does $actionID #$move');
        lastMaxFreshness = 0;
        for (e in qBoardSpaces) {
            var boardSpace = e.get(BoardSpace);
            boardSpace.values.copyTo(boardSpace.values);
        }
    }

    function onMoveStep(cause:String) {
        var maxFreshness:Int = state.global[maxFreshness_];
        if (maxFreshness > lastMaxFreshness) {
            for (e in qBoardSpaces) {
                var freshness:Int = e.get(BoardSpace).values[freshness_];
                if (freshness >= lastMaxFreshness) {
                    boardChangeSignal.dispatch(cause, freshness, e);
                    e.get(BoardSpace).values.copyTo(e.get(BoardSpace).lastValues);
                }
            }
            lastMaxFreshness = maxFreshness;
        }
        gameChangeSignal.dispatch(cause);
    }

    function onMoveStop() {
        var animations:Array<Array<GlyphAnimation>> = [];
        for (e in qAnimations) {
            var glyphAnimation = e.get(GlyphAnimation);
            if (animations[glyphAnimation.index] == null) animations[glyphAnimation.index] = [glyphAnimation];
            else animations[glyphAnimation.index].push(glyphAnimation);
        }
        var startTime:Float = 0;
        for (ike in 0...animations.length) {
            var anims = animations[ike];
            if (anims == null) continue;
            var lastAnim = anims[0];
            for (anim in anims) {
                anim.startTime = startTime;
                if (anim.duration * (1 - anim.overlap) > lastAnim.duration * (1 - lastAnim.overlap)) lastAnim = anim;
            }
            startTime = lastAnim.startTime + lastAnim.duration * (1 - lastAnim.overlap);
        }

        // FOR NOW:
        var count = 0;
        for (e in qAnimations) {
            ecce.collect(e);
            count++;
        }
        
        proceed();
    }

}
