package net.rezmason.scourge.game;

import net.rezmason.praxis.config.GameConfig;

import net.rezmason.scourge.game.bite.BiteAspect.*;
import net.rezmason.scourge.game.piece.SwapAspect.*;

import net.rezmason.scourge.game.ConfigTypes;
import net.rezmason.scourge.game.bite.*;
import net.rezmason.scourge.game.body.*;
import net.rezmason.scourge.game.build.*;
import net.rezmason.scourge.game.meta.*;
import net.rezmason.scourge.game.piece.*;

class ScourgeGameConfig extends GameConfig<RP, MP> {

    public var biteParams(get, null):BiteParams;
    public var bodyParams(get, null):BodyParams;
    public var buildParams(get, null):BuildParams;
    public var metaParams(get, null):MetaParams;
    public var pieceParams(get, null):PieceParams;
    
    public function new() {
        
        configDefs = [
            'bite'  => BiteConfig,
            'body'  => BodyConfig,
            'build' => BuildConfig,
            'meta'  => MetaConfig,
            'piece' => PieceConfig,
        ];

        jointRuleDefs = [
            {id:'cleanUp',  sequence:['decay', 'cavity', 'killHeadlessBody', 'oneLivingPlayer', 'resetFreshness']},
            {id:'wrapUp',   sequence:['endTurn', 'replenish']}, /*'pick'*/
            {id:'start',    sequence:['cleanUp']}, /*'pick'*/
            {id:'forfeit',  sequence:['forfeit', 'cleanUp', 'wrapUp']},
            {id:'drop',     sequence:['drop', 'eatCells', 'cleanUp', 'wrapUp', 'stalemate']},
            {id:'swap',     sequence:['swap']}, /*'pick'*/
            {id:'bite',     sequence:['bite', 'cleanUp']},
            {id:'build',    sequence:['buildGlobal', 'buildPlayers', 'buildBoard']},
        ];

        defaultActionIDs = ['drop', 'forfeit'];

        fallbackRP = #if HEADLESS null #else RP #end;
        fallbackMP = null;

        parseConfigDefs();
        metaParams.globalProperties[NUM_SWAPS.id] = { prop:NUM_SWAPS, amount:1, period:4, maxAmount:10 };
        metaParams.globalProperties[NUM_BITES.id] = { prop:NUM_BITES, amount:1, period:3, maxAmount:10 };
    }

    inline function get_biteParams():BiteParams return params['bite'];
    inline function get_bodyParams():BodyParams return params['body'];
    inline function get_buildParams():BuildParams return params['build'];
    inline function get_metaParams():MetaParams return params['meta'];
    inline function get_pieceParams():PieceParams return params['piece'];
}
