package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.utils.openfl.Resource;

#if !HEADLESS
    import net.rezmason.scourge.controller.DropPieceRulePresenter;
#end

class PieceConfig extends Config<PieceParams> {

    var pieces:Pieces;

    public function new() {
        super();
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    override function get_composition():Map<String, RuleComposition<PieceParams>> {
        return [
            'swap' => {type:Action(new SwapPieceRule(), null, null, null), 
                isIncluded:function(p) return !p.allowAllPieces && p.allowSwapping,
            },
            'pick' => {type:Action(new PickPieceRule(), null, null, function(p) return !p.allowPiecePick), 
                isIncluded:function(p) return !p.allowAllPieces,
            },
            'drop' => {type:Action(new DropPieceRule(), #if HEADLESS null #else new DropPieceRulePresenter() #end, null, null)},
        ];
    }

    override function get_defaultParams() {
        return {
            allowFlipping:false,
            allowRotating:true,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            pieces:pieces,

            hatSize:5,

            dropOverlapsSelf:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            allowPiecePick:false,
            allowSkipping:false,

            startingSwaps:5,

            allowAllPieces:false,
            allowSwapping:true,
        };
    }
}
