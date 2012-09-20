package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;

using net.rezmason.utils.Pointers;

typedef BuildConfig = {
    public var history:StateHistory;
    public var historyState:State;
}

class BuildRule extends Rule {

    public var extraAspectRequirements(default, null):AspectRequirements;

    private var extraAspectTemplate:AspectSet;
    private var extraAspectLookup:AspectLookup;

    public function new():Void {
        super();
        extraAspectRequirements = [];
        extraAspectTemplate = [];
        extraAspectLookup = [];
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);

        // set up extra template and lookup
        for (ike in 0...extraAspectRequirements.length) {
            var prop:AspectProperty = extraAspectRequirements[ike];
            extraAspectLookup[prop.id] = ike.pointerArithmetic();
            extraAspectTemplate[ike] = prop.initialValue;
        }
    }

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

    inline function extraPtr(prop:AspectProperty):AspectPtr { return extraAspectLookup[prop.id]; }

    inline function buildExtra():AspectSet {
        return buildAspectSet(extraAspectTemplate);
    }

    inline function buildHistExtra(history:StateHistory):AspectSet {
        return buildHistAspectSet(extraAspectTemplate, history);
    }
}

