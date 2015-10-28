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
import net.rezmason.scourge.game.bite.BiteMove;
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
    var bite:Body;
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
    var biteMovesByKey:Map<String, BiteMove>;
    var biteTargetIDs:Map<Int, Bool>;
    var biteMove:BiteMove;
    var allowFlipping:Bool;
    var allowRotating:Bool;
    var allowSkipping:Bool;
    var isBiting:Bool;
    var biteTargetSpace:Entity;
    var bitSpacesByID:Map<Int, Entity>;

    public function new() {
        var view:View = new Present(View);

        ecce = new Present(Ecce);
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
        selectedSpace = null;

        board = view.board;
        piece = view.piece;
        bite = view.bite;
        loupe = view.loupe;
        loupe.body.mouseEnabled = false;
        // loupe.body.updateSignal.add(onUpdate); 
        loupe.body.visible = false;
        
        board.interactionSignal.add(handleBoardInteraction);
    }

    public function beginGame(config, game) {
        this.config = cast config;
        this.game = game;

        pieces = this.config.pieceParams.pieces;
        allowFlipping = this.config.pieceParams.allowFlipping;
        allowRotating = this.config.pieceParams.allowRotating;
        allowSkipping = this.config.pieceParams.allowSkipping;
        piece.growTo(pieces.maxSize());
        for (id in 0...piece.numGlyphs) {
            var glyph = piece.getGlyphByID(id);
            glyph.SET({color:WHITE, x:id, s:0, p:-0.03, paint_s:0});
        }
        bite.growTo(this.config.biteParams.maxReach + 1);
        for (id in 0...bite.numGlyphs) {
            var glyph = bite.getGlyphByID(id);
            glyph.SET({color:WHITE, x:id, s:0, p:-0.03, paint_s:0});
        }
        bite.getGlyphByID(0).set_color(new Vec3(1, 0, 0));
        pieceTableID_ = game.plan.onGlobal(PieceAspect.PIECE_TABLE_ID);
        pieceReflection_ = game.plan.onGlobal(PieceAspect.PIECE_REFLECTION);
        pieceRotation_ = game.plan.onGlobal(PieceAspect.PIECE_ROTATION);
    }

    public function endGame() {
        movesEnabled = false;
        isBiting = false;
        game = null;
        dropMovesByKey = null;
        biteMovesByKey = null;
        biteTargetIDs = null;
        dropMove = null;
        biteMove = null;
        selectedSpace = null;
        biteTargetSpace = null;
        bitSpacesByID = null;
    }

    function updateBite() {
        for (glyph in bite.eachGlyph()) glyph.set_s(0);
        if (!isBiting || selectedSpace == null) return;

        var selectedCell = selectedSpace.get(BoardSpaceState).cell;
        var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
        var biteSelectionGlyph = bite.getGlyphByID(0);
        biteSelectionGlyph.SET({s:2, g:0, b:0, x:selectedGlyph.get_x(), y:selectedGlyph.get_y(), z:selectedGlyph.get_z()});

        var selectedChar = -1;

        if (biteTargetSpace == null) {
            selectedChar = biteTargetIDs.exists(selectedCell.id) ? Strings.BODY_CODE : Strings.ILLEGAL_BODY_CODE;
        } else {
            if (biteTargetSpace == selectedSpace) {
                selectedChar = Strings.LEGAL_BITE_TARGET_CODE;
            } else {
                var biteTargetSpaceGlyph = biteTargetSpace.get(BoardSpaceView).over;
                var biteTargetGlyph = bite.getGlyphByID(1);
                biteTargetGlyph.SET({s:2, x:biteTargetSpaceGlyph.get_x(), y:biteTargetSpaceGlyph.get_y(), z:biteTargetSpaceGlyph.get_z()});
                biteTargetGlyph.set_char(Strings.LEGAL_BITE_TARGET_CODE);

                var ike = 2;
                for (bitSpace in bitSpacesByID) {
                    if (bitSpace == selectedSpace) {
                        selectedChar = Strings.BITE_CODE;
                    } else {
                        var bitSpaceGlyph = bitSpace.get(BoardSpaceView).over;
                        var bitGlyph = bite.getGlyphByID(ike++);
                        bitGlyph.SET({s:2, x:bitSpaceGlyph.get_x(), y:bitSpaceGlyph.get_y(), z:bitSpaceGlyph.get_z()});
                        bitGlyph.set_char(Strings.BITE_CODE);
                    }
                }

                if (!bitSpacesByID.exists(selectedCell.id)) {
                    var sortedBitSpaceIDs = [for (key in bitSpacesByID.keys()) key];
                    sortedBitSpaceIDs.push(selectedCell.id);
                    sortedBitSpaceIDs.sort(lesserID);
                    var targetID = biteTargetSpace.get(BoardSpaceState).cell.id;
                    var key = '${targetID}_{$sortedBitSpaceIDs.join("_")}';
                    if (biteMovesByKey.exists(key)) {
                        selectedChar = Strings.BITE_CODE;
                    } else if (biteTargetIDs.exists(selectedCell.id)) {
                        selectedChar = Strings.BODY_CODE;
                    } else {
                        selectedChar = Strings.ILLEGAL_BITE_CODE;
                    }
                }
            }
        }
        
        biteSelectionGlyph.set_char(selectedChar);
    }

    function updatePiece() {
        for (glyph in piece.eachGlyph()) glyph.set_s(0);
        if (isBiting) return;
        var pieceID = game.state.global[pieceTableID_];
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
            var char = dropMove == null ? Strings.ILLEGAL_BODY_CODE : Strings.BODY_CODE;
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
            for (move in dropMoves) dropMovesByKey[move.addedSpaces.join('_')] = move;
        }
    }

    function updateBiteMoves() {
        if (movesEnabled) {
            var biteMoves:Array<BiteMove> = cast game.getMovesForAction('bite');
            biteMovesByKey = new Map();
            biteTargetIDs = new Map();
            for (move in biteMoves) {
                var sortedBitSpaceIDs = move.bitSpaces.copy();
                sortedBitSpaceIDs.sort(lesserID);
                biteMovesByKey['${move.targetSpace}_{$sortedBitSpaceIDs.join("_")}'] = move;
                biteTargetIDs[move.targetSpace] = true;
            }
        }
    }

    function lesserID(id1, id2) return id1 - id2;

    public function enableHumanMoves() {
        movesEnabled = true;
        isBiting = false;
        updateDropMoves();
        updateBiteMoves();
        updatePiece();
        updateBite();
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

    public function endMove() {
        updatePiece();
        updateBite();
    }

    function handleBoardInteraction(glyphID, interaction) {
        switch (interaction) {
            case KEYBOARD(type, keyCode, modifier) if (type == KEY_DOWN): 
                var cell = (selectedSpace == null) ? null : selectedSpace.get(BoardSpaceState).cell;
                var nextCell = null;
                switch (keyCode) {
                    case UP if (cell != null): nextCell = cell.n();
                    case DOWN if (cell != null): nextCell = cell.s();
                    case LEFT if (cell != null): nextCell = cell.w();
                    case RIGHT if (cell != null): nextCell = cell.e();
                    case SPACE if (cell != null): 
                        if (!isBiting && allowRotating) {
                            rotation = (rotation + 1) % 4;
                            updatePiece();
                        } else if (isBiting) {
                            if (selectedSpace == biteTargetSpace) {
                                biteMove = null;
                                biteTargetSpace = null;
                                bitSpacesByID = new Map();
                            } else if (bitSpacesByID.exists(cell.id)) {
                                bitSpacesByID.remove(cell.id);
                                var sortedBitSpaceIDs = [for (key in bitSpacesByID.keys()) key];
                                sortedBitSpaceIDs.sort(lesserID);
                                var targetID = biteTargetSpace.get(BoardSpaceState).cell.id;
                                var key = '${targetID}_{$sortedBitSpaceIDs.join("_")}';
                                biteMove = biteMovesByKey[key];
                            } else if (biteTargetIDs.exists(cell.id)) {
                                biteMove = null;
                                biteTargetSpace = selectedSpace;
                                bitSpacesByID = new Map();
                            } else if (biteTargetSpace != null) {
                                var sortedBitSpaceIDs = [for (key in bitSpacesByID.keys()) key];
                                sortedBitSpaceIDs.push(cell.id);
                                sortedBitSpaceIDs.sort(lesserID);
                                var targetID = biteTargetSpace.get(BoardSpaceState).cell.id;
                                var key = '${targetID}_{$sortedBitSpaceIDs.join("_")}';
                                if (biteMovesByKey[key] != null) {
                                    bitSpacesByID[cell.id] = selectedSpace;
                                    biteMove = biteMovesByKey[key];
                                }
                            }
                            updateBite();
                        }
                    case SLASH if (selectedSpace != null): 
                        if (allowFlipping) {
                            reflection = (reflection + 1) % 4;
                            updatePiece();
                        }
                    case RETURN: 
                        if (movesEnabled) {
                            if (!isBiting && dropMove != null) {
                                movesEnabled = false;
                                var moveID = dropMove.id;
                                dropMove = null;
                                selectedSpace = null;
                                updatePiece();
                                updateBite();
                                moveChosenSignal.dispatch(game.revision, 'drop', moveID);
                            } else if (isBiting && biteMove != null) {
                                movesEnabled = false;
                                var moveID = biteMove.id;
                                biteMove = null;
                                selectedSpace = null;
                                biteTargetSpace = null;
                                bitSpacesByID = null;
                                updatePiece();
                                updateBite();
                                moveChosenSignal.dispatch(game.revision, 'bite', moveID);
                            }
                        }
                    case TAB:
                        if (movesEnabled && game.getMovesForAction('swap').length > 0) {
                            movesEnabled = false;
                            moveChosenSignal.dispatch(game.revision, 'swap', 0);
                        }
                    case ESCAPE:
                        if (movesEnabled && game.getMovesForAction('forfeit').length > 0) {
                            movesEnabled = false;
                            moveChosenSignal.dispatch(game.revision, 'forfeit', 0);
                        }
                    case S:
                        if (movesEnabled && allowSkipping) {
                            movesEnabled = false;
                            moveChosenSignal.dispatch(game.revision, 'drop', 0);
                        }
                    case B:
                        if (movesEnabled && (isBiting || game.getMovesForAction('bite').length > 0)) {
                            isBiting = !isBiting;
                            selectedSpace = null;
                            biteTargetSpace = null;
                            bitSpacesByID = new Map();
                            biteMove = null;
                            updatePiece();
                            updateBite();
                        }
                    case _:
                }
                if (nextCell != null) {
                    var nextSpace = boardSpacesByID[nextCell.id];
                    if (nextSpace.get(BoardSpaceState).petriData.isWall) return;
                    selectedSpace = nextSpace;
                    var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                    piece.transform.identity();
                    piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                    piece.transform.append(board.transform);
                    updatePiece();
                    updateBite();
                }
            case MOUSE(type, x, y): 
                switch (type) {
                    case CLICK if (boardSpacesByID.exists(glyphID)):
                        selectedSpace = boardSpacesByID[glyphID];
                        var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                        piece.transform.identity();
                        piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                        piece.transform.append(board.transform);
                        updatePiece();
                        updateBite();
                    case MOUSE_DOWN:
                    case MOUSE_UP:
                    case MOVE:
                    case _:
                }
            case _:
        }
    }
}
