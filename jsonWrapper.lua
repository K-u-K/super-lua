-- load the JSON library.
local json = require("json")

JsonWrapper = {}

JsonWrapper.writeToFile = function(content, filename)
    local file = io.open(filename, "w")
    if file then
        file:write(json.encode(content))
        io.close(file)
        return true
    else
        return false
    end
end

JsonWrapper.readFromFile = function(filename)
    local file = io.open(filename, "r")
    if file then
        local content = json.decode(file:read("*a"))
        io.close(file)
        return content
    end
    return nil
end

return JsonWrapper