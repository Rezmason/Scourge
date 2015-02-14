package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;

typedef RuleComposition<Params, RulePresenter, MovePresenter> = {
    def:Class<Rule>,
    type:RuleType<MovePresenter>,
    presenter:Class<RulePresenter>,
    ?isIncluded:Params->Bool,
    ?isRandom:Params->Bool,
}
