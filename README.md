[Aegisub](https://github.com/Aegisub/Aegisub) moonscript macros
========

### [Add edgeblur](Add edgeblur.moon)
Adds \\be1 tags to selected lines. 
Affects only the lines that do not have the \be or \blur tag.

### [Add tags](Add tags.moon)
Adds user-specified tags to all/selected lines.
20 last used tags are remembered between sessions and may be re-used later.
![Screenshot](http://img823.imageshack.us/img823/2214/3c01.png)

### [Blame](Blame.moon)
Marks lines exceeding specified limits:
* minimum/maximum durations - lines dangerously shortened by TPP's keyframe snapping, for example.
* CPS - characters per second - excessively verbose lines.
* line count - 3-liners!!1
* overlaps - TPP may easily produce those
* missing styles - lines using non-existant styles will look wrong

![Screenshot](http://img801.imageshack.us/img801/1775/p620.png)

Puts results into the Effect field (1), and/or selects lines (2), and/or displays a mini log (3).
In the first case you can navigate between such lines using two supplementary macros:
* **Blame: Go to previous**
* **Blame: Go to next**
 
Tip: assign handy hotkeys in Options like Ctrl-Up and Down arrows, for example.

### [Position shifter](Position shifter.moon)
Shifts positions in selected lines with \pos,\move,\org,\clip
![Screenshot](http://img407.imageshack.us/img407/3419/2fs7.png)

### [Remove unused styles](Remove unused styles.moon)
Removes styles not referenced in dialogue lines (comment lines are ignored).
Also reports orphaned lines, that reference a non-existant style.

![Screenshot](http://img203.imageshack.us/img203/6941/eas7.png)

### [Select current style](Select current style.moon)
Selects all lines with style equal to current line's style.
Assigning a hotkey makes it really handy.

### [Split after 1st frame](Split after 1st frame.moon)
Splits selected lines after 1st frame.
Used to prevent disappearing of subtitles that start exactly at video chapter mark in case a user jumps to the chapter via Jump to next chapter hotkey/button while playing video file.

### [Wrap in {}](Wrap in curly braces.moon)
Wraps all/selected lines in curly braces.
Used bwhen translating subtitles to hide original content in {}.

- - -
<sup>
P.S.
<br/>
Add tags & Position shifter are enhanced moonscript versions of lua-macros originally written by [Youka](http://forum.youka.de/index.php?topic=4.0).
<br/>
Remove unused styles originated from pieceofsummer's CleanStyles.
</sup>
