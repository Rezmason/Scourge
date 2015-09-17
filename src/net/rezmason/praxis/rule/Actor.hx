package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

class Actor<Params> extends RuleElement<Params> {
    @:allow(net.rezmason.praxis.rule) var signalChange:Void->Void;
    public function chooseMove(move:Move):Void {}
}
