package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

class ForfeitRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override public function _init(cfg:Dynamic):Void { moves.push({id:0}); }

    override private function _chooseMove(choice:Int):Void {
        getPlayer(state.globals[currentPlayer_])[head_] = Aspect.NULL;
        signalEvent();
    }
}

