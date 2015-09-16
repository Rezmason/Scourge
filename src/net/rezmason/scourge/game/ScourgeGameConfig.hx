package net.rezmason.scourge.game;

import net.rezmason.praxis.config.GameConfig;

import net.rezmason.scourge.game.bite.BiteAspect;
import net.rezmason.scourge.game.piece.SwapAspect;

import net.rezmason.scourge.game.bite.BiteModule;
import net.rezmason.scourge.game.bite.BiteParams;
import net.rezmason.scourge.game.body.BodyModule;
import net.rezmason.scourge.game.body.BodyParams;
import net.rezmason.scourge.game.build.BuildModule;
import net.rezmason.scourge.game.build.BuildParams;
import net.rezmason.scourge.game.meta.MetaModule;
import net.rezmason.scourge.game.meta.MetaParams;
import net.rezmason.scourge.game.piece.PieceModule;
import net.rezmason.scourge.game.piece.PieceParams;

typedef RP = #if HEADLESS Dynamic #else net.rezmason.scourge.controller.RulePresenter #end;
typedef MP = Dynamic;

class ScourgeGameConfig extends GameConfig<RP, MP> {

    public var biteParams(get, null):BiteParams;
    public var bodyParams(get, null):BodyParams;
    public var buildParams(get, null):BuildParams;
    public var metaParams(get, null):MetaParams;
    public var pieceParams(get, null):PieceParams;
    
    public function new() {
        
        modules = [
            'bite'  => new BiteModule(),
            'body'  => new BodyModule(),
            'build' => new BuildModule(),
            'meta'  => new MetaModule(),
            'piece' => new PieceModule(),
        ];

        jointRuleDefs = [
            {id:'cleanUp',  sequence:['decay', 'cavity', 'killHeadlessBody', 'oneLivingPlayer', 'resetFreshness']},
            {id:'wrapUp',   sequence:['endTurn', 'replenish']}, /*'pick'*/
            {id:'start',    sequence:['cleanUp']}, /*'pick'*/
            {id:'forfeit',  sequence:['forfeit', 'cleanUp', 'wrapUp']},
            {id:'drop',     sequence:['drop', 'eat', 'cleanUp', 'wrapUp', 'stalemate']},
            {id:'swap',     sequence:['swap']}, /*'pick'*/
            {id:'bite',     sequence:['bite', 'cleanUp']},
            {id:'build',    sequence:['buildGlobal', 'buildPlayers', 'buildBoard']},
        ];

        defaultActionIDs = ['drop', 'forfeit'];

        parseModules();
        metaParams.globalProperties[SwapAspect.NUM_SWAPS.id] = { prop:SwapAspect.NUM_SWAPS, amount:1, period:4, maxAmount:10 };
        metaParams.globalProperties[BiteAspect.NUM_BITES.id] = { prop:BiteAspect.NUM_BITES, amount:1, period:3, maxAmount:10 };
    }

    inline function get_biteParams():BiteParams return params['bite'];
    inline function get_bodyParams():BodyParams return params['body'];
    inline function get_buildParams():BuildParams return params['build'];
    inline function get_metaParams():MetaParams return params['meta'];
    inline function get_pieceParams():PieceParams return params['piece'];
}
