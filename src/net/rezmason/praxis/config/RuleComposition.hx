package net.rezmason.praxis.config;

typedef RuleComposition<Params> = {
    type:RuleType<Dynamic>,
    ?isIncluded:Params->Bool
}
