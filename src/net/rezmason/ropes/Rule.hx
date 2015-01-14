package net.rezmason.ropes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

import net.rezmason.ropes.RopesTypes;

#if !macro @:autoBuild(net.rezmason.ropes.Rule.build()) #end class Rule extends Reckoner {

    var historyState:State;
    var history:StateHistory;

    public var moves(default, null):Array<Move>;
    public var quantumMoves(default, null):Array<Move>;
    
    private function _prime():Void {}
    private function _init(config:Dynamic):Void {}
    private function _update():Void {}
    private function _chooseMove(choice:Int):Void {}
    private function _collectMoves():Void {}
    private function _chooseQuantumMove(choice:Int):Void {}

    private function signalEvent():Void {}

    var onSignal:String->Void;

    @:final public function init(config:Dynamic):Void {
        moves = [];
        quantumMoves = [];
        _init(config);
    }

    @:final public function prime(state, plan, history, historyState, ?onSignal):Void {
        this.history = history;
        this.historyState = historyState;
        this.onSignal = onSignal;

        primePointers(state, plan);

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

    @:final inline function addGlobals():AspectSet {
        var globals:AspectSet = plan.globalAspectTemplate.copy();
        globals[ident_] = 0;
        state.globals = globals;
        plan.globalAspectTemplate[ident_] = 0;
        historyState.globals = plan.globalAspectTemplate.map(history.alloc);
        return globals;
    }

    @:final inline function addPlayer():AspectSet {
        var player:AspectSet = plan.playerAspectTemplate.copy();
        var playerID:Int = numPlayers();
        player[ident_] = playerID;
        state.players.push(player);
        plan.playerAspectTemplate[ident_] = playerID;
        historyState.players.push(plan.playerAspectTemplate.map(history.alloc));
        return player;
    }

    @:final inline function addNode():AspectSet {
        var node:AspectSet = plan.nodeAspectTemplate.copy();
        var nodeID:Int = numNodes();
        node[ident_] = nodeID;
        state.nodes.push(node);
        plan.nodeAspectTemplate[ident_] = nodeID;
        historyState.nodes.push(plan.nodeAspectTemplate.map(history.alloc));

        var locus:BoardLocus = new BoardLocus(nodeID, node);
        state.loci.push(locus);
        
        return node;
    }

    @:final inline function addExtra():AspectSet {
        var extra:AspectSet = extraAspectTemplate.copy();
        var extraID:Int = numExtras();
        extra[ident_] = extraID;
        state.extras.push(extra);
        extraAspectTemplate[ident_] = extraID;
        historyState.extras.push(extraAspectTemplate.map(history.alloc));
        return extra;
    }

    #if macro
    private static var restrictedFields:Map<String, Bool> = [
        'prime' => true,
        'update' => true,
        'chooseMove' => true,
        'chooseQuantumMove' => true,
        'signalEvent' => true,
    ];
    #end

    macro public static function build():Array<Field> {
        var className:String = Context.getLocalClass().get().name;
        var msg:String = 'Rule processing $className  ';
        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();
        for (field in fields) {
            if (restrictedFields.exists(field.name)) {
                throw new Error('Rules cannot manually override the function ${field.name}', field.pos);
            }
        }

        msg += '\n';

        var signalEventBody:Expr = macro if (onSignal != null) onSignal($v{className});
        fields.push(overrider('signalEvent', [signalEventBody], pos));

        #if ROPES_MACRO_VERBOSE
            Sys.print(msg);
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
