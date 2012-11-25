package net.rezmason.scourge.model;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
#end

import net.rezmason.scourge.model.ModelTypes;

using net.rezmason.utils.Pointers;

#if !macro @:autoBuild(net.rezmason.scourge.model.Rule.build()) #end class Rule {

    var state:State;
    var plan:StatePlan;

    public var demiurgic(default, null):Bool;
    public var options(default, null):Array<Option>;
    public var quantumOptions(default, null):Array<Option>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;
    public var extraAspectRequirements(default, null):AspectRequirements;

    private var extraAspectTemplate:AspectSet;
    private var extraAspectLookup:AspectLookup;

    public function new():Void {
        demiurgic = false;
        stateAspectRequirements = [];
        playerAspectRequirements = [];
        nodeAspectRequirements = [];
        extraAspectRequirements = [];
        extraAspectTemplate = [];
        extraAspectLookup = [];
        options = [];
        quantumOptions = [];
        __initReqs();
    }

    @final public function prime(state:State, plan:StatePlan):Void {
        this.state = state;
        this.plan = plan;

        for (ike in 0...extraAspectRequirements.length) {
            var prop:AspectProperty = extraAspectRequirements[ike];
            extraAspectLookup[prop.id] = ike.pointerArithmetic();
            extraAspectTemplate[ike] = prop.initialValue;
        }
        __initPtrs();
        init();
    }

    public function init():Void {}

    private function __initReqs():Void {}
    private function __initPtrs():Void {}

    // Note: Rules *should not* change the State during the update function.
    public function update():Void {}

    public function chooseOption(choice:Int = 0):Void {
        if (options == null || options.length < choice || options[choice] == null) {
            throw "Invalid choice index.";
        }
    }

    public function chooseQuantumOption(choice:Int):Void {
        if (quantumOptions == null || quantumOptions.length < choice || quantumOptions[choice] == null) {
            throw "Invalid choice index.";
        }
    }

    inline function buildAspectSet(template:AspectSet):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(val);
        return aspects;
    }

    @final inline function buildHistAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(history.alloc(val));
        return aspects;
    }

    @final inline function buildExtra():AspectSet {
        return buildAspectSet(extraAspectTemplate);
    }

    @final inline function buildHistExtra(history:StateHistory):AspectSet {
        return buildHistAspectSet(extraAspectTemplate, history);
    }

    // Are these still necessary?
    @final inline function statePtr(prop:AspectProperty):AspectPtr { return plan.stateAspectLookup[prop.id]; }
    @final inline function playerPtr(prop:AspectProperty):AspectPtr { return plan.playerAspectLookup[prop.id]; }
    @final inline function nodePtr(prop:AspectProperty):AspectPtr { return plan.nodeAspectLookup[prop.id]; }
    @final inline function extraPtr(prop:AspectProperty):AspectPtr { return extraAspectLookup[prop.id]; }

    #if macro
    private static var lkpSources:Hash<String> = {
        var hash:Hash<String> = new Hash<String>();
        hash.set("state",  "plan");
        hash.set("player", "plan");
        hash.set("node",   "plan");
        hash.set("extra",  "this");
        hash;
    }

    private static var restrictedFields:Array<String> = [ "__initReqs", "__initPointers", ];
    #end

    @:macro public static function build():Array<Field> {

        var msg:String = "Building " + Context.getLocalClass().get().name + "  ";

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        var reqExpressions:Array<Expr> = [];
        var ptrExpressions:Array<Expr> = [];

        for (field in fields) {

            if (restrictedFields.has(field.name)) {
                throw new Error("Rules cannot manually override the function " + field.name, field.pos);
            }

            for (metaTag in field.meta) {
                if (lkpSources.exists(metaTag.name)) {

                    var aspectExpr:Expr = metaTag.params[0];
                    metaTag.params = [];

                    field.access.remove(AStatic);

                    var reqs:Expr = Context.parse(metaTag.name + "AspectRequirements", pos);
                    var ptr:Expr = Context.parse(field.name, pos);
                    var lkp:Expr = Context.parse(lkpSources.get(metaTag.name) + "." + metaTag.name + "AspectLookup", pos);

                    reqExpressions.push( macro $reqs.push($aspectExpr) );
                    ptrExpressions.push( macro $ptr = $lkp[$aspectExpr.id] );

                    //neko.Lib.println(macro :net.rezmason.scourge.model.ModelTypes.AspectPtr);

                    field.kind = FVar(macro :net.rezmason.scourge.model.ModelTypes.AspectPtr, null);

                    msg += metaTag.name.charAt(0);

                    break;
                }
            }
        }

        msg += "\n";

        fields.push(overrider("__initReqs", reqExpressions, pos));
        fields.push(overrider("__initPtrs", ptrExpressions, pos));

        #if SCOURGE_VERBOSE
            neko.Lib.print(msg);
        #end

        return fields;
    }

    #if macro
    private inline static function overrider(name:String, expressions:Array<Expr>, pos:Position):Field {
        var func:Function = {params:[], args:[], ret:null, expr:{pos:pos, expr:EBlock(expressions)}};
        return { name:name, access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
    #end
}

