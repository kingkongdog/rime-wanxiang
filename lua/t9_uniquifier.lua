local function t9_uniquifier(input, env)
    local map = {}
    for cand in input:iter() do
        -- 获取声调标签（假设你把声调存在了 cand.comment 里）
        -- 或者通过某些逻辑获取该候选词对应的原始拼音
        local key = cand.text .. cand.comment 
        
        if not map[key] then
            yield(cand)
            map[key] = true
        end
    end
end

return t9_uniquifier