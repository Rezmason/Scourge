package net.rezmason.praxis.config;

import net.rezmason.praxis.rule.BaseRule;

enum RuleType<Params> {
    Simple(rule:BaseRule<Params>, presenter:Dynamic);
    Builder(rule:BaseRule<Params>);
    Action(rule:BaseRule<Params>, presenter:Dynamic, movePresenter:Dynamic, isRandom:Dynamic->Bool);
}
