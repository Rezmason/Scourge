package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.grid.GridDirection;
import net.rezmason.math.Vec4;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.ScourgeColorPalette.*;
import net.rezmason.scourge.ScourgeStrings;
import net.rezmason.scourge.View;
import net.rezmason.scourge.components.BoardSpaceState;
import net.rezmason.scourge.components.BoardSpaceView;
import net.rezmason.scourge.game.Piece;
import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.bite.BiteMove;
import net.rezmason.scourge.game.piece.DropPieceMove;
import net.rezmason.scourge.game.piece.PieceAspect;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.ui.BorderBox;
import net.rezmason.hypertype.ui.DragBehavior;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;
import net.rezmason.hypertype.ui.LoopingDragBehavior;

using net.rezmason.grid.GridUtils;
using net.rezmason.hypertype.core.GlyphUtils;

class MoveMediator {

    public var moveChosenSignal(default, null):Zig<Int->String->Int->Void> = new Zig();
    var ecce:Ecce;
    var config:ScourgeGameConfig;
    var game:Game;
    var loupe:BorderBox;
    var qBoard:Query;
    var boardSpacesByID:Map<Int, Entity>;
    var selectedSpace:Entity;
    var boardScale:Float;
    var board:Body;
    var piece:Body;
    var bite:Body;
    var pieces:Array<Piece>;
    var pieceTableIndex_:AspectPointer<PGlobal>;
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

    var dragBehavior:LoopingDragBehavior;

    public function new() {
        var view:View = new Present(View);

        ecce = new Present(Ecce);
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
        selectedSpace = null;

        boardScale = view.boardScale;
        board = view.board;
        piece = view.piece;
        bite = view.bite;
        loupe = view.loupe;
        loupe.body.mouseEnabled = false;
        // loupe.body.updateSignal.add(onUpdate); 
        board.interactionSignal.add(handleBoardInteraction);
        board.updateSignal.add(update);

        dragBehavior = new LoopingDragBehavior();
        dragBehavior.horizontalWrapSignal.add(onWrap.bind(_, 0));
        dragBehavior.verticalWrapSignal.add(onWrap.bind(0, _));
    }

    public function beginGame(config, game) {
        this.config = cast config;
        this.game = game;

        var pieceLib = this.config.pieceParams.pieceLib;
        pieces = [for (id in this.config.pieceParams.pieceIDs) pieceLib.getPieceByID(id)];
        allowFlipping = this.config.pieceParams.allowFlipping;
        allowRotating = this.config.pieceParams.allowRotating;
        allowSkipping = this.config.pieceParams.allowSkipping;
        piece.size = pieceLib.maxSize();
        for (glyph in piece.eachGlyph()) glyph.SET({color:WHITE, s:0, p:-0.03, hitboxS:0, a:0.2});
        bite.size = this.config.biteParams.maxReach + 1;
        for (glyph in bite.eachGlyph()) glyph.SET({color:WHITE, s:0, p:-0.03, hitboxS:0, a:0.2});
        bite.getGlyphByID(0).set_color(new Vec4(1, 0, 0));
        pieceTableIndex_ = game.plan.onGlobal(PieceAspect.PIECE_TABLE_INDEX);
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
            selectedChar = biteTargetIDs.exists(selectedCell.id) ? ScourgeStrings.BODY_CODE : ScourgeStrings.ILLEGAL_BODY_CODE;
        } else {
            if (biteTargetSpace == selectedSpace) {
                selectedChar = ScourgeStrings.LEGAL_BITE_TARGET_CODE;
            } else {
                var biteTargetSpaceGlyph = biteTargetSpace.get(BoardSpaceView).over;
                var biteTargetGlyph = bite.getGlyphByID(1);
                biteTargetGlyph.SET({s:2, x:biteTargetSpaceGlyph.get_x(), y:biteTargetSpaceGlyph.get_y(), z:biteTargetSpaceGlyph.get_z()});
                biteTargetGlyph.set_char(ScourgeStrings.LEGAL_BITE_TARGET_CODE);

                var ike = 2;
                for (bitSpace in bitSpacesByID) {
                    if (bitSpace == selectedSpace) {
                        selectedChar = ScourgeStrings.BITE_CODE;
                    } else {
                        var bitSpaceGlyph = bitSpace.get(BoardSpaceView).over;
                        var bitGlyph = bite.getGlyphByID(ike++);
                        bitGlyph.SET({s:2, x:bitSpaceGlyph.get_x(), y:bitSpaceGlyph.get_y(), z:bitSpaceGlyph.get_z()});
                        bitGlyph.set_char(ScourgeStrings.BITE_CODE);
                    }
                }

                if (!bitSpacesByID.exists(selectedCell.id)) {
                    var sortedBitSpaceIDs = [for (key in bitSpacesByID.keys()) key];
                    sortedBitSpaceIDs.push(selectedCell.id);
                    sortedBitSpaceIDs.sort(lesserID);
                    var targetID = biteTargetSpace.get(BoardSpaceState).cell.id;
                    var key = '${targetID}_{$sortedBitSpaceIDs.join("_")}';
                    if (biteMovesByKey.exists(key)) {
                        selectedChar = ScourgeStrings.BITE_CODE;
                    } else if (biteTargetIDs.exists(selectedCell.id)) {
                        selectedChar = ScourgeStrings.BODY_CODE;
                    } else {
                        selectedChar = ScourgeStrings.ILLEGAL_BITE_CODE;
                    }
                }
            }
        }
        
