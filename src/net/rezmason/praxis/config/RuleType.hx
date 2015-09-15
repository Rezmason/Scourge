package net.rezmason.praxis.config;

import net.rezmason.praxis.rule.Actor;

enum RuleType<Params> {
    Simple(actor:Actor<Params>, presenter:Dynamic);
    Builder(actor:Actor<Params>);
    Action(actor:Actor<Params>, presenter:Dynamic, movePresenter:Dynamic, isRandom:Dynamic->Bool);
}
