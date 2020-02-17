local json = require("json")

JsonWrapper = {}
JsonWrapper.__index = JsonWrapper

function JsonWrapper:create()
    local this = {}

    function this:writeToFile(content, filename)
        local file = io.open(filename, "w")
        if file then
            file:write(json.encode(content))
            io.close(file)
            return true
        else
            return false
        end
    end

    function this:readFromFile(filename)
        local file = io.open(filename, "r")
        if file then
            local content = json.decode(file:read("*a"))
            io.close(file)
            return content
        end
        return nil
    end
    setmetatable(this, self)
    return this
end