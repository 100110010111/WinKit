-- Clink configuration script
-- This file should be placed in %LOCALAPPDATA%\clink\

-- Set up aliases when Clink starts
local function setup_aliases()
    -- Get the path to the clink_start.cmd file
    local clink_config_dir = os.getenv("LOCALAPPDATA") .. "\\clink"
    local alias_script = clink_config_dir .. "\\clink_start.cmd"
    
    -- Check if the alias script exists and run it
    local file = io.open(alias_script, "r")
    if file then
        file:close()
        os.execute('"' .. alias_script .. '"')
    end
end

-- Run setup on Clink startup
setup_aliases()

-- Add custom prompt (optional)
local function custom_prompt()
    local cwd = clink.get_cwd()
    local home = os.getenv("USERPROFILE")
    
    -- Replace home path with ~
    if cwd:find(home, 1, true) == 1 then
        cwd = "~" .. cwd:sub(#home + 1)
    end
    
    -- Color codes
    local green = "\x1b[32m"
    local blue = "\x1b[34m"
    local reset = "\x1b[0m"
    
    return green .. cwd .. blue .. " > " .. reset
end

-- Uncomment to enable custom prompt
-- clink.prompt.register_filter(custom_prompt, 1)