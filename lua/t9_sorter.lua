-- 功能：根据首个候选词的长度，动态调整后续单字的排序方式

local function sort_filter(input)
    local l = {}
    local first_is_single = false
    local start_sort_index = -1

    -- 1. 获取所有候选词并初步判断
    for cand in input:iter() do
        table.insert(l, cand)
        
        -- 仅在处理第一个词时判断
        if #l == 1 then
            -- 判断是否为单字或 Emoji (UTF-8 字符长度判断)
            -- utf8.len 能够准确计算字符数而非字节数
            if utf8.len(cand.text) == 1 then
                first_is_single = true
                start_sort_index = 9 -- 第1个是单字，从第9个开始排
            end
        end

        -- 如果首词是多字，寻找第一个出现的单字位置
        if not first_is_single and start_sort_index == -1 then
            if utf8.len(cand.text) == 1 then
                start_sort_index = #l
            end
        end
    end

    -- 2. 执行逻辑分发
    if start_sort_index == -1 or start_sort_index > #l then
        -- 如果没达到排序触发条件，直接原样输出
        for _, cand in ipairs(l) do yield(cand) end
    else
        -- 输出不需要排序的部分
        for i = 1, start_sort_index - 1 do
            yield(l[i])
        end

        -- 提取需要排序的部分
        local sort_part = {}
        for i = start_sort_index, #l do
            table.insert(sort_part, l[i])
        end

        -- 按拼音（code）升序排序
        -- table.sort(sort_part, function(a, b)
        --     return a.code < b.code
        -- end)

        -- 输出排序后的部分
        for _, cand in ipairs(sort_part) do
            yield(cand)
        end
    end
end

return sort_filter