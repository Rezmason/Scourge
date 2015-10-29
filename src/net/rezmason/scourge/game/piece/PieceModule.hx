package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.utils.openfl.Resource;

#if !HEADLESS
    import net.rezmason.scourge.controller.DropPieceRulePresenter;
#end

class PieceModule extends Module<PieceParams> {

    var pieceLib:PieceLibrary;

    public function new() {
        super();
        pieceLib = new PieceLibrary(Resource.getString('tables/pieces.json.txt'));
    }

    override public function composeRules():Map<String, RuleComposition<PieceParams>> {
        return [
            'swap' => {type:Action(null, new SwapPieceSurveyor(), new SwapPieceActor(), null, null, null), 
                isIncluded:function(p) return !p.allowAllPieces && p.allowSwapping,
            },
            'pick' => {type:Action(new PickPieceBuilder(), new PickPieceSurveyor(), new PickPieceActor(), null, null, function(p) return !p.allowPiecePick), 
                isIncluded:function(p) return !p.allowAllPieces,
            },
            'drop' => {type:Action(null, new DropPieceSurveyor(), new DropPieceActor(), #if HEADLESS null #else new DropPieceRulePresenter() #end, null, null)},
        ];
    }

    override public function makeDefaultParams() {
        return {
            allowFlipping:false,
            allowRotating:true,
            pieceTableIDs:pieceLib.getAllPieceIDsOfSize(4),
            pieceLib:pieceLib,

            hatSize:5,

            dropOverlapsSelf:false,
            dropOrthoOnly:true,
            dropDiagOnly:false,
            allowPiecePick:false,
            allowSkipping:false,

            startingSwaps:5,

            allowAllPieces:false,
            allowSwapping:true,
            pieceMoves:null,
        };
    }
}
