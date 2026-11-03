class_name TilesDef
extends RefCounted

const DADOS := {
	"CastleCenter": {"amount": 1, "t": ["C","C","C","C","C","C","C","C","C"]},
	"CastleCenterEntry": {"amount": 3, "t": ["C","C","R","C","C","F","F","C","C"]},
	"CastleCenterSide": {"amount": 4, "t": ["C","C","F","C","C","F","F","C","C"]},
	"CastleEdge": {"amount": 5, "t": ["C","C","F","F","C","F","F","F","F"]},
	"CastleEdgeRoad": {"amount": 4, "t": ["C","C","R","R","C","F","F","F","R"]},
	"CastleSides": {"amount": 3, "t": ["C","F","C","F","F","F","F","F","F"]},
	"CastleSidesEdge": {"amount": 2, "t": ["C","F","F","C","F","F","F","O","F"]},
	"CastleTube": {"amount": 2, "t": ["F","C","F","C","F","F","F","F","C"]},
	"CastleWall": {"amount": 5, "t": ["C","F","F","F","F","F","F","F","F"]},
	"CastleWallCurveLeft": {"amount": 3, "t": ["C","F","R","R","F","F","F","F","R"]},
	"CastleWallCurveRight": {"amount": 3, "t": ["C","R","R","F","F","F","F","F","R"]},
	"CastleWallJunction": {"amount": 3, "t": ["C","R","R","R","F","F","F","F","O"]},
	"CastleWallRoad": {"amount": 4, "t": ["C","R","F","R","F","F","F","F","R"]},
	"Monastery": {"amount": 4, "t": ["F","F","F","F","F","F","F","F","M"]},
	"MonasteryRoad": {"amount": 2, "t": ["F","F","R","F","F","F","F","F","M"]},
	"Road": {"amount": 7, "t": ["R","F","R","F","F","F","F","F","R"]},
	"RoadCurve": {"amount": 8, "t": ["F","F","R","R","F","F","F","F","R"]},
	"RoadJunctionLarge": {"amount": 1, "t": ["R","R","R","R","F","F","F","F","O"]},
	"RoadJunctionSmall": {"amount": 3, "t": ["F","R","R","R","F","F","F","F","O"]},
	"RoadCrossLarge": {"amount": 0, "t": ["R","R","R","R","F","F","F","F","R"]},
	"RoadCrossSmall": {"amount": 2, "t": ["F","R","R","R","F","F","F","F","R"]},
	"CastleTubeEntries": {"amount": 1, "t": ["R","C","R","C","F","F","F","F","C"]},
	"CastleTubeEntry": {"amount": 1, "t": ["F","C","R","C","F","F","F","F","C"]},
	"MonasteryCastle": {"amount": 1, "t": ["C","C","C","C","C","C","C","C","M"]},
	"MonasteryJunction": {"amount": 1, "t": ["R","R","R","R","F","F","F","F","M"]},
	"CastleSidesRoad": {"amount": 2, "t": ["C","R","C","R","F","F","F","F","R"]},
	"CastleSidesEdgeRoad": {"amount": 1, "t": ["C","R","R","C","F","F","F","O","R"]},
	"CastleSidesQuad": {"amount": 1, "t": ["C","C","C","C","O","O","O","O","F"]},
	"RoadEnd": {"amount": 1, "t": ["F","F","R","F","F","F","F","F","O"]},
	"CastleCenterSides": {"amount": 1, "t": ["F","F","C","F","O","O","O","O","C"]},
	"CastleMini": {"amount": 1, "t": ["F","F","R","F","F","F","F","F","C"]},
	"CastleWallEntryLeft": {"amount": 1, "t": ["C","F","F","R","F","F","F","F","R"]},
	"CastleWallEntryRight": {"amount": 1, "t": ["C","R","F","F","F","F","F","F","R"]},
	"CastleWallEntry": {"amount": 2, "t": ["C","F","R","F","F","F","F","F","R"]},
}

const ESCUDOS := {
	"CastleCenter": [0],
	"CastleCenterSides": [2],
	"CastleTube": [1],
	"CastleSidesRoad": [0],
	"CastleEdgeRoad": [0],
}

const TILE_INICIAL := "CastleWallRoad"
