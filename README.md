[Aegisub](https://github.com/Aegisub/Aegisub) moonscript macros
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
* missing styles - *lines using non-existant styles will look wrong*

![Screenshot](http://img801.imageshack.us/img801/1775/p620.png)

Puts results into the Effect field (1), and/or selects lines (2), and/or displays a mini log (3).<br>
In the first case you can navigate between such lines using two supplementary macros:
* **Blame: Go to previous**
* **Blame: Go to next**

Tip: assign handy hotkeys in Options like Ctrl-Up and Down arrows, for example.

### [Position shifter](Position shifter.moon)
Shifts position tags in selected lines (\pos,\move,\org,\clip).
![Screenshot](http://img407.imageshack.us/img407/3419/2fs7.png)

### [Remove unused styles](Remove unused styles.moon)
Removes styles not referenced in dialogue lines (comment lines are ignored).<br>
Also reports orphaned lines that reference a non-existant style.

![Screenshot](http://img203.imageshack.us/img203/6941/eas7.png)

### [Selegator](Selegator.moon)
Select/navigate in the subtitle grid.

* Current style related:
 * **Current style -> select all** - select all lines with the same style as the current line
 * **Current style -> previous** - go to previous line with the same style as the current line
 * **Current style -> next** - go to next line with the same style as the current line
 * **Current style -> first in block** - go to the first line in current block of lines with the same style
 * **Current style -> last in block** - go to the last line in current block of lines with the same style
 * **Current style -> select block** - select all lines in current block of lines with the same style
* **Select till start** - unlike built-in Shift-Home, it preserves the active line
* **Select till end** - unlike built-in Shift-End, it preserves the active line

Assigning hotkeys makes these _really_ handy.
NB. You can redefine the built-in Shift-Home/End hotkeys with 'Select till start/end' macros in the 'Subtitle Grid' section of Options->Hotkeys.

### [Splitter](Splitter.moon)

* **Split by \\N** - split dialogues like -Person\N-Another person, also trim spaces/hyphens at start and estimate durations
* **Split 1 frame** - split after the 1st frame to prevent disappearing of subtitles, that start exactly at video chapter mark, when Jump-to-next-chapter hotkey/button is used in a video player.
* **Split 1 frame on chapters** - same as above but reads a user specified chapters file and automatically fixes the affected lines.

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
