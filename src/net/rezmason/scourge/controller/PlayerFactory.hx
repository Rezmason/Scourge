package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.controller.players.HumanPlayer;
import net.rezmason.scourge.controller.players.MachinePlayer;
import net.rezmason.scourge.controller.players.RemotePlayer;
import net.rezmason.scourge.controller.players.TestPlayer;

using Lambda;

typedef PlayerHandler = Player->GameEvent->Void;

class PlayerFactory {

    public static function makePlayers(playerConfigs:Array<PlayerConfig>, handler:PlayerHandler):Array<Player> {
        var players:Array<Player> = [];

        for (ike in 0...playerConfigs.length) {
            var config:PlayerConfig = playerConfigs[ike];
            if (config == null)
                throw 'Null player config.';

            var playerType:Class<Player> = null;
            switch (config.type) {
                case Test(_, _): playerType = TestPlayer;
                case Human: playerType = HumanPlayer;
                case Machine: playerType = MachinePlayer;
                case Remote: playerType = RemotePlayer;
            }

            var args:Array<Dynamic> = [ike, config, handler];
            args = args.concat(Type.enumParameters(config.type));
            players.push(Type.createInstance(playerType, args));
        }

        return players;
    }
}
