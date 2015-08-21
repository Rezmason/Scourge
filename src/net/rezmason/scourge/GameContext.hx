package net.rezmason.scourge;

import net.rezmason.ecce.Ecce;
import net.rezmason.praxis.play.Referee;
import net.rezmason.scourge.controller.Sequencer;
import net.rezmason.scourge.textview.View;
import net.rezmason.scourge.textview.board.BoardAnimator;
import net.rezmason.scourge.textview.board.BoardInitializer;
import net.rezmason.scourge.textview.board.BoardSettler;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.utils.santa.Santa;

class GameContext {

    public function new():Void {
        Santa.mapToClass(Referee, Singleton(new Referee()));
        Santa.mapToClass(Ecce, Singleton(new Ecce()));
        Santa.mapToClass(View, Singleton(new View()));
        
        var sequencer = new Sequencer();
        Santa.mapToClass(Sequencer, Singleton(sequencer));

        var boardInitializer = new BoardInitializer();
        sequencer.gameStartSignal.add(function(_, _) boardInitializer.run());

        var boardSettler = new BoardSettler();
        sequencer.moveSettlingSignal.add(boardSettler.run);
        sequencer.gameStartSignal.add(function(game, _) boardSettler.init(game));
        sequencer.gameEndSignal.add(boardSettler.dismiss);
        
        var boardAnimator = new BoardAnimator();
        sequencer.moveSequencedSignal.add(boardAnimator.wake);
        sequencer.moveSettlingSignal.add(boardAnimator.wake);
        boardAnimator.animCompleteSignal.add(sequencer.proceed);
    }
}
