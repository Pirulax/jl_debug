function table.copy(orig)
    local copy = {}
    for orig_key, orig_value in pairs(orig) do
        if (type(orig_value)=="table") then
            table.copy(orig_value)
        else
            copy[orig_key] = orig_value
        end
        copy[orig_key] = orig_value
    end
    return copy
end