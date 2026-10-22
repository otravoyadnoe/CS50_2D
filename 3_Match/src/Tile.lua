--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety, shiny)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety
    self.shiny = shiny

    -- the particle system for our "shiny" tiles
    if self.shiny == true then
        self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 5)
        self.psystem:setEmitterLifetime(-1)
        self.psystem:setParticleLifetime(1, 2)
        self.psystem:setEmissionArea('borderrectangle', 12, 12)
        self.psystem:setEmissionRate(3)
        self.psystem:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0)
        self.psystem:start()
    end
end

function Tile:update(dt)
    if self.shiny == true then
        self.psystem:update(dt)
    end
end

function Tile:render(x, y)
    -- draw shadow
    love.graphics.setColor(34/255, 32/255, 52/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    -- draw the particles
    if self.shiny == true then
        love.graphics.draw(self.psystem, self.x + x + 16, self.y + y + 16)
    end
end