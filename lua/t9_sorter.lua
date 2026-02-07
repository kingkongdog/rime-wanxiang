-- 目标：使用原生 utf8 库实现动态候选词排序

local function sort_filter(input)
    local l = {}
    -- 获取所有候选词
    for cand in input:iter() do
        table.insert(l, cand)
    end

    if #l == 0 then return end

    local start_sort_index = -1
    
    -- 使用 utf8.len 计算第一个候选词的字符长度
    -- 注意：Lua 原生 utf8.len 对非法序列会返回 nil，所以加个 or 0 保险
    local first_len = utf8.len(l[1].text) or 0

    -- 判定逻辑
    if first_len == 1 then
        -- 第一个是单字/表情，从第 9 个开始排序
        if #l >= 9 then
            start_sort_index = 9
        end
    else
        -- 第一个是词组，寻找列表中第一个出现的单字
        for i = 2, #l do
            if (utf8.len(l[i].text) or 0) == 1 then
                start_sort_index = i
                break
            end
        end
    end

    yield(Candidate("raw", 0, #tostring(start_sort_index), tostring(start_sort_index), ""))

    -- 渲染输出
    -- if start_sort_index == -1 then
    --     for i = 1, #l do yield(l[i]) end
    -- else
    --     -- 输出前缀部分
    --     for i = 1, start_sort_index - 1 do
    --         yield(l[i])
    --     end

    --     -- 提取并按字母顺序排序
    --     local sort_part = {}
    --     for i = start_sort_index, #l do
    --         table.insert(sort_part, l[i])
    --     end

    --     table.sort(sort_part, function(a, b)
    --         -- 优先使用输入码(code)排序，如果 code 相同或不存在则按文本内容排序
    --         local key_a = (a.code ~= "" and a.code) or a.text
    --         local key_b = (b.code ~= "" and b.code) or b.text
    --         return key_a < key_b
    --     end)

    --     -- 输出排序后的部分
    --     for _, cand in ipairs(sort_part) do
    --         yield(cand)
    --     end
    -- end
end

return sort_filter