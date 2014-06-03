package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;
import net.rezmason.scourge.textview.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
using Lambda;

class PlayGameConsoleCommand extends ConsoleCommand {
    
    var displaySystem:DisplaySystem;
    var gameSystem:GameSystem;

    public function new(displaySystem:DisplaySystem, gameSystem:GameSystem):Void {
        super();
        this.displaySystem = displaySystem;
        this.gameSystem = gameSystem;
        name = 'play';

        keys['playerPattern'] = PLAYER_PATTERN;
        keys['thinkPeriod'] = INTEGERS;
        keys['animatePeriod'] = INTEGERS;
        flags.push('replay');
        flags.push('circular');
    }

    override public function hint(args:ConsoleCommandArgs):Void {
        var message = '';
        hintSignal.dispatch(message, null);
    }

    override public function execute(args:ConsoleCommandArgs):Void {
        var message = '';

        var isReplay:Bool = args.flags.has('replay');

        if (isReplay && gameSystem.referee.lastGame == null) {
            message = styleError('Referee has no last game to replay.');
            outputSignal.dispatch(message, true);
            return;
        }

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

        var animatePeriodString:String = args.keyValuePairs['animatePeriod'];
        if (animatePeriodString == null) animatePeriodString = '1000';
        var animatePeriod:Int = Std.parseInt(animatePeriodString);

        var circular:Bool = args.flags.has('circular');

        var cfg:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        cfg.pieceTableIDs = cfg.pieces.getAllPieceIDsOfSize(4);
        cfg.allowRotating = true;
        cfg.circular = circular;
        cfg.allowNowhereDrop = true;
        cfg.numPlayers = numPlayers;
        cfg.includeCavities = true;

        cfg.maxSwaps = 0;
        cfg.maxBites = 0;
        cfg.maxSkips = 3;

        gameSystem.beginGame(cfg, playerPattern, thinkPeriod, animatePeriod, isReplay);
        displaySystem.showBody('board', 'main');

        message = 'Starting $numPlayers-player game.';
        outputSignal.dispatch(message, true);
    }
}
