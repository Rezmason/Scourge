package net.rezmason.praxis.config;

import net.rezmason.praxis.rule.Actor;
import net.rezmason.praxis.rule.Surveyor;

enum RuleType<Params> {
    Simple(actor:Actor<Params>, presenter:Dynamic);
    Builder(actor:Actor<Params>);
    Action(surveyor:Surveyor<Params>, actor:Actor<Params>, presenter:Dynamic, movePresenter:Dynamic, isRandom:Dynamic->Bool);
}
