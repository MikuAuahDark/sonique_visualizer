-- Visualizer test

local SoniqueVis = require("vis_kissfft")
local AudioObj
local SDObj
local VisObj
local shader = love.graphics.newShader [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 c = Texel(texture, texture_coords);
	return 1.0 - c;
}
]]

function love.load(arg)
	if love.filesystem.isFused() == false then
		table.remove(arg, 1)
	end
	
	local f = assert(io.open(arg[1], "rb"))
	SDObj = love.sound.newSoundData(love.filesystem.newFileData(f:read("*a"), arg[1]))
	AudioObj = love.audio.newSource(SDObj)
	VisObj = SoniqueVis.New("./sonique_visualizer/"..(arg[2] or "Rabbit Hole")..".dll", 320, 240)
		:Link(AudioObj, SDObj)
	
	AudioObj:play()
	f:close()
end

function love.update(dt)
	VisObj:Update(dt)
end

function love.draw()
	love.graphics.draw(VisObj, 0, 0, 0, 2.5)
	love.graphics.print(love.timer.getFPS().." FPS")
end

function love.mousereleased(x, y, button)
	VisObj:Click(x / 2.5, y / 2.5, button)
end

function love.keyreleased(key)
	if key == "return" or key == "escape" then
		love.event.quit()
	elseif key == "space" then
		if AudioObj:isPlaying() then
			AudioObj:pause()
		else
			AudioObj:play()
		end
	end
end
