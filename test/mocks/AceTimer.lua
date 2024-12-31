local M = {}

---@class AceTimerMock : AceTimer
---@field tick fun()
---@field repeating_tick fun( times: number? )

function M.new()
  local m_tick_fn = nil ---@type fun()?
  local m_repeating_tick_fn = nil ---@type fun()?

  local function schedule( _, f )
    m_tick_fn = f
    return 1337
  end

  local function schedule_repeating( _, f )
    m_repeating_tick_fn = f
    return 2
  end

  local function cancel( _, timer_id )
    if timer_id == 1 then m_tick_fn = nil end
    if timer_id == 2 then m_repeating_tick_fn = nil end
  end

  local function tick()
    if m_tick_fn then m_tick_fn() end
  end

  ---@param times number?
  local function repeating_tick( times )
    if not m_repeating_tick_fn then return end
    for _ = 1, times or 1 do m_repeating_tick_fn() end
  end

  ---@type AceTimerMock
  return {
    ScheduleTimer = schedule,
    ScheduleRepeatingTimer = schedule_repeating,
    CancelTimer = cancel,
    tick = tick,
    repeating_tick = repeating_tick
  }
end

return M
