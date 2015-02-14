package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.scourge.tools.Resource;

class PieceConfig<RP, MP> extends Config<PieceParams, RP, MP> {

    var pieces:Pieces;

    public function new() {
        super();
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    override public function composition():Map<String, RuleComposition<PieceParams, RP, MP>> {
        return [
            'swap' => {def:SwapPieceRule, type:Action(null), presenter:null, 
                isIncluded:function(p) return !p.allowAllPieces && p.allowSwapping,
            },
            'pick' => {def:PickPieceRule, type:Action(null), presenter:null, 
                isIncluded:function(p) return !p.allowAllPieces,
                isRandom:function(p) return true,
            },
            'drop' => {def:DropPieceRule, type:Action(null), presenter:null},
        ];
    }

    override public function defaultParams():Null<PieceParams> {
        return {
            allowFlipping:false,
            allowRotating:true,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            pieces:pieces,

            hatSize:5,

            dropOverlapsSelf:false,
            dropOrthoOnly:true,
            dropGrowsGraph:false,
            dropDiagOnly:false,
            allowPiecePick:false,
            allowSkipping:false,

            startingSwaps:5,

            allowAllPieces:false,
            allowSwapping:true,
        };
    }
}
