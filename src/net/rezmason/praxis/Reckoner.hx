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

#if !macro @:autoBuild(net.rezmason.praxis.Reckoner.build()) #end class Reckoner {

    var state:State;
    var plan:StatePlan;

    public var globalAspectRequirements(default, null):AspectRequirements<PGlobal> = new AspectRequirements();
    public var playerAspectRequirements(default, null):AspectRequirements<PPlayer> = new AspectRequirements();
    public var cardAspectRequirements(default, null):AspectRequirements<PCard> = new AspectRequirements();
    public var spaceAspectRequirements(default, null):AspectRequirements<PSpace> = new AspectRequirements();
    public var extraAspectRequirements(default, null):AspectRequirements<PExtra> = new AspectRequirements();

    private var extraAspectTemplate:Extra = new AspectPointable();
    private var extraAspectLookup:AspectLookup<PExtra> = new AspectLookup();
    
    private var globalIdent_:AspectWritePointer<PGlobal>;
    private var playerIdent_:AspectWritePointer<PPlayer>;
    private var cardIdent_:AspectWritePointer<PCard>;
    private var spaceIdent_:AspectWritePointer<PSpace>;
    private var extraIdent_:AspectWritePointer<PExtra>;

    function __initRequirements() {}
    function __initPointers() {}
    
    public function new() __initRequirements();

    @:final public function primePointers(state, plan) {
        this.state = state;
        this.plan = plan;

        #if !macro 
            globalIdent_ = plan.onGlobal(IdentityAspect.IDENTITY);
            playerIdent_ = plan.onPlayer(IdentityAspect.IDENTITY);
            cardIdent_ = plan.onCard(IdentityAspect.IDENTITY);
            spaceIdent_ = plan.onSpace(IdentityAspect.IDENTITY);
        #end

        var extraAspectSource:AspectSource<PExtra> = new AspectSource();
        extraIdent_ = extraAspectSource.add();

        for (id in extraAspectRequirements.keys().a2z()) {
            var prop = extraAspectRequirements[id];
            var ptr = extraAspectSource.add();
            extraAspectLookup[prop.id] = ptr;
            extraAspectTemplate[ptr] = prop.initialValue;
        }

        __initPointers();
    }

    @:final public function dismiss() {
        if (this.state == null) throw 'Reckoner was not yet primed.';
        this.state = null;
        this.plan = null;
    }

    @:final inline function getID<T>(aspectPointable:AspectPointable<T>):Int return aspectPointable[cast globalIdent_];
    @:final inline function getSpaceCell(space) return getCell(getID(space));

    @:final inline function getSpace(index) return state.spaces[index];
    @:final inline function getCell(index) return state.cells.getCell(index);
    @:final inline function getPlayer(index) return state.players[index];
    @:final inline function getCard(index) return state.cards[index];
    @:final inline function getExtra(index) return state.extras[index];

    @:final inline function eachSpace() return state.spaces.iterator();
    @:final inline function eachCell() return state.cells.iterator();
    @:final inline function eachPlayer() return state.players.iterator();
    @:final inline function eachCard() return state.cards.iterator();
    @:final inline function eachExtra() return state.extras.iterator();

    @:final inline function numSpaces() return state.spaces.length;
    @:final inline function numCells() return state.cells.length; // should be the same as numSpaces though
    @:final inline function numPlayers() return state.players.length;
    @:final inline function numCards() return state.cards.length;
    @:final inline function numExtras() return state.extras.length;

    @:final inline function addGlobalAspectRequirement(prop:AspectProperty<PGlobal>) globalAspectRequirements [prop.id] = prop;
    @:final inline function addPlayerAspectRequirement(prop:AspectProperty<PPlayer>) playerAspectRequirements [prop.id] = prop;
    @:final inline function addSpaceAspectRequirement(prop:AspectProperty<PSpace>) spaceAspectRequirements [prop.id] = prop;
    @:final inline function addCardAspectRequirement(prop:AspectProperty<PCard>) cardAspectRequirements [prop.id] = prop;

    @:final inline function onExtra(prop:AspectProperty<PExtra>) return extraAspectLookup[prop.id];
    @:final inline function extraDefaults() return extraAspectTemplate.copy();

    #if macro
    private static var lkpSources:Map<String, String> = [
        'global'=>'plan',
        'player'=>'plan',
        'space'=>'plan',
        'card'=>'plan',
        'extra'=>'this',
    ];

    private static var ptrTypes:Map<String, ComplexType> = [
        'global'=> macro :net.rezmason.praxis.PraxisTypes.PGlobal,
        'player'=> macro :net.rezmason.praxis.PraxisTypes.PPlayer,
        'space'=> macro :net.rezmason.praxis.PraxisTypes.PSpace,
        'card'=> macro :net.rezmason.praxis.PraxisTypes.PCard,
        'extra'=> macro :net.rezmason.praxis.PraxisTypes.PExtra,
    ];

    private static var restrictedFields:Map<String, Bool> = [ 
        '__initRequirements' => true, 
        '__initPointers' => true, 
    ];
    #end

    macro public static function build():Array<Field> {
        var className:String = Context.getLocalClass().get().name;
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
                    var ptrType = ptrTypes[kind];

                    declarations.push(macro $i{kindRequirements}.set($aspect.id, $aspect));
                    assignments.push(macro $i{name} = $p{[lkpSources[kind], kindLookup]}($aspect));

                    if (writable) {
                        field.kind = FVar(macro :net.rezmason.praxis.PraxisTypes.AspectWritePointer<$ptrType>, null);
                    } else {
                        field.kind = FVar(macro :net.rezmason.praxis.PraxisTypes.AspectPointer<$ptrType>, null);
                    }
                    field.access.remove(AStatic);
                    break;
                }
            }
        }

        fields.push(overrider('__initRequirements', declarations, pos));
        fields.push(overrider('__initPointers', assignments, pos));

        return fields;
    }

    #if macro
    private inline static function overrider(name:String, expressions:Array<Expr>, pos:Position):Field {
        var func:Function = {params:[], args:[], ret:null, expr:macro $b{expressions}};
        return { name:name, access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
    #end
}
