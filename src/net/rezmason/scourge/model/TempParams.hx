package net.rezmason.scourge.model;

import net.rezmason.scourge.model.build.*;
import net.rezmason.scourge.model.piece.*;

// Haxe typedef syntax currently has a bug, where a type can't extend two types that in turn extend a common type.

typedef FullDropPieceParams = {>BasePieceParams, >DropPieceParams,};
typedef FullPickPieceParams = {>BasePieceParams, >PickPieceParams,};

typedef FullBuildBoardParams = {>BaseBuildParams, >BuildBoardParams,};
typedef FullBuildPlayersParams = {>BaseBuildParams, >BuildPlayersParams,};
