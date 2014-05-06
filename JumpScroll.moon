export script_name = 'JumpScroll'
export script_description = 'Save/load subtitle grid scrollbar position (MSWindows only)'

ok, ffi = pcall require, 'ffi'
return if not ok or ffi.os != 'Windows'

ffi.cdef[[
uintptr_t GetForegroundWindow();
uintptr_t SendMessageA(uintptr_t hWnd, uintptr_t Msg, uintptr_t wParam, uintptr_t lParam);
uintptr_t FindWindowExA(uintptr_t hWndParent, uintptr_t hWndChildAfter, const char *lpszClass, const char *lpszWindow);
]]

jumpscroll_max = 3
jumpscroll = [nil for i=1,jumpscroll_max]

WM_VSCROLL = 0x0115
SBM_SETPOS = 0xE0
SBM_GETPOS = 0xE1
SB_THUMBPOSITION = 4
SB_ENDSCROLL = 8
SB_SETTEXT = 0x400 + 1

hApp = ffi.C.GetForegroundWindow!
hStatusbar = ffi.C.FindWindowExA hApp, 0, 'msctls_statusbar32', nil
hContainer = ffi.C.FindWindowExA hApp, 0, 'wxWindowNR', nil
hSubsGrid = ffi.C.FindWindowExA hContainer, 0, nil, nil
hScrollbar = ffi.C.FindWindowExA hSubsGrid, 0, nil, nil

update_statusbar = (i, saved=true) ->
    if hStatusbar
        ffi.C.SendMessageA hStatusbar, SB_SETTEXT, 0,
            ffi.cast 'uintptr_t',
                ('JumpScroll #%d: %s position %d')\format i, saved and 'saved' or 'scrolled to', jumpscroll[i]

save_scroll_pos = (i) ->
    jumpscroll[i] = tonumber ffi.C.SendMessageA hScrollbar, SBM_GETPOS, 0, 0
    update_statusbar i

load_scroll_pos = (i) ->
    return if not jumpscroll[i]
    ffi.C.SendMessageA hSubsGrid, WM_VSCROLL, SB_THUMBPOSITION, hScrollbar
    ffi.C.SendMessageA hScrollbar, SBM_SETPOS, jumpscroll[i], 0
    ffi.C.SendMessageA hSubsGrid, WM_VSCROLL, SB_ENDSCROLL, hScrollbar
    update_statusbar i, false

for i=1,jumpscroll_max
    aegisub.register_macro script_name..'/save/'..i,
        'Remember subtitle grid scrollbar position as #'..i,
        -> save_scroll_pos i

for i=1,jumpscroll_max
    aegisub.register_macro script_name..'/load/'..i,
        'Scroll to subtitle grid scrollbar position previously saved in #'..i,
        -> load_scroll_pos i
