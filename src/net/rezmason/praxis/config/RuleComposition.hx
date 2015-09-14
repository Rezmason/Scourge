package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;

typedef RuleComposition<Params, RulePresenter, MovePresenter> = {
    def:Rule,
    type:RuleType<MovePresenter>,
    presenter:RulePresenter,
    ?isIncluded:Params->Bool,
    ?isRandom:Params->Bool,
}
