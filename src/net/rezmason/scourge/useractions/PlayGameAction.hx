package net.rezmason.scourge.useractions;

import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.bite.BiteAspect;
import net.rezmason.scourge.game.build.PetriBoardFactory;
import net.rezmason.scourge.game.piece.SwapAspect;
import net.rezmason.hypertype.console.UserAction;
import net.rezmason.hypertype.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.hypertype.console.ConsoleTypes;
import net.rezmason.hypertype.console.ConsoleUtils.*;
import net.rezmason.scourge.errands.BeginGameErrand;
import net.rezmason.utils.santa.Present;

using Lambda;

class PlayGameAction extends UserAction {
    
    var showBody:Void->Void;
    var isReplay:Bool;
    var errand:BeginGameErrand;
    var seed:UInt;
    var numPlayers:Int;

    public function new(showBody:Void->Void):Void {
        super();
        this.showBody = showBody;
        name = 'play';

        keys['playerPattern'] = PLAYER_PATTERN;
        keys['thinkPeriod'] = INTEGERS;
        keys['animationLength'] = REALS;
        keys['seed'] = INTEGERS;
        flags.push('replay');
        flags.push('circular');
    }

    override public function hint(args:UserActionArgs):Void {
        var message = '';
        hintSignal.dispatch(message, null);
    }

    override public function execute(args:UserActionArgs):Void {
        isReplay = args.flags.has('replay');
        if (args.keyValuePairs.exists('seed')) seed = Std.parseInt(args.keyValuePairs['seed']);
        else seed = Std.int(Math.random() * 0x7FFFFFFF);

        var playerPatternString:String = args.keyValuePairs['playerPattern'];
        if (playerPatternString == null) playerPatternString = 'bb';
        var playerPattern:Array<String> = playerPatternString.split('');
        numPlayers = playerPattern.length;
        if (numPlayers > 8) numPlayers = 8;
        if (numPlayers < 2) numPlayers = 2;

        if (playerPattern.length > numPlayers) playerPattern = playerPattern.slice(0, numPlayers);
        while (playerPattern.length < numPlayers) playerPattern.push('b');

        var thinkPeriodString:String = args.keyValuePairs['thinkPeriod'];
        if (thinkPeriodString == null) thinkPeriodString = '1000';
        var thinkPeriod:Int = Std.parseInt(thinkPeriodString);

        var animationLengthString:String = args.keyValuePairs['animationLength'];
        if (animationLengthString == null) animationLengthString = '1';
        var animationLength:Float = Std.parseFloat(animationLengthString);

        var circular:Bool = args.flags.has('circular');

        var cfg:ScourgeGameConfig = new ScourgeGameConfig();

        var pieceLib = cfg.pieceParams.pieceLib;
        var pieceIDs:Array<String> = [];
        for (ike in 0...4) for (piece in pieceLib.getPiecesOfSize(ike + 1)) pieceIDs.push(piece.id);

        cfg.buildParams.numPlayers = numPlayers;
        cfg.buildParams.cells = PetriBoardFactory.create(numPlayers, circular);
        cfg.pieceParams.pieceIDs = pieceIDs;
        cfg.pieceParams.allowRotating = true;
        cfg.pieceParams.allowSkipping = false;
        cfg.bodyParams.includeCavities = true;

        cfg.metaParams.globalProperties[SwapAspect.NUM_SWAPS.id].maxAmount = 5;
        cfg.metaParams.globalProperties[BiteAspect.NUM_BITES.id].maxAmount = 5;

        errand = new BeginGameErrand(cfg, playerPattern, thinkPeriod, animationLength, isReplay, seed);
        errand.onComplete.add(onErrandComplete);
        errand.run();
    }

    function onErrandComplete(success, message) {
        errand.onComplete.removeAll();
        if (success) {
            showBody();
            if (isReplay) message = 'Replaying last game.';
            else message = 'Starting $numPlayers-player game with seed $seed.';
        } else {
            message = 'ERROR: $message';
        }
        outputSignal.dispatch(message, true);
    }
}
