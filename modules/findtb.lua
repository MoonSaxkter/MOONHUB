local function start_challenge_via_remote(name, chapter, difficulty)
    name       = name or LAST_SELECTED or "Challenge1"
    chapter    = chapter or CHAPTER
    difficulty = difficulty or DIFFICULTY

    -- First: select/confirm the challenge in the lobby
    local selectPayload = {
        Chapter    = chapter,
        Type       = "Lobby",
        Name       = name,
        Friend     = true,
        Mode       = "Pod",
        Update     = true,
        Difficulty = difficulty
    }

    -- Second: press the Start button to join the place
    local startPayload = {
        Start  = true,
        Type   = "Lobby",
        Update = true,
        Mode   = "Pod"
    }

    -- Send selection/confirm
    pcall(function()
        RF:InvokeServer(selectPayload)
    end)

    -- Brief yield so server/client state can update
    Run.RenderStepped:Wait()
    task.wait(0.10)

    -- Send Start (with a lightweight retry in case of brief race conditions)
    for _ = 1, 2 do
        local ok = pcall(function()
            RF:InvokeServer(startPayload)
        end)
        if ok then break end
        task.wait(0.15)
    end
end
