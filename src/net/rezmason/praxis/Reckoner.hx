package net.rezmason.praxis;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlan;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

#if !macro @:autoBuild(net.rezmason.praxis.Reckoner.build()) #end class Reckoner {

    var state:State;
    var plan:StatePlan;

    public var globalAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var playerAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var nodeAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var extraAspectRequirements(default, null):AspectRequirements = new AspectRequirements();

    private var extraAspectTemplate:AspectSet = new AspectSet();
    private var extraAspectLookup:AspectLookup = new AspectLookup();
    private var ident_:AspectPtr;

    function __initRequirements():Void {}
    function __initPointers():Void {}
    
    @:final public function new() __initRequirements();

    @:final public function primePointers(state, plan):Void {
        if (this.state != null) throw 'Reckoner was already primed.';
        this.state = state;
        this.plan = plan;

        ident_ = Ptr.intToPointer(0, state.key);

        var itr:Int = 1; // Index 0 is reserved for the aspects' ID
        for (id in extraAspectRequirements.keys().a2z()) {
            var prop:AspectProperty = extraAspectRequirements[id];
            var ptr:AspectPtr = extraAspectTemplate.ptr(itr, state.key);
            extraAspectLookup[prop.id] = ptr;
            extraAspectTemplate[ptr] = prop.initialValue;
            itr++;
        }

        __initPointers();
    }

    @:final inline function getID(aspectSet:AspectSet):Int return aspectSet[ident_];
    @:final inline function getNodeLocus(node:AspectSet):BoardLocus return getLocus(getID(node));

    @:final inline function getNode(index:Int):AspectSet return state.nodes[index];
    @:final inline function getLocus(index:Int):BoardLocus return state.loci[index];
    @:final inline function getPlayer(index:Int):AspectSet return state.players[index];
    @:final inline function getExtra(index:Int):AspectSet return state.extras[index];

    @:final inline function eachNode():Iterator<AspectSet> return state.nodes.iterator();
    @:final inline function eachLocus():Iterator<BoardLocus> return state.loci.iterator();
    @:final inline function eachPlayer():Iterator<AspectSet> return state.players.iterator();
    @:final inline function eachExtra():Iterator<AspectSet> return state.extras.iterator();

    @:final inline function numNodes():Int return state.nodes.length;
    @:final inline function numLoci():Int return state.loci.length; // should be the same as numNodes though
    @:final inline function numPlayers():Int return state.players.length;
    @:final inline function numExtras():Int return state.extras.length;

    @:final inline function addGlobalAspectRequirement(req:AspectProperty):Void globalAspectRequirements [req.id] = req;
    @:final inline function addPlayerAspectRequirement(req:AspectProperty):Void playerAspectRequirements [req.id] = req;
    @:final inline function addNodeAspectRequirement(req:AspectProperty):Void nodeAspectRequirements [req.id] = req;

    #if macro
    private static var lkpSources:Map<String, String> = [
        'global'=>'plan',
        'player'=>'plan',
        'node'=>'plan',
        'extra'=>'this',
    ];

    private static var restrictedFields:Map<String, Bool> = [ 
        '__initRequirements' => true, 
        '__initPointers' => true, 
    ];
    #end

    macro public static function build():Array<Field> {
        var className:String = Context.getLocalClass().get().name;
        var msg:String = 'Reckoner processing $className  ';
        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();
        var declarations:Array<Expr> = [];
        var assignments:Array<Expr> = [];

        for (field in fields) {

            if (restrictedFields.exists(field.name)) {
                throw new Error('Reckoners cannot manually override the function ${field.name}', field.pos);
            }

            for (metaTag in field.meta) {
                if (lkpSources[metaTag.name] != null) {
                    var kind:String = metaTag.name;
                    var name:String = field.name;
                    var aspect:Expr = metaTag.params[0];
                    metaTag.params = [];

                    var kindLookup:String = '${kind}AspectLookup';
                    var kindRequirements:String = '${kind}AspectRequirements';

                    declarations.push(macro $i{kindRequirements}.set($aspect.id, $aspect));
                    assignments.push(macro $i{name} = $p{[lkpSources[kind], kindLookup]}[$aspect.id]);

                    field.kind = FVar(macro :net.rezmason.praxis.PraxisTypes.AspectPtr, null);
                    field.access.remove(AStatic);

                    msg += kind.charAt(0);

                    break;
                }
            }
        }

        msg += '\n';

        fields.push(overrider('__initRequirements', declarations, pos));
        fields.push(overrider('__initPointers', assignments, pos));

        #if PRAXIS_MACRO_VERBOSE
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
