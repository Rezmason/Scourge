package net.rezmason.praxis;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#else
import net.rezmason.praxis.aspect.IdentityAspect;
#end

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlan;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.pointers.Pointers;

#if !macro @:autoBuild(net.rezmason.praxis.Reckoner.build()) #end class Reckoner {

    var state:State;
    var plan:StatePlan;

    public var globalAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var playerAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var cardAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var spaceAspectRequirements(default, null):AspectRequirements = new AspectRequirements();
    public var extraAspectRequirements(default, null):AspectRequirements = new AspectRequirements();

    private var extraAspectTemplate:AspectSet = new AspectSet();
    private var extraAspectLookup:AspectLookup = new AspectLookup();
    private var ident_:AspectWritePtr;

    function __initRequirements():Void {}
    function __initPointers():Void {}
    
    public function new() __initRequirements();

    @:final public function primePointers(state, plan):Void {
        if (this.state != null) throw 'Reckoner was already primed.';
        this.state = state;
        this.plan = plan;


        var extraAspectSource:AspectSource = new AspectSource();
        extraAspectSource.add();

        for (id in extraAspectRequirements.keys().a2z()) {
            var prop:AspectProperty = extraAspectRequirements[id];
            var ptr:AspectWritePtr = extraAspectSource.add();
            extraAspectLookup[prop.id] = ptr;
            extraAspectTemplate[ptr] = prop.initialValue;
        }

        __initPointers();
        #if !macro ident_ = plan.onGlobal(IdentityAspect.IDENTITY); #end
    }

    @:final public function dismiss():Void {
        if (this.state == null) throw 'Reckoner was not yet primed.';
        this.state = null;
        this.plan = null;
    }

    @:final inline function getID(aspectSet:AspectSet):Int return aspectSet[ident_];
    @:final inline function getSpaceCell(space:AspectSet):BoardCell return getCell(getID(space));

    @:final inline function getSpace(index:Int):AspectSet return state.spaces[index];
    @:final inline function getCell(index:Int):BoardCell return state.cells.getCell(index);
    @:final inline function getPlayer(index:Int):AspectSet return state.players[index];
    @:final inline function getCard(index:Int):AspectSet return state.cards[index];
    @:final inline function getExtra(index:Int):AspectSet return state.extras[index];

    @:final inline function eachSpace():Iterator<AspectSet> return state.spaces.iterator();
    @:final inline function eachCell():Iterator<BoardCell> return state.cells.iterator();
    @:final inline function eachPlayer():Iterator<AspectSet> return state.players.iterator();
    @:final inline function eachCard():Iterator<AspectSet> return state.cards.iterator();
    @:final inline function eachExtra():Iterator<AspectSet> return state.extras.iterator();

    @:final inline function numSpaces():UInt return state.spaces.length;
    @:final inline function numCells():UInt return state.cells.length; // should be the same as numSpaces though
    @:final inline function numPlayers():UInt return state.players.length;
    @:final inline function numCards():UInt return state.cards.length;
    @:final inline function numExtras():UInt return state.extras.length;

    @:final inline function addGlobalAspectRequirement(req:AspectProperty):Void globalAspectRequirements [req.id] = req;
    @:final inline function addPlayerAspectRequirement(req:AspectProperty):Void playerAspectRequirements [req.id] = req;
    @:final inline function addSpaceAspectRequirement(req:AspectProperty):Void spaceAspectRequirements [req.id] = req;
    @:final inline function addCardAspectRequirement(req:AspectProperty):Void cardAspectRequirements [req.id] = req;

    @:final inline function onExtra(prop:AspectProperty) return extraAspectLookup[prop.id];
    @:final inline function extraDefaults() return extraAspectTemplate.copy();

    #if macro
    private static var lkpSources:Map<String, String> = [
        'global'=>'plan',
        'player'=>'plan',
        'space'=>'plan',
        'card'=>'plan',
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
        var declarations:Array<Expr> = [macro super.__initRequirements()];
        var assignments:Array<Expr> = [macro super.__initPointers()];

        for (field in fields) {

            if (restrictedFields.exists(field.name)) {
                throw new Error('Reckoners cannot manually override the function ${field.name}', field.pos);
            }

            for (metaTag in field.meta) {
                if (lkpSources[metaTag.name] != null) {
                    var kind:String = metaTag.name;
                    var name:String = field.name;
                    var aspect:Expr = metaTag.params[0];
                    var writable:Bool = false;
                    if (metaTag.params.length >= 2) {
                        switch (metaTag.params[1].expr) {
                            case EConst(CIdent(s)) if (s == 'true'): writable = true;
                            case _:
                        }
                    }
                    metaTag.params = [];

                    var kindLookup:String = 'on' + kind.charAt(0).toUpperCase() + kind.substr(1);
                    var kindRequirements:String = '${kind}AspectRequirements';

                    declarations.push(macro $i{kindRequirements}.set($aspect.id, $aspect));
                    assignments.push(macro $i{name} = $p{[lkpSources[kind], kindLookup]}($aspect));

                    if (writable) field.kind = FVar(macro :net.rezmason.praxis.PraxisTypes.AspectWritePtr, null);
                    else field.kind = FVar(macro :net.rezmason.praxis.PraxisTypes.AspectPtr, null);
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
