package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;

typedef BuildConfig = {
    public var history:StateHistory;
    public var historyState:State;
}

class BuildRule extends Rule {



    inline function buildAspectSet(template:AspectSet):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(val);
        return aspects;
    }

    inline function buildHistAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(history.alloc(val));
        return aspects;
    }
}

