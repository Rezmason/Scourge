package net.rezmason.scourge.model.piece;

import net.rezmason.scourge.tools.Resource;

class PieceConfig extends Config<PieceParams> {

    var pieces:Pieces;

    public function new() {
        super();
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    override public function id():String {
        return 'piece';
    }

    public override function ruleComposition():RuleComposition {
        return null;
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
            allowSkipping:true,

            startingSwaps:5,

            allowAllPieces:false,
            allowSwapping:true,
        };
    }
}
