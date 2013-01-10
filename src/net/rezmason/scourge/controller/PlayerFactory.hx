package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.controller.players.*;

using Lambda;

typedef PlayerHandler = Player->GameEvent->Void;

class PlayerFactory {

    public static function makePlayers(playerConfigs:Array<PlayerConfig>, handler:PlayerHandler):Array<Player> {
        var players:Array<Player> = [];

        for (ike in 0...playerConfigs.length) {
            var config:PlayerConfig = playerConfigs[ike];
            if (config == null)
                throw "Null player config.";

            var playerType:Class<Player> = null;
            switch (config.type) {
                case Test(helper): playerType = TestPlayer;
                case Human: playerType = HumanPlayer;
                case Machine: playerType = MachinePlayer;
                case Remote: playerType = RemotePlayer;
            }

            players.push(Type.createInstance(playerType, [ike, config, handler].concat(Type.enumParameters(config.type))));
        }

        return players;
    }
}
