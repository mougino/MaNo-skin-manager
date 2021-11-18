
# Skin manager for MaNo, the Markdown Notepad

**MaNo** (for **Ma**rkdown **No**tepad)
is a lean editor for the Markdown language,
written by Nicolas Mougin (mailto:mougino@free.fr).

v1.3.0 of **MaNo** adds support for editor customization:
fonts, colors, line-number margin.

MaNo is available at http://mougino.free.fr/mano.html

This **skin manager** proposes a set of skins (themes)
that can be applied to the **MaNo** editor.

# License

**MaNo** skin manager 's code is provided under the GNU GPL V3 license.

See "gpl.txt" or https://www.gnu.org/licenses/gpl.html

# How to use

A skin is a .ini file with a set of properties:

```ini
[info]
Skin=Default
Description=Original MaNo font and colors
Author=mougino@free.fr
Version=V1 (2021-11-15)
[editor]
TextFont=Courier New
TextSize=11
TextForeColor=000000
TextBackColor=FFFFFF
LineNbShow=1
LineNbFont=Courier New
LineNbSize=13
LineNbForeColor=5FD3BC
LineNbBackColor=FFFFFF
```

Use the skin manager to apply a skin to the **MaNo** editor.

You can write your own skin (ini file).
If you do, please consider sharing it with mailto:mougino@free.fr
so it can be included in the pack, for others to enjoy :smile:

# How to build

MaNo skin manager is written and compiled with Classic PowerBasic v9.07.0205.
http://powerbasic.com
