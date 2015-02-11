package net.rezmason.scourge.model;

import net.rezmason.ropes.RopesTypes;

typedef RuleComposition<Params, RulePresenter, MovePresenter> = {
    def:Class<Rule>,
    type:RuleType<MovePresenter>,
    presenter:Class<RulePresenter>,
    ?condition:Params->Bool
}
