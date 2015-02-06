package net.rezmason.scourge.model;

import net.rezmason.utils.Siphon;

class ScourgeConfig extends GameConfig {
    
    static var configDefs(default, null):Map<String, Class<Config<Dynamic>>> = cast Siphon.getDefs(
        'net.rezmason.scourge.model', 'src', true, "Config$"
    );

    public function new() super(configDefs);
}
