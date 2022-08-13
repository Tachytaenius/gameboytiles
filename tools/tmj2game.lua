local json = require("tools.lib.json")

-- expects embedded tilesets

local mapBinLength = 20 * 18
local tilePropertyCollisionShift = 4
local warpsShift = 0
local warpsIterationStart, warpsIterationStop = 1, 15

local inputPath = select(1, ...)
local outputPath = select(2, ...) -- makes three files
local mapName = select(3, ...)

local tmjFile = io.open(inputPath, "r")
local tmjString = tmjFile:read("*a")
tmjFile:close()

local tmjTable = json.decode(tmjString)

local function findProperty(name)
	for _, property in ipairs(tmjTable.properties) do
		if property.name == name then
			return property
		end
	end
end

local GidToGameId = {} -- To have position 0 in tileset correspond to 0 etc
for _, tileset in ipairs(tmjTable.tilesets) do
	for gameIdPlusOne, tile in ipairs(tileset.tiles) do
		assert(not GidToGameId[tileset.firstgid + tile.id])
		GidToGameId[tileset.firstgid + tile.id] = gameIdPlusOne - 1
	end
end

local incString =
	"SECTION \"" .. mapName .. "\", ROMX\n\n" ..
	"x" .. mapName .. "::\n" ..
	".tileTypes\n" .. -- could easily make this exported if need be
	"\tINCBIN \"" .. outputPath .. "-tile-types.bin\"\n" ..
	".tileProperties\n" ..
	"\tINCBIN \"" .. outputPath .. "-tile-properties.bin\"\n"

for _, edge in ipairs({"left", "right", "top", "bottom"}) do
	incString = incString .. "." .. edge .. "EdgeWarp\n"
	local property = findProperty(edge .. "EdgeWarp")
	if property then
		incString = incString .. "\tDefEdgeWarp x" .. property.value .. "\n"
	else
		incString = incString .. "\tdb 0\n\tdw 0\n"
	end
end

incString = incString .. ".tileWarps\n"
for i = warpsIterationStart, warpsIterationStop do
	local property = findProperty("warp" .. i)
	if property then
		incString = incString .. "\tDefTileWarp " .. property.value.destinationX .. ", " .. property.value.destinationY .. ", x" .. property.value.destinationMap .. "\n"
	end
end

local tileTypesBinTable = {}
local tilePropertiesBinTable = {}
for i = 1, mapBinLength do
	tilePropertiesBinTable[i] = 0
end

for _, layer in ipairs(tmjTable.layers) do
	if layer.name == "Types" then
		for i, tileGid in ipairs(layer.data) do
			tileTypesBinTable[i] = GidToGameId[tileGid]
		end
	elseif layer.name == "Collision" then
		for i, tileGid in ipairs(layer.data) do
			tilePropertiesBinTable[i] = tilePropertiesBinTable[i] | GidToGameId[tileGid] << tilePropertyCollisionShift
		end
	elseif layer.name == "Warps" then
		for i, tileGid in ipairs(layer.data) do
			tilePropertiesBinTable[i] = tilePropertiesBinTable[i] | GidToGameId[tileGid] << warpsShift
		end
	end
end

local incFile = io.open(outputPath .. ".inc", "w+")
incFile:write(incString)
incFile:close()

for i, integer in ipairs(tileTypesBinTable) do
	tileTypesBinTable[i] = string.char(integer)
end
local tileTypesBinString = table.concat(tileTypesBinTable)
assert(#tileTypesBinString == mapBinLength)
local tileTypesBinFile = io.open(outputPath .. "-tile-types.bin", "w+")
tileTypesBinFile:write(tileTypesBinString)
tileTypesBinFile:close()

for i, integer in ipairs(tilePropertiesBinTable) do
	tilePropertiesBinTable[i] = string.char(integer)
end
local tilePropertiesBinString = table.concat(tilePropertiesBinTable)
assert(#tilePropertiesBinString == mapBinLength)
local tilePropertiesBinFile = io.open(outputPath .. "-tile-properties.bin", "w+")
tilePropertiesBinFile:write(tilePropertiesBinString)
tilePropertiesBinFile:close()
