[Aegisub 3](https://github.com/Aegisub/Aegisub) moonscript macros
========

### [Add edgeblur](Add edgeblur.moon)
Adds \\be1 tags to selected lines.
Affects only the lines that do not have the \be or \blur tag.

### [Add tags](Add tags.moon)
Adds user-specified tags to all/selected lines.<br>
20 last used tags are remembered between sessions and may be re-applied (or just loaded) later.

![Screenshot](http://img542.imageshack.us/img542/8342/ufhi.png)

### [Blame](Blame.moon)
Marks lines exceeding specified limits:
* minimum/maximum durations - *lines dangerously shortened by TPP's keyframe snapping, for example.*
* CPS - characters per second - *excessively verbose lines.*
* line count - *3-liners!!1*
* overlaps - *TPP may easily produce those*
* missing styles - *lines using non-existent styles will look wrong*

![Screenshot](http://img801.imageshack.us/img801/1775/p620.png)

Puts results into the Effect field (1), and/or selects lines (2), and/or displays a mini log (3).<br>
In the first case you can navigate between such lines using two supplementary macros:
* **Go to previous**
* **Go to next**

Tip: assign handy hotkeys in Options like Ctrl-Up and Down arrows, for example.

### [JumpScroll](JumpScroll.moon)
Saves/loads subtitle grid scrollbar position.<br/>
Requires Aegisub with LuaJIT and win32/64 (r8238 or v3.2 and newer).<br/>
Number of "memory spots" for positions is set in the macro, *jumpscroll_max = 3* by default.<br/>
Assign hotkeys to use it effectively e.g. Ctrl-F1...F3 to save, Shift-F1...F3 to jump.<br/>
Currently it doesn't save these positions to a file so it's session-only.

### [Position shifter](Position shifter.moon)
Shifts position tags in selected lines (\pos,\move,\org,\clip,\p).<br/>
![Screenshot](http://i.imgur.com/MGzi22j.png)

### [Remove unused styles](Remove unused styles.moon)
Removes styles not referenced in dialogue lines (comment lines are ignored).<br>
Also reports lines that reference a non-existent style ("orphaned lines").

![Screenshot](http://img203.imageshack.us/img203/6941/eas7.png)

### [Selegator](Selegator.moon)
Select/navigate in the subtitle grid.

* Current style related:
 * **Current style/select all** - select all lines with the same style as the current line
 * **Current style/previous** - go to previous line with the same style as the current line
 * **Current style/next** - go to next line with the same style as the current line
 * **Current style/first in block** - go to the first line in current block of lines with the same style
 * **Current style/last in block** - go to the last line in current block of lines with the same style
 * **Current style/select block** - select all lines in current block of lines with the same style
* **Select till start** - unlike built-in Shift-Home, it preserves the active line
* **Select till end** - unlike built-in Shift-End, it preserves the active line

Assigning hotkeys makes these _really_ handy.
NB. You can redefine the built-in Shift-Home/End hotkeys with 'Select till start/end' macros in the 'Subtitle Grid' section of Options->Hotkeys.

### [Splitter](Splitter.moon)

* **Split by \\N** - split dialogues like -Person\N-Another person, also trim spaces/hyphens at start and estimate durations
* **Split 1 frame** - split after the 1st frame to prevent disappearing of subtitles, that start exactly at video chapter mark, when Jump-to-next-chapter hotkey/button is used in a video player.
* **Split 1 frame on chapters** - same as above but reads a user specified chapters file and automatically fixes the affected lines.

### [Title Case](Title Case.moon)

Applies English Title Case (maintains lower case on prepositions and other auxiliary words) to the selected lines.

### [Wrap in curly braces](Wrap in curly braces.moon)
Wraps all/selected lines in {}.<br>
Helps translating subtitles since the text in {} isn't shown on video.<br>
Original override tags are preserved inside \<\>.

- - -
<sup>
P.S.
<br/>
Add tags & Position shifter are enhanced moonscript versions of lua-macros originally written by [Youka](http://forum.youka.de/index.php?topic=4.0).
<br/>
Remove unused styles originated from pieceofsummer's CleanStyles.
</sup>
