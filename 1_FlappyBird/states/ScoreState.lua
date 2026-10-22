--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
    
    -- quit the game if escape is pressed
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function ScoreState:render()
    -- render the score to the middle of the screen
    -- bronze medal is for scoring higher than 0
    -- silver medal is for scoring higher than 2
    -- gold medal is for scoring higher than 4
    if self.score > 0 and self.score < 3 then
        love.graphics.draw(gTextures['medalBronze'], VIRTUAL_WIDTH / 2 - 36, VIRTUAL_HEIGHT / 2 - 36)
    end
    if self.score > 2 and self.score < 5 then
        love.graphics.draw(gTextures['medalSilver'], VIRTUAL_WIDTH / 2 - 36, VIRTUAL_HEIGHT / 2 - 36)
    end
    if self.score > 4 then
        love.graphics.draw(gTextures['medalGold'], VIRTUAL_WIDTH / 2 - 36, VIRTUAL_HEIGHT / 2 - 36)
    end

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 80, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to Play Again!', 0, 194, VIRTUAL_WIDTH, 'center')
end