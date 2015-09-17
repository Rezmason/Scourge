package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

class RuleElement<Params> extends Reckoner {
    @:allow(net.rezmason.praxis.rule) var params:Params;
    public function init():Void {}
    public function prime():Void {}
}
