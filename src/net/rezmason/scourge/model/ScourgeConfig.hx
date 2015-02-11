package net.rezmason.scourge.model;

import net.rezmason.scourge.model.bite.BiteAspect.*;
import net.rezmason.scourge.model.piece.SwapAspect.*;

import net.rezmason.scourge.model.bite.*;
import net.rezmason.scourge.model.body.*;
import net.rezmason.scourge.model.build.*;
import net.rezmason.scourge.model.meta.*;
import net.rezmason.scourge.model.piece.*;

typedef RP = Dynamic; // TODO
typedef MP = Dynamic; // TODO

class ScourgeConfig extends GameConfig<RP, MP> {

    public var biteParams(get, null):BiteParams;
    public var bodyParams(get, null):BodyParams;
    public var buildParams(get, null):BuildParams;
    public var metaParams(get, null):MetaParams;
    public var pieceParams(get, null):PieceParams;
    
    static var scourgeDefs:Map<String, Class<Config<Dynamic, RP, MP>>> = [
        'bite'  => BiteConfig,
        'body'  => BodyConfig,
        'build' => BuildConfig,
        'meta'  => MetaConfig,
        'piece' => PieceConfig,
    ];

    static var cleanUp:String = 'cleanUp';
    static var wrapUp:String = 'wrapUp';

    static var combinedDefs:Map<String, Array<String>> = [
        cleanUp     => ['decay', 'cavity', 'killHeadlessBody', 'oneLivingPlayer', 'resetFreshness'],
        wrapUp      => ['endTurn', 'replenish', 'pick'],
        'start'     => [cleanUp, 'pick'],
        'forfeit'   => ['forfeit', cleanUp, wrapUp],
        'drop'      => ['drop', 'eatCells', cleanUp, wrapUp, 'stalemate'],
        'swap'      => ['swap', 'pick'],
        'bite'      => ['bite', cleanUp],
    ];

    public function new() {
        
        super(scourgeDefs);

        metaParams.globalProperties[NUM_SWAPS.id] = { prop:NUM_SWAPS, amount:1, period:4, maxAmount:10 };
        metaParams.globalProperties[NUM_BITES.id] = { prop:NUM_BITES, amount:1, period:3, maxAmount:10 };
    }

    inline function get_biteParams():BiteParams return params['bite'];
    inline function get_bodyParams():BodyParams return params['body'];
    inline function get_buildParams():BuildParams return params['build'];
    inline function get_metaParams():MetaParams return params['meta'];
    inline function get_pieceParams():PieceParams return params['piece'];
}
