-- 目标：使用原生 utf8 库实现动态候选词排序

local function t9_sorter(input)
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
            if (utf8.len(l[i].text) or 0) == 1 and l[i].comment ~= "" then      -- comment 为 "" 的是 emoji
                start_sort_index = i
                break
            end
        end
    end

    -- 渲染输出
    if start_sort_index == -1 then
        for i = 1, #l do yield(l[i]) end
    else
        -- 输出前缀部分
        for i = 1, start_sort_index - 1 do
            yield(l[i])
        end

        -- 对剩余部分进行分组：将 Emoji 归入前一个汉字组
        local groups = {}
        local group_pinyin = ""
        for i = start_sort_index, #l do
            local cand = l[i]
            if #groups == 0 then                        -- 第一组
                table.insert(groups, {cand})
                group_pinyin = cand.comment
            elseif cand.comment == "" then              -- emoji 加入当前组
                table.insert(groups[#groups], cand)
            elseif cand.comment == group_pinyin then    -- 拼音一样，加入当前组
                table.insert(groups[#groups], cand)
            else                                        -- 拼音不一样，新开一组
                table.insert(groups, {cand})
                group_pinyin = cand.comment
            end
        end

        -- 对组进行排序（只比较组里的第一个候选词）
        table.sort(groups, function(group_a, group_b)
            local a = group_a[1]
            local b = group_b[1]

            -- 获取排序用的 Key
            local key_a = a.comment
            local key_b = b.comment

            return key_a < key_b
        end)

        -- 按组平铺输出
        for _, group in ipairs(groups) do
            for _, cand in ipairs(group) do
                yield(cand)
            end
        end
    end
end

return t9_sorter