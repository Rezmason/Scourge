package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;

enum RuleType {
    Simple(rule:Rule, presenter:Dynamic);
    Builder(rule:Rule);
    Action(rule:Rule, presenter:Dynamic, movePresenter:Dynamic, isRandom:Dynamic->Bool);
}
