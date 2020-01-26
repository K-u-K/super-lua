--- Gets the value of a specific RAM address.
-- Accesses a RAM address and returns its value.
-- @param addr The RAM address.
function ReadMemByte(addr) 
	return memory.readbyte(addr)
end

--- Gets the current position of the player in the game.
-- Sets a table that contains the x and y values for the character.
function GetCharPos()
    Char = {}
	Char.x = ReadMemByte(0x6D) * 0x100 + ReadMemByte(0x86)
	Char.y = ReadMemByte(0x03B8) + 16
end

--- Gets the current positions of the enemies on the screen.
-- Sets a table that contains the x and y values for each enemie that is visible on screen.
function GetEnemyPos()
	Enemies = {}
	for slot = 0, 4 do
		if ReadMemByte(0xF + slot) > 0 then
			Enemies[#Enemies + 1] = {
                ["x"] = ReadMemByte(0x6E + slot) * 0x100 + ReadMemByte(0x87 + slot), 
                ["y"] = ReadMemByte(0xCF + slot) + 24
            }
		end
	end
end

--- Checks if on the current x and y coordinate a tile is displayed.
-- Returns a 0 if there is no tile otherwise a 1.
-- @param pos a table containing the x and y coordinates of the tile.
-- @return 0 or 1 depending on if there is a tile or not.
function GetTile(pos)
	local x = Char.x + pos.x + 8

	local page = math.floor(x / 256) % 2
	local tx = math.floor((x % 256) / 16)
	local ty = math.floor((Char.y + pos.y - 48) / 16)

	local addr = 0x500 + page * 208 + ty * 16 + tx

	if ty >= 13 or ty < 0 or ReadMemByte(addr) == 0 then
		return 0
	end

	return 1
end

--- Gathers the inputs for the neural network.
-- Returns tile information and how far away enemies are from the player.
-- @return a table that contains all information of the current screen.
function GetInputs()
	GetCharPos()
	GetEnemyPos()

    local areaLength = ViewArea * TileSize
    local inputs = {}
	local tile = {}

	for tx = -areaLength, areaLength, TileSize do
		for ty = -areaLength, areaLength, TileSize do
			inputs[#inputs + 1] = 0

            tile = {["x"] = tx, ["y"] = ty}
			if GetTile(tile) == 1 and (Char.y + tile.y) < 0x1B0 then
				inputs[#inputs] = 1
			end

			for i = 1, #Enemies do
				local distx = math.abs(Enemies[i].x - Char.x - tile.x)
				local disty = math.abs(Enemies[i].y - Char.y - tile.y)
				if distx <= 8 and disty <= 8 then
					inputs[#inputs] = -1
				end
			end
		end
	end
	return inputs
end