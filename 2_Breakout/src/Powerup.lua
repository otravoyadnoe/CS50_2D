--[[
    CS50 2D
    Breakout Remake

    -- Powerup class--

    Author: Artem Bondarev
    otravoyadnoe@gmail.com

    Describes the powerups which have a chance to be generated
    when the brick is destroyed. Will fall towards the bottom of
    the screen and activate if collided with the paddle.
]]

Powerup = Class{}

function Powerup:init(powerType, active, spawned)
    -- type and skin of the powerup
    self.type = powerType

    if self.type == "plusBalls" then
        self.skin = 1
    else
        self.skin = 2
    end

    -- positional and dimensional variables, falls offscreen until spawned
    self.width = 16
    self.height = 16
    self.x = 0
    self.y = VIRTUAL_HEIGHT

    -- key powerup is essential thus needs to decay more slowly
    if self.type == "plusBalls" then
        self.dy = 100
    else
        self.dy = 50
    end

    -- game logic variables
    self.active = active
    self.spawned = spawned
end

    -- check for collision with the paddle
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    -- if the above aren't true, they're overlapping
    return true
end

    -- update just updates the powerup position as it falls down
function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    if self.spawned then
        love.graphics.draw(gTextures['powerups'], gFrames['powerups'][self.skin],
            self.x, self.y)
    end
end