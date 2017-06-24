-- Visualizer test

local SoniqueVis = require("vis_kissfft")
local AudioObj
local SDObj
local VisObj

function love.load(arg)
	if love.filesystem.isFused() == false then
		table.remove(arg, 1)
	end
	
	local f = assert(io.open(arg[1], "rb"))
	SDObj = love.sound.newSoundData(love.filesystem.newFileData(f:read("*a"), arg[1]))
	AudioObj = love.audio.newSource(SDObj)
	VisObj = SoniqueVis.New("./sonique_visualizer/"..(arg[2] or "Rabbit Hole")..".dll", 800, 600)
		:Link(AudioObj, SDObj)
	
	AudioObj:play()
	f:close()
end

function love.update(dt)
	VisObj:Update(dt)
end

function love.draw()
	love.graphics.draw(VisObj)
	love.graphics.print(love.timer.getFPS().." FPS")
end

function love.mousereleased(x, y, button)
	--VisObj:Click(x / 2.5, y / 2.5, button)
	VisObj:Click(x, y, button)
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
