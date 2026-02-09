local function with_dot_processor(key, env)
  local engine = env.engine
  local context = engine.context
  local krepr = key:repr()

  if key:release() then
      return 2
  end

  -- 获取当前是否为英文模式 (Shift 切换后的状态)
  if context:get_option("ascii_mode") then
    return 2
  end

  if not context:is_composing() and krepr == "period" then
    engine:commit_text("。")
    return 1
  end
end

return with_dot_processor