package net.rezmason.scourge.game;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

typedef RP = #if HEADLESS Dynamic #else net.rezmason.scourge.controller.RulePresenter #end;
typedef MP = Dynamic;

typedef ScourgeConfig<Params> = Config<Params, RP, MP>;
typedef ScourgeRuleComposition<Params> = RuleComposition<Params, RP, MP>;
