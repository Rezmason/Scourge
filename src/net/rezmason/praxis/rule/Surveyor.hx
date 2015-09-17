package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

class Surveyor<Params> extends RuleElement<Params> {
    public var moves(default, null):Array<Move> = [{id:0}];
    public function update():Void {}
    public function collectMoves():Void {}
}
