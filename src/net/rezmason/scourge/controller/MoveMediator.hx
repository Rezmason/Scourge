package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.gl.GLTypes;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.BoardSpaceState;
import net.rezmason.scourge.components.BoardSpaceView;
import net.rezmason.scourge.game.Pieces;
import net.rezmason.scourge.game.ScourgeGameConfig;
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
        var numPieceGlyphsNeeded = pieces.maxSize();
        if (piece.numGlyphs < numPieceGlyphsNeeded) piece.growTo(numPieceGlyphsNeeded);
        for (id in 0...piece.numGlyphs) {
            var glyph = piece.getGlyphByID(id);
            glyph.SET({color:WHITE, x:id, char:Strings.UI_CODE, s:2, p:-0.03});
        }
    }

    public function endGame() {
        game = null;
    }

    /*
    function onUpdate(delta) {
        num += delta;
        loupe.width  = (Math.sin(num * 2) * 0.5 + 0.5) * 0.5;
        loupe.height = (Math.sin(num * 3) * 0.5 + 0.5) * 0.5;
        loupe.redraw();
    }
    */

    public function enableHumanMoves() {
        trace('ENABLE HUMAN MOVES');
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
                    case SPACE: trace('SPACE');
                    case _:
                }
                if (nextCell != null) {
                    var nextSpace = boardSpacesByID[nextCell.id];
                    if (nextSpace.get(BoardSpaceState).petriData.isWall) return;
                    selectedSpace.get(BoardSpaceView).over.set_s(0);
                    selectedSpace = nextSpace;
                    var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                    selectedGlyph.set_s(2);
                    piece.transform.identity();
                    piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                    piece.transform.append(board.transform);
                }
            case MOUSE(type, x, y): 
                switch (type) {
                    case CLICK:
                        if (selectedSpace != null) selectedSpace.get(BoardSpaceView).over.set_s(0);
                        selectedSpace = boardSpacesByID[glyphID];
                        var selectedGlyph = selectedSpace.get(BoardSpaceView).over;
                        selectedGlyph.set_s(2);
                        piece.transform.identity();
                        piece.transform.appendTranslation(selectedGlyph.get_x(), selectedGlyph.get_y(), selectedGlyph.get_z());
                        piece.transform.append(board.transform);
                    case MOUSE_DOWN:
                    case MOUSE_UP:
                    case MOVE:
                    case _:
                }
            case _:
        }
    }
}
