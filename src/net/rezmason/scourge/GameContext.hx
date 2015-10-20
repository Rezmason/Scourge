package net.rezmason.scourge;

import net.rezmason.ecce.Ecce;
import net.rezmason.praxis.bot.BotSystem;
import net.rezmason.praxis.human.HumanSystem;
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

        var botSystem:BotSystem = new BotSystem();
        Santa.mapToClass(BotSystem, Singleton(botSystem));
        referee.gameEventSignal.add(botSystem.processGameEvent);
        botSystem.playSignal.add(referee.submitMove);
        
        var sequencer = new Sequencer();
        Santa.mapToClass(Sequencer, Singleton(sequencer));

        var boardAnimator = new BoardAnimator();
        sequencer.animationComposedSignal.add(boardAnimator.wake);
        boardAnimator.animCompleteSignal.add(referee.proceed);

        var moveMediator = new MoveMediator();
        Santa.mapToClass(MoveMediator, Singleton(moveMediator));
        sequencer.gameStartSignal.add(moveMediator.acceptBoardSpaces);
        sequencer.gameEndSignal.add(moveMediator.ejectBoardSpaces);

        var humanSystem:HumanSystem = new HumanSystem();
        Santa.mapToClass(HumanSystem, Singleton(humanSystem));
        moveMediator.moveChosenSignal.add(humanSystem.submitMove);
        humanSystem.enableUISignal.add(moveMediator.enableHumanMoves);
        referee.gameEventSignal.add(humanSystem.processGameEvent);
        humanSystem.playSignal.add(referee.submitMove);

        humanSystem.gameBegunSignal.add(sequencer.beginGame);
        humanSystem.gameBegunSignal.add(moveMediator.beginGame);

        humanSystem.moveStartSignal.add(sequencer.beginMove);
        humanSystem.moveStepSignal.add(sequencer.stepMove);
        humanSystem.moveStopSignal.add(sequencer.endMove);

        humanSystem.moveStopSignal.add(moveMediator.updatePiece);
        
        humanSystem.gameEndedSignal.add(sequencer.endGame);
        humanSystem.gameEndedSignal.add(moveMediator.endGame);
    }
}
