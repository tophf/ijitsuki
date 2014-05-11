export script_name = 'JumpScroll'
export script_description = 'Save/load subtitle grid scrollbar position (MSWindows only)'

ok, ffi = pcall require, 'ffi'
return if not ok or jit.os != 'Windows'

ffi.cdef[[
uintptr_t GetForegroundWindow();
uintptr_t SendMessageA(uintptr_t hWnd, uintptr_t Msg, uintptr_t wParam, uintptr_t lParam);
uintptr_t FindWindowExA(uintptr_t hWndParent, uintptr_t hWndChildAfter, uintptr_t lpszClass, uintptr_t lpszWindow);
]]

jumpscroll_max = 3
jumpscroll = [nil for i=1,jumpscroll_max]

h = nil
msgs = {WM_VSCROLL:0x0115, SBM_SETPOS:0xE0, SBM_GETPOS:0xE1,
        SB_THUMBPOSITION:4, SB_ENDSCROLL:8, SB_SETTEXT:0x401}

get_handle = ->
    if not h
        h = {}
        h.App = ffi.C.GetForegroundWindow!
        h.Statusbar = ffi.C.FindWindowExA h.App, 0, ffi.cast('uintptr_t','msctls_statusbar32'), 0
        h.Container = ffi.C.FindWindowExA h.App, 0, ffi.cast('uintptr_t','wxWindowNR'), 0
        h.SubsGrid = ffi.C.FindWindowExA h.Container, 0, 0, 0
        h.Scrollbar = ffi.C.FindWindowExA h.SubsGrid, 0, 0, 0
    h.App != 0

update_statusbar = (i, saved=true) ->
    if h.Statusbar
        ffi.C.SendMessageA h.Statusbar, msgs.SB_SETTEXT, 0,
            ffi.cast 'uintptr_t',
                ('JumpScroll #%d: %s position %d')\format i, saved and 'saved' or 'scrolled to', jumpscroll[i]

save_scroll_pos = (i) ->
    return unless get_handle!
    jumpscroll[i] = tonumber ffi.C.SendMessageA h.Scrollbar, msgs.SBM_GETPOS, 0, 0
    update_statusbar i

load_scroll_pos = (i) ->
    return unless jumpscroll[i] and get_handle!
    ffi.C.SendMessageA h.SubsGrid, msgs.WM_VSCROLL, msgs.SB_THUMBPOSITION, h.Scrollbar
    ffi.C.SendMessageA h.Scrollbar, msgs.SBM_SETPOS, jumpscroll[i], 0
    ffi.C.SendMessageA h.SubsGrid, msgs.WM_VSCROLL, msgs.SB_ENDSCROLL, h.Scrollbar
    update_statusbar i, false

for i=1,jumpscroll_max
    aegisub.register_macro script_name..'/save/'..i,
        'Remember subtitle grid scrollbar position as #'..i,
        -> save_scroll_pos i

for i=1,jumpscroll_max
    aegisub.register_macro script_name..'/load/'..i,
        'Scroll to subtitle grid scrollbar position previously saved in #'..i,
        -> load_scroll_pos i
