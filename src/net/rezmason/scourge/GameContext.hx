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
        Santa.mapToClass(Referee, Singleton(new Referee()));
        Santa.mapToClass(Ecce, Singleton(new Ecce()));
        Santa.mapToClass(View, Singleton(new View()));
        
        var sequencer = new Sequencer();
        Santa.mapToClass(Sequencer, Singleton(sequencer));

        var boardAnimator = new BoardAnimator();
        sequencer.animationComposedSignal.add(boardAnimator.wake);
        boardAnimator.animCompleteSignal.add(sequencer.completeAnimation);

        var moveMediator = new MoveMediator();
        Santa.mapToClass(MoveMediator, Singleton(moveMediator));
    }
}
