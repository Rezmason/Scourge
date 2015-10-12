package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.controller.RulePresenter;
import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.scourge.controller.board.BoardSettler;
import net.rezmason.scourge.controller.board.BoardInitializer;
import net.rezmason.utils.Zig;
import net.rezmason.utils.pointers.Pointers;
import net.rezmason.utils.santa.Present;

using net.rezmason.grid.GridUtils;

class Sequencer {

    var ecce:Ecce = null;
    var config:ScourgeGameConfig = null;
    var game:Game = null;
    var qBoardSpaceStates:Query;
    var qBoardViews:Query;
    var qAnimations:Query;
    var lastMaxFreshness:Int;
    var sequence:Array<Array<Array<Entity>>> = [];
    var defaultRulePresenter:RulePresenter;
    var rulePresentersByCause:Map<String, RulePresenter>;
    var boardInitializer = new BoardInitializer();
    var boardSettler:BoardSettler;
    public var gameStartSignal(default, null):Zig<Void->Void> = new Zig();
    public var gameEndSignal(default, null):Zig<Void->Void> = new Zig();
    public var animationComposedSignal(default, null):Zig<Void->Void> = new Zig();
    public var boardChangeSignal(default, null):Zig<String->Null<Int>->Entity->Void> = new Zig();
    public var animationLength(default, set):Float;

    var freshness_:AspectPointer<PSpace>;
    var maxFreshness_:AspectPointer<PGlobal>;

    public function new() {
        ecce = new Present(Ecce);
        boardSettler = new BoardSettler();

        qBoardSpaceStates = ecce.query([BoardSpaceState]);
        qBoardViews = ecce.query([BoardSpaceView]);
        qAnimations = ecce.query([GlyphAnimation]);
        animationLength = 1;
    }

    public function endGame():Void {
        for (presenter in rulePresentersByCause) if (presenter != null) presenter.dismiss();
        rulePresentersByCause = null;
        defaultRulePresenter.dismiss();
        defaultRulePresenter = null;
        boardSettler.dismiss();
        if (game.winner == -1) for (e in qAnimations) ecce.collect(e);
        gameEndSignal.dispatch();
    }

    public function beginGame(config, game) {
        this.game = game;
        this.config = cast config;
        var petriCells = this.config.buildParams.cells;
        var cells:Array<Cell<Entity>> = [];
        freshness_ = game.plan.onSpace(FreshnessAspect.FRESHNESS);
        maxFreshness_ = game.plan.onGlobal(FreshnessAspect.MAX_FRESHNESS);
        
        rulePresentersByCause = new Map();
        defaultRulePresenter = new RulePresenter();
        defaultRulePresenter.init(game, ecce);
        for (cause in this.config.rulePresenters.keys()) {
            var rp = this.config.rulePresenters[cause];
            rulePresentersByCause[cause] = rp;
            if (rp != null) rp.init(game, ecce);
        }
        boardSettler.init(game);

        for (ike in 0...game.state.spaces.length) {
            var space = game.state.spaces[ike];
            var e = ecce.dispense([BoardSpaceState, BoardSpaceView]);
            var spaceState = e.get(BoardSpaceState);
            spaceState.values = space;
            spaceState.lastValues = new AspectPointable([for (ike in 0...space.size()) NULL]);
            cells[ike] = new Cell(ike, e);
            spaceState.cell = cells[ike];
            spaceState.petriData = petriCells.getCell(ike).value;
        }

        for (ike in 0...cells.length) {
            for (direction in GridUtils.allDirections()) {
                var neighbor = petriCells.getCell(ike).neighbors[direction];
                if (neighbor != null) cells[ike].attach(cells[neighbor.id], direction);
            }
        }

        gameStartSignal.dispatch();

        boardInitializer.run();
        sequence.push([for (e in qBoardSpaceStates) defaultRulePresenter.presentBoardEffect(e)]);
        sequence.push([boardSettler.run()]);
        startAnimation();
        animationComposedSignal.dispatch();
    }

    public function beginMove(currentPlayer:Int, actionID:String, move:Int) {
        lastMaxFreshness = 0;
        for (e in qBoardSpaceStates) {
            var spaceState = e.get(BoardSpaceState);
            spaceState.values.copyTo(spaceState.values);
        }
    }

    public function stepMove(cause:String) {
        var presenter = rulePresentersByCause[cause];
        if (presenter == null) presenter = defaultRulePresenter;
        var maxFreshness:Int = game.state.global[maxFreshness_];
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

    public function endMove() {
        sequence.push([boardSettler.run()]);
        startAnimation();
        animationComposedSignal.dispatch();
    }

    function startAnimation():Void {
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
