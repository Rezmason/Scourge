package net.rezmason.scourge.textview.board;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.controller.PlayerSystem;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.aspects.*;
import net.rezmason.utils.Pointers;



class BoardSequenceSystem {

    var ecce:Ecce = null;
    var game:Game = null;
    var player:PlayerSystem = null;
    var boardEntities:Map<Int, Entity>;
    var qBoardSpaces:Query;
    var freshness_:AspectPtr;
    var maxFreshness_:AspectPtr;
    var ident_:AspectPtr;
    var lastFreshness:Int;

    public function new(ecce:Ecce) {
        this.ecce = ecce;
        qBoardSpaces = ecce.query([BoardSpace]);
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
        trace('GAME END');
    }

    function onGameBegun(game) { 
        this.game = game;
        freshness_ = game.plan.onNode(FreshnessAspect.FRESHNESS);
        maxFreshness_ = game.plan.onState(FreshnessAspect.MAX_FRESHNESS);
        ident_ = Ptr.intToPointer(0, game.state.key);
        
        for (node in game.state.nodes) {
            var e = ecce.dispense([BoardSpace]);
            e.get(BoardSpace).node = node;
        }
        trace('GAME START');

        player.proceed();
    }

    function onMoveStart(currentPlayer:Int, action:Int, move:Int) {
        trace('Player $currentPlayer does ${game.actionIDs[action]} #$move');
        lastFreshness = 0;
    }

    function onMoveStep(cause:String) {
        var maxFreshness:Int = game.state.globals[maxFreshness_];
        if (maxFreshness > lastFreshness) trace('\t$cause: $maxFreshness');
        for (e in qBoardSpaces) {
            var node = e.get(BoardSpace).node;
            if (node[freshness_] > lastFreshness) trace(node[ident_]);
        }
        lastFreshness = maxFreshness;
    }

    function onMoveStop() {
        // trace('READ STOP');
        
        player.proceed();
    }

}

