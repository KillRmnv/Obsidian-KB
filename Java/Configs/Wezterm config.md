``` lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.window_background_opacity = 0.85 
config.font = wezterm.font('JetBrainsMono Nerd Font', {weight='Regular'})
config.font_size = 15.0
config.harfbuzz_features = {'calt', 'clig', 'liga'}
config.color_scheme = 'Catppuccin Mocha'
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true  -- ✅ Скрывать tab, если 1 вкладка
config.scrollback_lines = 10000


-- ✅ Позволяем вкладкам занимать как можно больше места
config.tab_max_width = 9999

-- ✅ Отключаем "модные" (fancy) вкладки для лучшего отображения сплошной заливки
config.use_fancy_tab_bar = false


config.window_frame = {
  active_titlebar_bg = '#1e1e2e',
  inactive_titlebar_bg = '#181825',
  active_titlebar_fg = '#cdd6f4',
  inactive_titlebar_fg = '#6c7086',
  border_left_color = '#1e1e2e',
  border_top_color = '#1e1e2e',
  border_right_color = '#1e1e2e',
  border_bottom_color = '#1e1e2e',
  border_left_width = 0,
  border_top_height = 0,
  border_right_width = 0,
  border_bottom_height = 0,
}

-- ✅ Выделение активного таба и растягивание на всю ширину
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local bg = '#313244'
  local fg = '#cdd6f4'

  if tab.is_active then
    bg = '#89b4fa'  -- Синий для активного
    fg = '#1e1e2e'  -- Тёмный текст
  end

  local title = tab.active_pane.title
  -- Вычисляем реальную ширину заголовка (с учетом иконок и широких символов)
  local title_width = wezterm.column_width(title)

  -- Динамически рассчитываем пробелы для заполнения и центрирования
  if title_width > max_width then
    -- Если текста больше, чем места — обрезаем
    title = wezterm.truncate_right(title, max_width)
  else
    -- Вычисляем нужное количество пробелов по бокам
    local padding = max_width - title_width
    local left_pad = math.floor(padding / 2)
    local right_pad = padding - left_pad
    
    -- Оборачиваем текст в пробелы
    title = string.rep(' ', left_pad) .. title .. string.rep(' ', right_pad)
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = title },
  }
end)

config.keys ={
    {
    key = 'w',
    mods = 'CTRL',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  },
  {
    key = 'd',
    mods = 'CTRL',
    action=wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain'},

  },
  {
    key = 'd',
    mods = 'CTRL|SHIFT',
    action=wezterm.action.SplitVertical { domain = 'CurrentPaneDomain'},

  },


}

return config
```