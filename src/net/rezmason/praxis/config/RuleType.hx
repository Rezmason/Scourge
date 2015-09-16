package net.rezmason.praxis.config;

import net.rezmason.praxis.rule.Actor;
import net.rezmason.praxis.rule.Builder;
import net.rezmason.praxis.rule.Surveyor;

enum RuleType<Params> {
    Simple(actor:Actor<Params>, presenter:Dynamic);
    Builder(builder:Builder<Params>);
    Action(builder:Builder<Params>, surveyor:Surveyor<Params>, actor:Actor<Params>, presenter:Dynamic, movePresenter:Dynamic, isRandom:Dynamic->Bool);
}
