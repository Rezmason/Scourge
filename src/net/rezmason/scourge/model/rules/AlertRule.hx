package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Rule;

typedef AlertConfig = {
    var alertFunction:Void->Void;
}

class AlertRule extends Rule {

    private var cfg:AlertConfig;

    public function new(cfg:AlertConfig):Void {
        super();
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
        if (cfg.alertFunction != null) cfg.alertFunction();
    }
}

