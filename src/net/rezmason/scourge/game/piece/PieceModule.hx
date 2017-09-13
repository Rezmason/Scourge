package net.rezmason.scourge.game.piece;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.praxis.config.RuleType;
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
        var rules:Map<String, RuleComposition<PieceParams>> = new Map();
        rules['swap'] = {
            type:Action(null, new SwapPieceSurveyor(), new SwapPieceActor(), null, null, null), 
            isIncluded:function(p:PieceParams) return (!p.allowAllPieces && p.allowSwapping) == true,
        };
        rules['pick'] = {
            type:Action(new PickPieceBuilder(), new PickPieceSurveyor(), new PickPieceActor(), null, null, function(p) return !p.allowPiecePick), 
            isIncluded:function(p:PieceParams) return !p.allowAllPieces,
        };
        rules['drop'] = {
            type:Action(null, new DropPieceSurveyor(), new DropPieceActor(), #if HEADLESS null #else new DropPieceRulePresenter() #end, null, null),
            isIncluded: null,
        };
        return rules;
    }

    override public function makeDefaultParams() {
        return {
            allowFlipping:false,
            allowRotating:true,
            pieceIDs:[for (piece in pieceLib.getPiecesOfSize(4)) piece.id],
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
