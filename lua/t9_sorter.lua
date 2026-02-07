-- 目标：使用原生 utf8 库实现动态候选词排序

local function t9_sorter(input)
    local l = {}

    -- 获取所有候选词
    for cand in input:iter() do
        table.insert(l, cand)
    end

    if #l == 0 then return end

    -- 获取第一个单字候选词索引
    -- 候选词排列是这样：多字候选词，然后单字候选词，多字和单字候选词后面都可能有 emoji，emoji 的长度一般是 1, comment 是 ""
    local first_single_index = -1
    local first_len = utf8.len(l[1].text)

    if first_len == 1 then
        first_single_index = 1
    else
        for i = 2, #l do
            if utf8.len(l[i].text) == 1 and l[i].comment ~= "" then
                first_single_index = i
                break
            end
        end
    end

    -- 全部是多字候选词
    if first_single_index == -1 then 
        for i = 1, #l do yield(l[i]) end
        return
    end

    -- 多字候选词直接 yield
    for i = 1, first_single_index - 1 do
        yield(l[i])
    end

    -- 单字候选词不到 18 个
    local multi_count = first_single_index - 1
    if #l - multi_count < 18 then
        for i = first_single_index, #l do 
            yield(l[i])
        end
        return
    end

    -- 前 18 个单字候选词直接 yield
    for i = first_single_index, first_single_index + 17 do 
        yield(l[i])
    end

    -- 剩余的单字按拼音排序
    local groups = {}
    local group_pinyin = ""
    for i = first_single_index + 18, #l do
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
        -- 分割线
        local sep = "====================================================="
        yield(Candidate("raw", l[1]._start, l[1]._end, "--- " .. group[1].comment .. " ---", sep))
        for _, cand in ipairs(group) do
            yield(cand)
        end
    end
end

return t9_sorter