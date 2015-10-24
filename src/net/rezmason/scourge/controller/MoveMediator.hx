package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.gl.GLTypes;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.BoardSpaceState;
import net.rezmason.scourge.components.BoardSpaceView;
import net.rezmason.scourge.game.PieceTypes;
import net.rezmason.scourge.game.Pieces;
import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.piece.DropPieceMove;
import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.View;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.ui.BorderBox;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.grid.GridUtils;
using net.rezmason.scourge.textview.core.GlyphUtils;

class MoveMediator {

    public var moveChosenSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    var ecce:Ecce;
    var config:ScourgeGameConfig;
    var game:Game;
    var loupe:BorderBox;
    var qBoard:Query;
    var boardSpacesByID:Map<Int, Entity>;
    var selectedSpace:Entity;
    var board:Body;
    var piece:Body;
    var pieces:Pieces;
    var pieceTableID_:AspectPointer<PGlobal>;
    var pieceReflection_:AspectPointer<PGlobal>;
    var pieceRotation_:AspectPointer<PGlobal>;
    var rotation:Int = 0;
    var reflection:Int = 0;
    var fixedPiece:Piece;
    var movesEnabled:Bool = false;
    var dropMovesByKey:Map<String, DropPieceMove>;
    var dropMove:DropPieceMove;
    var allowFlipping:Bool;
    var allowRotating:Bool;

    public function new() {
        var view:View = new Present(View);

        ecce = new Present(Ecce);
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
        selectedSpace = null;

        board = view.board;
        piece = view.piece;
        loupe = view.loupe;
        loupe.body.mouseEnabled = false;
        // loupe.body.updateSignal.add(onUpdate); 
        
        board.interactionSignal.add(handleBoardInteraction);
    }

    public function beginGame(config, game) {
        this.config = cast config;
        this.game = game;

        pieces = this.config.pieceParams.pieces;
        allowFlipping = this.config.pieceParams.allowFlipping;
        allowRotating = this.config.pieceParams.allowRotating;
        var numPieceGlyphsNeeded = pieces.maxSize();
        if (piece.numGlyphs < numPieceGlyphsNeeded) piece.growTo(numPieceGlyphsNeeded);
        for (id in 0...piece.numGlyphs) {
            var glyph = piece.getGlyphByID(id);
            glyph.SET({color:WHITE, x:id, s:0, p:-0.03, paint_s:0});
        }
        pieceTableID_ = game.plan.onGlobal(PieceAspect.PIECE_TABLE_ID);
        pieceReflection_ = game.plan.onGlobal(PieceAspect.PIECE_REFLECTION);
        pieceRotation_ = game.plan.onGlobal(PieceAspect.PIECE_ROTATION);
    }

    public function endGame() {
        movesEnabled = false;
        game = null;
        dropMovesByKey = null;
    }

    public function updatePiece() {
        var pieceID = game.state.global[pieceTableID_];
        
        for (glyph in piece.eachGlyph()) glyph.set_s(0);
        if (pieceID == NULL) {
            if (movesEnabled && game.getMovesForAction('pick').length > 0) {
                moveChosenSignal.dispatch(game.revision, 'pick', 0);
            }
        } else if (selectedSpace != null) {
            var freePiece = pieces.getPieceById(pieceID);
            rotation %= freePiece.numRotations;
            reflection %= freePiece.numReflections;
            if (!allowFlipping) reflection = game.state.global[pieceReflection_];
            if (!allowRotating) rotation = game.state.global[pieceRotation_];
            fixedPiece = freePiece.getPiece(reflection, rotation);
            var cells = fixedPiece.cells;
            var homeCell = cells[0];
            var ids = [];
            var selectedCell = selectedSpace.get(BoardSpaceState).cell;
            for (ike in 0...cells.length) {
                var x = cells[ike].x - homeCell.x;
                var y = cells[ike].y - homeCell.y;
                var cell = selectedCell.runEuclidean(x, y);
                ids.push(cell.id);
                var nr = ike == 0 ? 0 : 1;
                piece.getGlyphByID(ike).SET({s:2, x:-x, y:y, g:nr, b:nr});
            }
            var key = ids.join('_');
            if (dropMovesByKey != null) dropMove = dropMovesByKey[key];
            var char = dropMove == null ? Strings.EATEN_HEAD_CODE : Strings.UI_CODE;
            for (glyph in piece.eachGlyph()) glyph.set_char(char);
        }
    }

