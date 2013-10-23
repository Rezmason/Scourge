package net.rezmason.scourge.controller;

import msignal.Signal;

import net.rezmason.scourge.controller.Types;

using Lambda;

class PlayerFactory {

    public function new():Void {

    }

    public function makePlayers(defs:Array<PlayerDef>, signal:Signal2<Player, GameEvent>):Array<Player> {
        var players:Array<Player> = [];

        var botSystem:BotSystem = null;

        for (ike in 0...defs.length) {
            var def:PlayerDef = defs[ike];
            if (def == null) throw 'Null player def.';

            var player:Player = null;
            switch (def) {
                case Test(proxy): player = new TestPlayer(ike, signal, proxy);
                case Bot(smarts, period):
                    if (botSystem == null) botSystem = new BotSystem();
                    player = botSystem.createPlayer(ike, signal, smarts, period);
                // case Human:
                // case Remote:
                case _: throw 'Unsupported player type "$def"';
            }

            players.push(player);
        }

        return players;
    }
}