        biteSelectionGlyph.set_char(selectedChar);
    }

    function updatePiece() {
        for (glyph in piece.eachGlyph()) glyph.set_s(0);
        if (isBiting) return;
        var pieceIndex = game.state.global[pieceTableIndex_];
        if (pieceIndex == NULL) {
            if (movesEnabled && game.getMovesForAction('pick').length > 0) {
                moveChosenSignal.dispatch(game.revision, 'pick', 0);
            }
        } else if (selectedSpace != null) {
            var freePiece = pieces[pieceIndex];
            if (!allowFlipping) reflection = game.state.global[pieceReflection_];
            if (!allowRotating) rotation = game.state.global[pieceRotation_];
            fixedPiece = freePiece.getVariant(reflection, rotation);
            var ids:Array<Int> = [];
            var selectedCell = selectedSpace.get(BoardSpaceState).cell;
            for (ike in 0...fixedPiece.cells.length) {
                var x = fixedPiece.cells[ike].x - fixedPiece.closestCellToCenter.x;
                var y = fixedPiece.cells[ike].y - fixedPiece.closestCellToCenter.y;
                var cell = selectedCell.runEuclidean(x, y);
                ids.push(cell.id);
                var nr = fixedPiece.cells[ike] == fixedPiece.closestCellToCenter ? 0 : 1;
                piece.getGlyphByID(ike).SET({s:2, x:-x, y:y, g:nr, b:nr});
            }
            if (dropMovesByKey != null) dropMove = dropMovesByKey[getDropMoveKey(ids)];
            var char = dropMove == null ? ScourgeStrings.ILLEGAL_BODY_CODE : ScourgeStrings.BODY_CODE;
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
                dropMovesByKey[getDropMoveKey(move.addedSpaces)] = move;
            }
        }
    }

    inline function getDropMoveKey(ids:Array<Int>) {
        ids = ids.copy();
        ids.sort(lowerInt);
        return ids.join('_');
    }

    function lowerInt(i1:Int, i2:Int) return i1 - i2;

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

    function update(delta) {
        if (dragBehavior.active) {
            dragBehavior.update(delta);
            updatePiecePosition();
        }
    }

    inline function updatePiecePosition() {
        if (selectedSpace != null) {
            piece.transform.identity();

            var offset = dragBehavior.displacement;
            var dH = offset.x < 0 ? W : E;
            var dV = offset.y < 0 ? S : N;
            var hMag = Math.abs(offset.x);
            var vMag = Math.abs(offset.y);

            var oCell = selectedSpace.get(BoardSpaceState).cell;
            var oGlyph = selectedSpace.get(BoardSpaceView).over;
            var hGlyph = boardSpacesByID[oCell.neighbors[dH].id].get(BoardSpaceView).over;
            var vGlyph = boardSpacesByID[oCell.neighbors[dV].id].get(BoardSpaceView).over;
            var hvGlyph = null;
            if (hMag > vMag) {
                hvGlyph = boardSpacesByID[oCell.neighbors[dH].neighbors[dV].id].get(BoardSpaceView).over;
            } else {
                hvGlyph = boardSpacesByID[oCell.neighbors[dV].neighbors[dH].id].get(BoardSpaceView).over;
            }

            var interpX = bilinearInterpolate(oGlyph.get_x(), hGlyph.get_x(), vGlyph.get_x(), hvGlyph.get_x(), hMag, vMag);
            var interpY = bilinearInterpolate(oGlyph.get_y(), hGlyph.get_y(), vGlyph.get_y(), hvGlyph.get_y(), hMag, vMag);
            var interpZ = bilinearInterpolate(oGlyph.get_z(), hGlyph.get_z(), vGlyph.get_z(), hvGlyph.get_z(), hMag, vMag);

            // TODO: proper use of dragBehavior.displacement
            piece.transform.appendTranslation(interpX, interpY, interpZ);
            piece.transform.append(board.transform);

            /*
            loupe.body.transform.identity();
            loupe.body.transform.appendTranslation(
                dragBehavior.displacement.x / boardScale,
                dragBehavior.displacement.y / boardScale,
                0
            );
            */
        }
    }

    inline function bilinearInterpolate(oVal:Float, hVal:Float, vVal:Float, hvVal:Float, hFrac:Float, vFrac:Float):Float {
        var val:Float = 0;
        val += oVal * (1 - hFrac) * (1 - vFrac);
        val += hVal * hFrac * (1 - vFrac);
        val += vVal * vFrac * (1 - hFrac);
        val += hvVal * vFrac * hFrac;
        return val;
    }

    function onWrap(horizontal:Int, vertical:Int) {
        if (selectedSpace != null) {
            var cell = selectedSpace.get(BoardSpaceState).cell;
            var nextCell = cell;
            if (horizontal > 0) nextCell = cell.run(E,  horizontal, isNotWall);
            if (horizontal < 0) nextCell = cell.run(W, -horizontal, isNotWall);
            if (vertical   > 0) nextCell = cell.run(N,    vertical, isNotWall);
            if (vertical   < 0) nextCell = cell.run(S,   -vertical, isNotWall);

            if (nextCell != cell) {
                selectedSpace = boardSpacesByID[nextCell.id];
                updateDragWalls();
                updatePiecePosition();
                updatePiece();
                updateBite();
            }
        }
    }

    function updateDragWalls() {
        if (selectedSpace != null) {
            var cell = selectedSpace.get(BoardSpaceState).cell;
            dragBehavior.setWalls( 
                !isNotWall(cell.n()), 
                !isNotWall(cell.s()), 
                !isNotWall(cell.e()), 
                !isNotWall(cell.w())
            );
        }
    }

    function isNotWall(cell) return !boardSpacesByID[cell.id].get(BoardSpaceState).petriData.isWall;

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
                    updatePiecePosition();
                    updatePiece();
                    updateBite();
                }
            case MOUSE(type, x, y): 
                switch (type) {
                    case CLICK if (!dragBehavior.dragging && boardSpacesByID.exists(glyphID)):
                        selectedSpace = boardSpacesByID[glyphID];
                        var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                        updateDragWalls();
                        updatePiecePosition();
                        updatePiece();
                        updateBite();
                    case DROP, CLICK if (dragBehavior.dragging): dragBehavior.stopDrag();
                    case ENTER, EXIT, MOVE if (dragBehavior.dragging): 
                        dragBehavior.updateDrag(x * 20, -y * 20);
                    case MOUSE_DOWN if (selectedSpace != null):
                        dragBehavior.startDrag(x * 20, -y * 20);
                    case _:
                }
            case _:
        }
    }
}