    /*
    function onUpdate(delta) {
        num += delta;
        loupe.width  = (Math.sin(num * 2) * 0.5 + 0.5) * 0.5;
        loupe.height = (Math.sin(num * 3) * 0.5 + 0.5) * 0.5;
        loupe.redraw();
    }
    */

    function updateDropMoves() {
        if (movesEnabled) {
            var dropMoves:Array<DropPieceMove> = cast game.getMovesForAction('drop');
            dropMovesByKey = new Map();
            for (move in dropMoves) {
                var key = move.addedSpaces.join('_');
                dropMovesByKey[key] = move;
            }
        }
    }
    public function enableHumanMoves() {
        movesEnabled = true;
        updateDropMoves();
        updatePiece();
    }

    public function acceptBoardSpaces() {
        boardSpacesByID = new Map();
        for (entity in qBoard) {
            var spaceState = entity.get(BoardSpaceState);
            boardSpacesByID[spaceState.cell.id] = entity;
        }
    }

    public function ejectBoardSpaces() {
        boardSpacesByID = null;
    }

    function handleBoardInteraction(glyphID, interaction) {
        switch (interaction) {
            case KEYBOARD(type, keyCode, modifier) if (type == KEY_DOWN && selectedSpace != null): 
                var cell = selectedSpace.get(BoardSpaceState).cell;
                var nextCell = null;
                switch (keyCode) {
                    case UP: nextCell = cell.n();
                    case DOWN: nextCell = cell.s();
                    case LEFT: nextCell = cell.w();
                    case RIGHT: nextCell = cell.e();
                    case SPACE: 
                        if (allowRotating) {
                            rotation = (rotation + 1) % 4;
                            updatePiece();
                        }
                    case SLASH: 
                        if (allowFlipping) {
                            reflection = (reflection + 1) % 4;
                            updatePiece();
                        }
                    case RETURN: 
                        if (movesEnabled && dropMove != null) {
                            movesEnabled = false;
                            moveChosenSignal.dispatch(game.revision, 'drop', dropMove.id);
                            dropMove = null;
                        }
                    case TAB:
                        if (movesEnabled && game.getMovesForAction('swap').length > 0) {
                            movesEnabled = false;
                            moveChosenSignal.dispatch(game.revision, 'swap', 0);
                        }
                    case _:
                }
                if (nextCell != null) {
                    var nextSpace = boardSpacesByID[nextCell.id];
                    if (nextSpace.get(BoardSpaceState).petriData.isWall) return;
                    //selectedSpace.get(BoardSpaceView).over.set_s(0);
                    selectedSpace = nextSpace;
                    var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                    //selectedGlyph.set_s(2);
                    piece.transform.identity();
                    piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                    piece.transform.append(board.transform);
                    updatePiece();
                }
            case MOUSE(type, x, y): 
                switch (type) {
                    case CLICK:
                        //if (selectedSpace != null) selectedSpace.get(BoardSpaceView).over.set_s(0);
                        selectedSpace = boardSpacesByID[glyphID];
                        var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                        //selectedGlyph.set_s(2);
                        piece.transform.identity();
                        piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                        piece.transform.append(board.transform);
                        updatePiece();
                    case MOUSE_DOWN:
                    case MOUSE_UP:
                    case MOVE:
                    case _:
                }
            case _:
        }
    }
}
