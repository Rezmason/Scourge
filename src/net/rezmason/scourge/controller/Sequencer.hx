package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.game.ScourgeConfig;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.utils.Pointers;
import net.rezmason.utils.Zig;

class Sequencer extends Reckoner {

    var ecce:Ecce = null;
    var config:ScourgeConfig = null;
    var game:Game = null;
    var player:PlayerSystem = null;
    var qBoardNodeStates:Query;
    var qAnimations:Query;
    var lastMaxFreshness:Int;
    var waitingToProceed:Bool;
    public var gameStartSignal(default, null):Zig<Game->Ecce->Void> = new Zig();
    public var gameEndSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveSequencedSignal(default, null):Zig<Void->Void> = new Zig();
    public var boardChangeSignal(default, null):Zig<String->Null<Int>->Entity->Void> = new Zig();
    public var animationLength(default, set):Float;

    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new(ecce:Ecce) {
        super();
        this.ecce = ecce;
        qBoardNodeStates = ecce.query([BoardNodeState]);
        qAnimations = ecce.query([GlyphAnimation]);
        waitingToProceed = false;
        animationLength = 1;
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
        player.gameBegunSignal.remove(onGameBegun);
        player.moveStartSignal.remove(onMoveStart);
        player.moveStepSignal.remove(onMoveStep);
        player.moveStopSignal.remove(onMoveStop);
        player.gameEndedSignal.remove(onGameEnded);
        this.player = null;
        dismiss();
        for (e in ecce.get()) ecce.collect(e);
        waitingToProceed = false;
        gameEndSignal.dispatch();
    }

    function onGameBegun(config, game) {
        this.game = game;
        this.config = cast config;
        var loci = this.config.buildParams.loci;
        primePointers(game.state, game.plan);

        for (node in state.nodes) {
            var e = ecce.dispense([BoardNodeState, BoardNodeView]);
            var nodeState = e.get(BoardNodeState);
            nodeState.ident = getID(node);
            nodeState.values = node;
            nodeState.lastValues = node.copy();
            e.get(BoardNodeView).locus = loci[nodeState.ident];
        }
        gameStartSignal.dispatch(game, ecce);
        for (e in qBoardNodeStates) boardChangeSignal.dispatch(null, null, e);
        
        // waitingToProceed = true;
        player.proceed();
    }

    function onMoveStart(currentPlayer:Int, actionID:String, move:Int) {
        // trace('Player $currentPlayer does $actionID #$move');
        lastMaxFreshness = 0;
        for (e in qBoardNodeStates) {
            var nodeState = e.get(BoardNodeState);
            nodeState.values.copyTo(nodeState.values);
        }
    }

    function onMoveStep(cause:String) {
        var maxFreshness:Int = state.global[maxFreshness_];
        if (maxFreshness > lastMaxFreshness) {
            for (e in qBoardNodeStates) {
                var freshness:Int = e.get(BoardNodeState).values[freshness_];
                if (freshness >= lastMaxFreshness) {
                    boardChangeSignal.dispatch(cause, freshness, e);
                    e.get(BoardNodeState).values.copyTo(e.get(BoardNodeState).lastValues);
                }
            }
            lastMaxFreshness = maxFreshness;
        }
    }

    function onMoveStop() {
        var animations:Array<Array<GlyphAnimation>> = [];
        for (e in qAnimations) {
            var glyphAnimation = e.get(GlyphAnimation);
            glyphAnimation.time = 0;
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

        var finalAnims = animations[animations.length - 1];
        if (finalAnims != null) {
            var finalAnim = finalAnims[finalAnims.length - 1];
            var scale = animationLength / (finalAnim.startTime + finalAnim.duration);
            if (scale < 1) {
                for (anims in animations) {
                    for (anim in anims) {
                        anim.startTime *= scale;
                        anim.overlap *= scale;
                        anim.duration *= scale;
                    }
                }
            }
        }
        
        waitingToProceed = true;
        moveSequencedSignal.dispatch();
    }

    public function proceed() {
        if (waitingToProceed) {
            waitingToProceed = false;
            if (player != null) player.proceed();
            else for (entity in ecce.get()) ecce.collect(entity);
        }
    }

    inline function set_animationLength(val:Float):Float {
        animationLength = Math.max(val, 0);
        return animationLength;
    }
}
