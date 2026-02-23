-- number_first.lua
-- 检测输入是否是 1-9，并在第一位插入该数字

local function filter(input, env)
    local context = env.engine.context
    local input_str = context.input

    -- 使用正则判断是否为纯数字
    if string.match(input_str, "^%d$") then
        -- 构造一个候选词：类型为 "number"，内容为输入字符串，注释为 "数字"
        local cand = Candidate("number", 0, #input_str, input_str, " 数字")
        yield(cand)
    end

    -- 之后正常输出其他的候选词
    for cand in input:iter() do
        -- 为了避免重复（如果后面也有这个数字），可以加个判断
        if cand.text ~= input_str then
            yield(cand)
        else
            -- 如果后面的候选词里也有这个数字，且不是我们手动置顶的那个，
            -- 可以根据需求决定是否保留。这里选择直接跳过以去重。
        end
    end
end

return filter