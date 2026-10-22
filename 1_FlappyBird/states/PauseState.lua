--[[
    Pause State
    Author: Artem Bondarev

    Pauses the game - turns off scrolling and just renders the bird, the pipes
    and the background until the player presses Enter to continue or Esc to quit.
]]

PauseState = Class{__includes = BaseState}

function PauseState:enter(params)
    self.bird = params.bird
    self.pipePairs = params.pipePairs
    self.score = params.score
    self.timer = params.timer
    self.lastY = params.lastY

    gSounds['pause']:play()
    gSounds['music']:pause()
end


-- basically just waits for either a space bar or escape to be pressed
function PauseState:update(dt)
    -- go back to play if space is pressed
    if love.keyboard.wasPressed('space') then
        gStateMachine:change('play', {
                    bird = self.bird,
                    score = self.score,
                    timer = self.timer,
                    lastY = self.lastY,
                    pipePairs = self.pipePairs
                })
    end

    -- quit the game if esc is pressed
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end


-- renders pipes and bird while paused so player knew the state of
-- their game when they unpause
function PauseState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    self.bird:render()

    love.graphics.setFont(hugeFont)
    love.graphics.printf("II", 0, 100, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(mediumFont)
    love.graphics.printf("Press Space to continue or Esc to quit", 0, 170, VIRTUAL_WIDTH, 'center')
end

function PauseState:exit()
    gSounds['music']:play()
end