package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.utils.Pointers;

typedef BuildStateConfig = {
    public var firstPlayer:Int;
}

class BuildGlobalsRule extends Rule {

    private var cfg:BuildStateConfig;

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override public function _init(cfg:Dynamic):Void { this.cfg = cfg; }

    override private function _prime():Void {
        addGlobals();
        state.globals[currentPlayer_] = cfg.firstPlayer;
    }
}
