-- Inactive-window dimming that coordinates with the patched tmux build.
--
-- tint.nvim dims nvim's own inactive *splits* with the SAME transform the tmux
-- colour_dim() patch uses (desaturate 30% toward luma, blend 35% toward bg), so
-- the whole setup looks consistent.
--
-- Double-dimming guard: when the nvim pane loses focus in tmux, tmux dims the
-- ENTIRE pane itself. So on FocusLost we untint every nvim window (let tmux do
-- it), and on FocusGained we re-tint the inactive ones. Requires tmux
-- `focus-events on` (set in tmux.conf).
return {
  'levouh/tint.nvim',
  event = 'VeryLazy',
  config = function()
    -- Match tmux dim_target. tmux dims toward the pane bg (~#18181f fallback);
    -- tweak to taste — only affects nvim's internal inactive splits.
    local dim_target = { r = 0x1e, g = 0x20, b = 0x30 }

    local function dim_transform(r, g, b)
      -- Step 1: desaturate 30% toward perceptual luma (Rec. 601).
      local luma = (299 * r + 587 * g + 114 * b) / 1000
      r = (r * 70 + luma * 30) / 100
      g = (g * 70 + luma * 30) / 100
      b = (b * 70 + luma * 30) / 100
      -- Step 2: blend 35% toward target background.
      r = (r * 65 + dim_target.r * 35) / 100
      g = (g * 65 + dim_target.g * 35) / 100
      b = (b * 65 + dim_target.b * 35) / 100
      return math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5)
    end

    require('tint').setup {
      transforms = {
        function(r, g, b)
          return dim_transform(r, g, b)
        end,
      },
    }

    -- Untint all windows when nvim loses focus (tmux dims the whole pane).
    vim.api.nvim_create_autocmd('FocusLost', {
      callback = function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          require('tint').untint(win)
        end
      end,
    })

    -- Re-tint inactive windows when nvim regains focus.
    vim.api.nvim_create_autocmd('FocusGained', {
      callback = function()
        local cur = vim.api.nvim_get_current_win()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if win ~= cur then
            require('tint').tint(win)
          end
        end
      end,
    })
  end,
}
