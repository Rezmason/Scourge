package net.rezmason.ropes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
#end

import net.rezmason.ropes.Types;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.Pointers;

#if !macro @:autoBuild(net.rezmason.ropes.Rule.build()) #end class Rule {

    var state:State;
    var plan:StatePlan;

    public var demiurgic(default, null):Bool;
    public var moves(default, null):Array<Move>;
    public var quantumMoves(default, null):Array<Move>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;
    public var extraAspectRequirements(default, null):AspectRequirements;

    private var extraAspectTemplate:AspectSet;
    private var extraAspectLookup:AspectLookup;
    private var ident_:AspectPtr;

    private function _prime():Void {}
    private function _update():Void {}
    private function _chooseMove(choice:Int):Void {}
    private function _collectMoves():Void {}
    private function _chooseQuantumMove(choice:Int):Void {}

    private function __initReqs():Void {}
    private function __initPtrs():Void {}

    function new():Void {
        demiurgic = false;
        stateAspectRequirements = new AspectRequirements();
        playerAspectRequirements = new AspectRequirements();
        nodeAspectRequirements = new AspectRequirements();
        extraAspectRequirements = new AspectRequirements();
        extraAspectTemplate = new AspectSet();
        extraAspectLookup = new AspectLookup();
        moves = [];
        quantumMoves = [];
        __initReqs();
    }

    @:final public function prime(state:State, plan:StatePlan):Void {
        this.state = state;
        this.plan = plan;

        ident_ = Ptr.intToPointer(0, state.key);

        var itr:Int = 0;
        for (id in extraAspectRequirements.keys().a2z()) {
            var prop:AspectProperty = extraAspectRequirements[id];
            var ptr:AspectPtr = extraAspectTemplate.ptr(itr, state.key);
            extraAspectLookup[prop.id] = ptr;
            extraAspectTemplate[ptr] = prop.initialValue;
            itr++;
        }

        __initPtrs();
        #if ROPES_VERBOSE trace('${myName()} initializing'); #end
        _prime();
    }

    @:final public function update():Void {
        #if ROPES_VERBOSE trace('${myName()} updating'); #end
        _update();
    }

    @:final public function chooseMove(choice:Int = -1):Void {
        var defaultChoice:Bool = choice == -1;
        if (defaultChoice) choice = 0;

        if (moves == null || moves.length < choice || moves[choice] == null) {
            throw 'Invalid choice index.';
        }
        #if ROPES_VERBOSE
            if (defaultChoice) trace('${myName()} choosing default move');
            else trace('${myName()} choosing move $choice');
        #end
        _chooseMove(choice);
    }

    @:final public function collectMoves():Void {
        _collectMoves();
    }

    @:final public function chooseQuantumMove(choice:Int):Void {
        if (quantumMoves == null || quantumMoves.length < choice || quantumMoves[choice] == null) {
            throw 'Invalid choice index.';
        }
        #if ROPES_VERBOSE trace('${myName()}choosing quantum move $choice'); #end
        _chooseQuantumMove(choice);
    }

    @:final inline function myName():String {
        var name:String = Type.getClassName(Type.getClass(this));
        name = name.substr(name.lastIndexOf('.') + 1);
        return name;
    }

    @:final inline function buildExtra():AspectSet {
        return extraAspectTemplate.copy();
    }

    @:final inline function buildHistExtra(history:StateHistory):AspectSet {
        return extraAspectTemplate.map(history.alloc);
    }

    @:final inline function getID(aspectSet:AspectSet):Int { return aspectSet[ident_]; }
    @:final inline function getNodeLocus(node:AspectSet):BoardLocus { return getLocus(getID(node)); }

    // Are these still necessary?
    @:final inline function statePtr(prop:AspectProperty):AspectPtr { return plan.stateAspectLookup[prop.id]; }
    @:final inline function playerPtr(prop:AspectProperty):AspectPtr { return plan.playerAspectLookup[prop.id]; }
    @:final inline function nodePtr(prop:AspectProperty):AspectPtr { return plan.nodeAspectLookup[prop.id]; }
    @:final inline function extraPtr(prop:AspectProperty):AspectPtr { return extraAspectLookup[prop.id]; }

    @:final inline function getNode(index:Int):AspectSet { return state.nodes[index]; }
    @:final inline function getLocus(index:Int):BoardLocus { return state.loci[index]; }
    @:final inline function getPlayer(index:Int):AspectSet { return state.players[index]; }
    @:final inline function getExtra(index:Int):AspectSet { return state.extras[index]; }

    @:final inline function eachNode():Iterator<AspectSet> { return state.nodes.iterator(); }
    @:final inline function eachLocus():Iterator<BoardLocus> { return state.loci.iterator(); }
    @:final inline function eachPlayer():Iterator<AspectSet> { return state.players.iterator(); }
    @:final inline function eachExtra():Iterator<AspectSet> { return state.extras.iterator(); }

    @:final inline function numNodes():Int { return state.nodes.length; }
    @:final inline function numLoci():Int { return state.loci.length; } // should be the same as numNodes though
    @:final inline function numPlayers():Int { return state.players.length; }
    @:final inline function numExtras():Int { return state.extras.length; }

    @:final inline function addStateAspectRequirement(req:AspectProperty):Void stateAspectRequirements [req.id] = req;
    @:final inline function addPlayerAspectRequirement(req:AspectProperty):Void playerAspectRequirements [req.id] = req;
    @:final inline function addNodeAspectRequirement(req:AspectProperty):Void nodeAspectRequirements [req.id] = req;

    #if macro
    private static var lkpSources:Map<String, String> = [
        'state'=>'plan',
        'player'=>'plan',
        'node'=>'plan',
        'extra'=>'this',
    ];

    private static var restrictedFields:Array<String> = [
        '__initReqs', '__initPointers',
        'prime',
        'update',
        'chooseMove',
        'chooseQuantumMove',
    ];
    #end

    macro public static function build():Array<Field> {

        var msg:String = 'Building ${Context.getLocalClass().get().name}  ';

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        var declarations:Array<Expr> = [];
        var assignments:Array<Expr> = [];

        for (field in fields) {

            if (restrictedFields.has(field.name)) {
                throw new Error('Rules cannot manually override the function ${field.name}', field.pos);
            }

            for (metaTag in field.meta) {
                if (lkpSources.exists(metaTag.name)) {
                    var kind:String = metaTag.name;
                    var name:String = field.name;
                    var aspect:Expr = metaTag.params[0];
                    metaTag.params = [];

                    var kindLookup:String = '${kind}AspectLookup';
                    var kindRequirements:String = '${kind}AspectRequirements';

                    declarations.push(macro $i{kindRequirements}.set($aspect.id, $aspect));
                    assignments.push(macro $i{name} = $p{[lkpSources[kind], kindLookup]}[$aspect.id]);

                    field.kind = FVar(macro :net.rezmason.ropes.Types.AspectPtr, null);
                    field.access.remove(AStatic);

                    msg += kind.charAt(0);

                    break;
                }
            }
        }

        msg += '\n';

        fields.push(overrider('__initReqs', declarations, pos));
        fields.push(overrider('__initPtrs', assignments, pos));

        #if ROPES_MACRO_VERBOSE
            neko.Lib.print(msg);
        #end

        return fields;
    }

    #if macro
    private inline static function overrider(name:String, expressions:Array<Expr>, pos:Position):Field {
        var func:Function = {params:[], args:[], ret:null, expr:macro $b{expressions}};
        return { name:name, access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
    #end
}

