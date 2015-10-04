package net.rezmason.scourge;

import net.rezmason.ecce.Ecce;
import net.rezmason.praxis.play.Referee;
import net.rezmason.scourge.controller.MoveMediator;
import net.rezmason.scourge.controller.Sequencer;
import net.rezmason.scourge.controller.board.BoardAnimator;
import net.rezmason.scourge.textview.View;
import net.rezmason.utils.santa.Santa;

class GameContext {

    public function new():Void {
        Santa.mapToClass(Ecce, Singleton(new Ecce()));
        Santa.mapToClass(View, Singleton(new View()));
        
        var referee = new Referee();
        Santa.mapToClass(Referee, Singleton(referee));
        
        var sequencer = new Sequencer();
        Santa.mapToClass(Sequencer, Singleton(sequencer));

        var boardAnimator = new BoardAnimator();
        sequencer.animationComposedSignal.add(boardAnimator.wake);
        boardAnimator.animCompleteSignal.add(referee.proceed);

        var moveMediator = new MoveMediator();
        Santa.mapToClass(MoveMediator, Singleton(moveMediator));
    }
}
