package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;

typedef RuleComposition<Params> = {
    type:RuleType,
    ?isIncluded:Params->Bool
}
