-- number_first.lua
-- 检测输入是否是 1-9，并在第一位插入该数字

local digit_map_1 = {
    ["1"] = {"1", "①"},
    ["2"] = {"2", "②"},
    ["3"] = {"3", "③"},
    ["4"] = {"4", "④"},
    ["5"] = {"5", "⑤"},
    ["6"] = {"6", "⑥"},
    ["7"] = {"7", "⑦"},
    ["8"] = {"8", "⑧"},
    ["9"] = {"9", "⑨"},
    ["0"] = {"0", "⓪"},
}

local digit_map_2 = {
    ["1"] = {"1️⃣", "❶"},
    ["2"] = {"2️⃣", "❷"},
    ["3"] = {"3️⃣", "❸"},
    ["4"] = {"4️⃣", "❹"},
    ["5"] = {"5️⃣", "❺"},
    ["6"] = {"6️⃣", "❻"},
    ["7"] = {"7️⃣", "❼"},
    ["8"] = {"8️⃣", "❽"},
    ["9"] = {"9️⃣", "❾"},
    ["0"] = {"0️⃣", "⓿"},
}

local function yield_digit_list(list)
    for _, value in ipairs(list) do
        local cand = Candidate("raw", 0, 1, value, "")
        yield(cand)
    end
end

local function filter(input, env)
    local context = env.engine.context
    local input_str = context.input

    local is_length_one_digit = string.match(input_str, "^%d$")
    if is_length_one_digit then
        yield_digit_list(digit_map_1[input_str])
    end
    
    -- 之后正常输出其他的候选词
    for cand in input:iter() do
        yield(cand)
    end

    if is_length_one_digit then
        yield_digit_list(digit_map_2[input_str])
    end
end

return filter
