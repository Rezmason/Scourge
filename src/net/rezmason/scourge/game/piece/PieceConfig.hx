package net.rezmason.scourge.game.piece;

import net.rezmason.scourge.game.ConfigTypes;
import net.rezmason.utils.openfl.Resource;
import net.rezmason.praxis.config.RuleType;

class PieceConfig extends ScourgeConfig<PieceParams> {

    var pieces:Pieces;

    public function new() {
        super();
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    override function get_composition():Map<String, ScourgeRuleComposition<PieceParams>> {
        return [
            'swap' => {def:SwapPieceRule, type:Action(null), presenter:null, 
                isIncluded:function(p) return !p.allowAllPieces && p.allowSwapping,
            },
            'pick' => {def:PickPieceRule, type:Action(null), presenter:null, 
                isIncluded:function(p) return !p.allowAllPieces,
                isRandom:function(p) return !p.allowPiecePick,
            },
            'drop' => {def:DropPieceRule, type:Action(null), presenter:null},
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
