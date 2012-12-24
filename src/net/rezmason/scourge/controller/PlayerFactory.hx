package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types.PlayerConfig;
import net.rezmason.scourge.controller.players.*;

using Lambda;

class PlayerFactory {

    public static function makePlayers(playerConfigs:Array<PlayerConfig>):Array<Player> {
        return playerConfigs.map(makePlayer).array();
    }

    private inline static function makePlayer(config:PlayerConfig):Player {
        switch (config.type) {
            case Test: return new TestPlayer(config);
            case Human: return new HumanPlayer(config);
            case Machine: return new MachinePlayer(config);
            case Remote: return new RemotePlayer(config);
        }
    }
}
