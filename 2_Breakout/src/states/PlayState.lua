--[[
    CS50 2D
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.keyNeeded = params.keyNeeded
    self.sameLevel = params.sameLevel

    self.keyPowerup = params.keyPowerup
    self.keyPowerup.spawned = false
    self.ballsPowerup = Powerup('plusBalls', false, false)

    -- 25% chance for one of the bricks to be locked if the level is freshly generated
    if self.sameLevel == false and math.random(1, 100) <= 33 then
        self.keyNeeded = true
        brickLocked = false
        -- do a while loop while one of the bricks randomized to become color 6 (locked one)
        while brickLocked == false do
            for k, brick in pairs(self.bricks) do
                if math.random(1, 100) <= math.floor(k / 2) then
                    brick.color = 6
                    brick.tier = 0
                    brickLocked = true
                    break
                end
            end
        end
    end

    -- give ball random starting velocity
    for b, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    if #self.balls > 0 then
        self.paddle:update(dt)
        for b, ball in pairs(self.balls) do
            ball:update(dt)

            if ball:collides(self.paddle) then
                -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

                --
                -- tweak angle of bounce based on where it hits the paddle
                --

                local isPaddleMovingLeft = self.paddle.dx < 0
                local isPaddleMovingRight = self.paddle.dx > 0
                local paddleCenter = self.paddle.x + self.paddle.width / 2

                -- adjustable values for the feel of bounce speed/angle
                local startingBounceDX = 50
                local bounceAngleMultiplier = 8

                -- if we hit the paddle on its left side while moving left...
                if ball.x < paddleCenter and isPaddleMovingLeft then
                local ballOffset = paddleCenter - ball.x
                ball.dx = -startingBounceDX - bounceAngleMultiplier * ballOffset

                -- else if we hit the paddle on its right side while moving right...
                elseif ball.x > paddleCenter and isPaddleMovingRight then
                    local ballOffset = ball.x - paddleCenter
                    ball.dx = startingBounceDX + bounceAngleMultiplier * ballOffset
                end

                gSounds['paddle-hit']:play()
            end
        end

        -- detect collision across all bricks with the balls
        for b, ball in pairs(self.balls) do
            for k, brick in pairs(self.bricks) do

                -- only check collision if we're in play
                if brick.inPlay and ball:collides(brick) then

                    -- handle the possible powerups generation
                        if self.ballsPowerup.active == false and self.ballsPowerup.spawned == false then
                            if math.random(1, 100) <= 5  then
                                gSounds['powerup']:play()
                                self.ballsPowerup.spawned = true
                                self.ballsPowerup.x = brick.x + 8
                                self.ballsPowerup.y = brick.y
                            end
                        end

                        if self.keyPowerup.active == false and self.keyPowerup.spawned == false
                        and self.keyNeeded == true then
                            if math.random(1, 100) <= 5  then
                                gSounds['powerup']:play()
                                self.keyPowerup.spawned = true
                                self.keyPowerup.x = brick.x + 8
                                self.keyPowerup.y = brick.y
                            end
                        end

                    -- add to score
                    if brick.color <= 5 then
                        self.score = self.score + (brick.tier * 100 + brick.color * 25)
                    end
                    -- add a thousand if the brick hit was the unlocked one
                    if brick.color == 6 and self.keyPowerup.active == true then
                        self.score = self.score + 1000
                    end

                    -- trigger the brick's hit function, which reduces it's color/tier if not locked
                    if brick.color <= 5 or self.keyPowerup.active == true then
                        brick:hit()
                    else
                        gSounds['brick-hit-locked']:stop()
                        gSounds['brick-hit-locked']:play()
                    end

                    -- if we have enough points, increase the paddle size or recover a point of health
                    if self.score > self.recoverPoints then
                        if self.health < 3 then
                            -- can't go above 3 health
                            self.health = math.min(3, self.health + 1)
                        else
                            if self.paddle.size < 4 then
                                self.paddle.size = self.paddle.size + 1
                                self.paddle.width = self.paddle.width + 32
                            end
                        end

                        -- increase the amount of recover points
                        self.recoverPoints = math.min(200000, self.recoverPoints + 5000 * (1 + self.level / 50))

                        -- play recover sound effect
                        gSounds['recover']:play()
                    end

                    -- go to our victory screen if there are no more bricks left
                    if self:checkVictory() then
                        gSounds['victory']:play()

                        gStateMachine:change('victory', {
                            level = self.level,
                            paddle = self.paddle,
                            health = self.health,
                            score = self.score,
                            highScores = self.highScores,
                            recoverPoints = self.recoverPoints,
                            keyNeeded = self.keyNeeded
                        })
                    end

                    --
                    -- collision code for bricks
                    --
                    -- we check to see how much we overlap on the brick between X and Y axes;
                    -- the delta between the centers of the brick and ball will help us pinpoint
                    -- which side, and then how far in the ball has overlapped will determine
                    -- whether to prioritize a Y bounce or an X bounce

                    local BALL_RADIUS = 4
                    local BRICK_W, BRICK_H = brick.width, brick.height

                    -- centers of X and Y of our brick and ball
                    local cxB, cyB = brick.x + BRICK_W / 2, brick.y + BRICK_H / 2
                    local cxb, cyb = ball.x + BALL_RADIUS, ball.y + BALL_RADIUS

                    -- signed collision offsets between brick and ball
                    local ox = cxB - cxb
                    local oy = cyB - cyb

                    -- penetration depth of the ball on X and Y;
                    -- add half-extents of brick and ball, then subtract
                    -- amount of overlap on that axis; the higher penetration
                    -- depth is the prioritized collision and axis of bounce
                    local px = BRICK_W / 2 + BALL_RADIUS - math.abs(ox)
                    local py = BRICK_H / 2 + BALL_RADIUS - math.abs(oy)

                    if px < py then
                        ball.dx = -ball.dx
                        ball.x = ball.x + (ox > 0 and -px or px)
                    else
                        ball.dy = -ball.dy
                        ball.y = ball.y + (oy > 0 and -py or py)
                    end

                    -- slightly scale the y velocity to speed up the game, capping at +- 150
                    if math.abs(ball.dy) < 150 then
                        ball.dy = ball.dy * 1.02
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end
        end

        -- if ball goes below bounds, remove it from the table
        for b, ball in pairs(self.balls) do
            if ball.y > VIRTUAL_HEIGHT then
                table.remove(self.balls, b)
                if #self.balls == 1 then
                    self.ballsPowerup.active = false
                end
            end
        end

        -- for rendering particle systems
        for k, brick in pairs(self.bricks) do
            brick:update(dt)
        end

        if love.keyboard.wasPressed('escape') then
            love.event.quit()
        end
    else
        -- no balls left, decrease the paddle size or health
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.width - 32
        else
            self.health = self.health - 1
            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            end
        end

        gSounds['hurt']:play()
        gStateMachine:change('serve', {
        paddle = self.paddle,
        bricks = self.bricks,
        health = self.health,
        score = self.score,
        highScores = self.highScores,
        level = self.level,
        recoverPoints = self.recoverPoints,
        keyNeeded = self.keyNeeded,
        sameLevel = true,
        keyPowerup = self.keyPowerup
        })
    end

    -- spawned powerups handling
    self.ballsPowerup:update(dt)
    self.keyPowerup:update(dt)

    if self.keyPowerup:collides(self.paddle) then
        -- unlock the locked brick, despawn the spawned powerup
        gSounds['powerup']:play()
        self.keyNeeded = false
        self.keyPowerup.active = true
        self.keyPowerup.spawned = false
    end

    if self.ballsPowerup:collides(self.paddle) then
        -- despawn the spawned powerup
        gSounds['powerup']:play()
        self.ballsPowerup.spawned = false
        self.ballsPowerup.active = true

        -- generate two new balls
        table.insert(self.balls, Ball())
        table.insert(self.balls, Ball())
        for b, ball in pairs(self.balls) do
            if b > 1 then
                ball.x = self.ballsPowerup.x + (self.ballsPowerup.width / 2) - 2
                ball.y = self.paddle.y - 8
                ball.dx = math.random(-200, 200)
                ball.dy = math.random(-50, -60)
                ball.skin = math.random(7)
            end
        end

        -- make sure the despawned balls powerup doesn't collide with the paddle
        self.ballsPowerup.y = VIRTUAL_HEIGHT
    end

    -- despawn powerups when off the screen
    if self.ballsPowerup.y > VIRTUAL_HEIGHT then
        self.ballsPowerup.spawned = false
    end

    if self.keyPowerup.y > VIRTUAL_HEIGHT then
        self.keyPowerup.spawned = false
    end


end

function PlayState:render()
    -- render bricks (sorry for the locked brick quad rendering code being less than ideal =/ )
    for k, brick in pairs(self.bricks) do
        if self.keyPowerup.active == false and brick.color == 6 then
            love.graphics.draw(gTextures['main'], gFrames['bricks'][24], brick.x, brick.y)
        else
            brick:render()
        end
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    -- render all the balls
    for b, ball in pairs(self.balls) do
        ball:render()
    end

    -- render powerups
    self.ballsPowerup:render()
    self.keyPowerup:render()

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end