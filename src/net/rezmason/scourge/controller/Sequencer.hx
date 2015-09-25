package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.praxis.play.PlayerSystem;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.controller.RulePresenter;
import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.scourge.textview.board.BoardSettler;
import net.rezmason.utils.Zig;
import net.rezmason.utils.pointers.Pointers;
import net.rezmason.utils.santa.Present;

using net.rezmason.grid.GridUtils;

class Sequencer extends Reckoner {

    var ecce:Ecce = null;
    var config:ScourgeGameConfig = null;
    var game:Game = null;
    var player:PlayerSystem = null;
    var qBoardSpaceStates:Query;
    var qBoardViews:Query;
    var qAnimations:Query;
    var lastMaxFreshness:Int;
    var waitingToProceed:Bool;
    var sequence:Array<Array<Array<Entity>>> = [];
    var defaultRulePresenter:RulePresenter;
    var rulePresentersByCause:Map<String, RulePresenter>;
    var boardSettler:BoardSettler;
    public var gameStartSignal(default, null):Zig<Game->Ecce->Void> = new Zig();
    public var gameEndSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveSequencedSignal(default, null):Zig<Void->Void> = new Zig();
    public var moveSettlingSignal(default, null):Zig<Void->Void> = new Zig();
    public var boardChangeSignal(default, null):Zig<String->Null<Int>->Entity->Void> = new Zig();
    public var animationLength(default, set):Float;

    @space(FreshnessAspect.FRESHNESS) var freshness_;
    @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new() {
        super();
        ecce = new Present(Ecce);
        boardSettler = new BoardSettler();

        qBoardSpaceStates = ecce.query([BoardSpaceState]);
        qBoardViews = ecce.query([BoardSpaceView]);
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

    function onGameEnded():Void {
        player.gameBegunSignal.remove(onGameBegun);
        player.moveStartSignal.remove(onMoveStart);
        player.moveStepSignal.remove(onMoveStep);
        player.moveStopSignal.remove(onMoveStop);
        player.gameEndedSignal.remove(onGameEnded);
        this.player = null;
        for (presenter in rulePresentersByCause) if (presenter != null) presenter.dismiss();
        rulePresentersByCause = null;
        defaultRulePresenter.dismiss();
        defaultRulePresenter = null;
        boardSettler.dismiss();
        if (game.winner == -1) for (e in qAnimations) ecce.collect(e);
        dismiss();
        waitingToProceed = false;
        gameEndSignal.dispatch();
    }

    function onGameBegun(config, game) {
        this.game = game;
        this.config = cast config;
        var petriCells = this.config.buildParams.cells;
        var cells:Array<Cell<Entity>> = [];
        primePointers(game.state, game.plan);

        rulePresentersByCause = new Map();
        defaultRulePresenter = new RulePresenter();
        defaultRulePresenter.init(game, ecce);
        for (cause in this.config.rulePresenters.keys()) {
            var rp = this.config.rulePresenters[cause];
            rulePresentersByCause[cause] = rp;
            if (rp != null) rp.init(game, ecce);
        }
        boardSettler.init(game);

        for (space in eachSpace()) {
            var id = getID(space);
            var e = ecce.dispense([BoardSpaceState, BoardSpaceView]);
            var spaceState = e.get(BoardSpaceState);
            spaceState.values = space;
            spaceState.lastValues = new AspectPointable([for (ike in 0...space.size()) NULL]);
            cells[id] = new Cell(id, e);
            spaceState.cell = cells[id];
            spaceState.petriData = petriCells.getCell(id).value;
        }

        for (ike in 0...cells.length) {
            for (direction in GridUtils.allDirections()) {
                var neighbor = petriCells.getCell(ike).neighbors[direction];
                if (neighbor != null) cells[ike].attach(cells[neighbor.id], direction);
            }
        }

        gameStartSignal.dispatch(game, ecce);
        sequence[0] = [for (e in qBoardSpaceStates) defaultRulePresenter.presentBoardEffect(e)];
        processSequence();
        waitingToProceed = true;
        moveSequencedSignal.dispatch();
    }

    function onMoveStart(currentPlayer:Int, actionID:String, move:Int) {
        lastMaxFreshness = 0;
        for (e in qBoardSpaceStates) {
            var spaceState = e.get(BoardSpaceState);
            spaceState.values.copyTo(spaceState.values);
        }
    }

    function onMoveStep(cause:String) {
        var presenter = rulePresentersByCause[cause];
        if (presenter == null) presenter = defaultRulePresenter;
        var maxFreshness:Int = state.global[maxFreshness_];
        if (maxFreshness > lastMaxFreshness) {
            for (e in qBoardSpaceStates) {
                var freshness:Int = e.get(BoardSpaceState).values[freshness_];
                if (freshness >= lastMaxFreshness) {
                    if (sequence[freshness] == null) sequence[freshness] = [];
                    sequence[freshness].push(presenter.presentBoardEffect(e));
                    var spaceState = e.get(BoardSpaceState);
                    spaceState.values.copyTo(spaceState.lastValues);
                }
            }
            lastMaxFreshness = maxFreshness;
        }
    }

    function onMoveStop() {
        processSequence();
        waitingToProceed = true;
        moveSequencedSignal.dispatch();
    }

    public function proceed() {
        if (waitingToProceed) {
            for (entity in qBoardViews) {
                if (entity.get(BoardSpaceView).changed) {
                    boardSettler.run();
                    moveSettlingSignal.dispatch();
                    processSequence();
                    return;
                }
            }
            if (waitingToProceed) {
                waitingToProceed = false;
                player.proceed();
            }
        }
    }

    function processSequence():Void {
        var animations = [];
        var startTime:Float = 0;
        for (step in sequence) { // steps correspond to freshness
            if (step == null) continue;
            var lastAnim = null;
            var lastAnimEndTime:Float = 0;
            for (effect in step) { // effects correspond to spaces on the board
                if (effect == null) continue;
                for (e in effect) {
                    var anim = e.get(GlyphAnimation);
                    var subjectSpaceState = anim.subject.get(BoardSpaceState);
                    anim.startTime += startTime;
                    animations.push(anim);
                    if (anim.startTime + anim.duration > lastAnimEndTime) {
                        lastAnim = anim;
                        lastAnimEndTime = anim.startTime + anim.duration;
                    }
                }
            }
            if (lastAnim != null) startTime = lastAnim.startTime + lastAnim.duration * (1 - 0); // TODO: overlap
        }
        sequence.splice(0, sequence.length);
        var finalAnim = animations[animations.length - 1];
        if (finalAnim != null) {
            var scale = animationLength / (finalAnim.startTime + finalAnim.duration);
            if (scale < 1) {
                for (anim in animations) {
                    anim.startTime *= scale;
                    anim.duration *= scale;
                }
            }
        }
    }

    inline function set_animationLength(val:Float):Float {
        animationLength = Math.max(val, 0);
        return animationLength;
    }
}
