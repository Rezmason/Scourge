package net.rezmason.scourge.textview.useractions;

import net.rezmason.scourge.game.ScourgeGameConfig;
import net.rezmason.scourge.game.bite.BiteAspect;
import net.rezmason.scourge.game.build.PetriBoardFactory;
import net.rezmason.scourge.game.piece.SwapAspect;
import net.rezmason.scourge.textview.GameSystem;
import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.utils.santa.Present;

using Lambda;

class PlayGameAction extends UserAction {
    
    var showBody:Void->Void;
    var gameSystem:GameSystem;

    public function new(showBody:Void->Void):Void {
        super();
        this.showBody = showBody;
        this.gameSystem = new Present(GameSystem);
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
        var message = '';

        var isReplay:Bool = args.flags.has('replay');

        if (isReplay && !gameSystem.hasLastGame) {
            message = styleError('Referee has no last game to replay.');
            outputSignal.dispatch(message, true);
            return;
        }

        var seed:UInt = 0;

        if (args.keyValuePairs.exists('seed')) seed = Std.parseInt(args.keyValuePairs['seed']);
        else seed = Std.int(Math.random() * 0x7FFFFFFF);

        var playerPatternString:String = args.keyValuePairs['playerPattern'];
        if (playerPatternString == null) playerPatternString = 'bb';
        var playerPattern:Array<String> = playerPatternString.split('');
        var numPlayers:Int = playerPattern.length;
        if (numPlayers > 8) numPlayers = 8;
        if (numPlayers < 2) numPlayers = 2;

        if (playerPattern.length > numPlayers) playerPattern = playerPattern.slice(0, numPlayers);
        while (playerPattern.length < numPlayers) playerPattern.push('b');

        var thinkPeriodString:String = args.keyValuePairs['thinkPeriod'];
        if (thinkPeriodString == null) thinkPeriodString = '10';
        var thinkPeriod:Int = Std.parseInt(thinkPeriodString);

        var animationLengthString:String = args.keyValuePairs['animationLength'];
        if (animationLengthString == null) animationLengthString = '1';
        var animationLength:Float = Std.parseFloat(animationLengthString);

        var circular:Bool = args.flags.has('circular');

        var cfg:ScourgeGameConfig = new ScourgeGameConfig();

        var pieceTableIDs:Array<Int> = [];
        var pieces = cfg.pieceParams.pieces;
        for (ike in 0...4) pieceTableIDs = pieceTableIDs.concat(pieces.getAllPieceIDsOfSize(ike + 1));

        cfg.buildParams.numPlayers = numPlayers;
        cfg.buildParams.loci = PetriBoardFactory.create(numPlayers, circular);
        cfg.pieceParams.pieceTableIDs = pieceTableIDs;
        cfg.pieceParams.allowRotating = true;
        cfg.pieceParams.allowSkipping = false;
        cfg.bodyParams.includeCavities = true;

        cfg.metaParams.globalProperties[SwapAspect.NUM_SWAPS.id].maxAmount = 5;
        cfg.metaParams.globalProperties[BiteAspect.NUM_BITES.id].maxAmount = 5;

        gameSystem.beginGame(cfg, playerPattern, thinkPeriod, animationLength, isReplay, seed);
        showBody();

        if (isReplay) message = 'Replaying last game.';
        else message = 'Starting $numPlayers-player game with seed $seed.';
        outputSignal.dispatch(message, true);
    }
}
