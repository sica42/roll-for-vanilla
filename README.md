# RollFor
A World of Warcraft (1.12.1) addon that automates rolling for items.  

The addon **does NOT** distribute loot, it only automates rolling and announces
winners.  
It's ulitmately your decision who you'll assign the loot to and how
you do it (trade or master loot).

## Features
### Shows the loot that dropped (and who soft reserved)
<img src="docs/dropped-loot.gif" alt="Shows dropped loot" style="width:720px;height:350">

---

### Makes Master Loot window pretty and safe
* one window with players sorted by class
* adds confirmation window

![](docs/master-loot-window.gif)

---

### Fully automated
 * Detects if someone rolls too many times and ignores extra rolls.
 * If multiple players roll the same number, it automatically shows it and
   waits for these players to re-roll.

---

### Soft res integration
 * Integrates with https://raidres.fly.dev.
 * Minimap icon shows soft res status and who did not soft res.
 * Fully automated (shows who soft ressed, only accepts rolls from players who SR).

---

### And more
 * Supports "**two top rolls win**" rolling.
 * Supports **raid rolls**.

---

### See it in action
https://youtu.be/vZdafun0nYo


## Usage

### In the loot window

Shift + left click for `/rf`.  
Alt + left click for `/rr`.


### Basic item roll
```
/rf <item>
```

---


### Basic item roll with custom rolling time
```
/rf <item> <seconds>
```

---


### Basic item roll with a message
```
/rf <item> <message...>
```

---


### Basic item roll with custom rolling time and a message
```
/rf <item> <seconds> <message...>
```

---


### Roll for 2 items (two top rolls win)
```
/rf 2x<item>
```

---


### Ignore SR and allow everyone to roll
If the item is SRed, the addon will only watch rolls for players who SRed.
However, if you want everyone to roll, even if the item is SRed, use `/arf`
instead of `/rf`. "arf" stands for "All Roll For".

---


## Soft-Res setup

1. Create a Soft Res list at https://raidres.fly.dev.  
2. Use this tool to export the data: https://github.com/obszczymucha/raidres-parser-rust.  
3. Click on the minimap icon or type `/sr`.  
5. Paste the data into the window.  
6. Click *Close*.  

The addon will tell you the status of SR import.  
Hovering over the minimap icon will tell you who did not soft-res.  
If you see `Soft-res setup is complete.` then it means you're good to go.
The minimap icon will go **green** if everyone in the group is soft-ressing.  
The minimap icon will be **orange** if someone has not soft-ressed.
The minimap icon will be **red** if you have an outdated soft-res data.  
The minimap icon will be **white** if there is no soft-res data.  

---


### Fixing mistyped player names in SR setup

When using soft-res, the players sometimes mistype their nickname, e.g. 
`Johnny` in game will be `Jonnhy` in the raidres.fly.dev website.  
The addon is smart enough to fix simple typos like that for you.  
It will also deal with special characters in player names.  
However, sometimes there's so many typos and the addon can't match the  
player's name - you have to fix it manually.  

`/sro` (stands for SR Override) is the command to do this.  

---


### Finish rolls early
```
/fr
```

---


### Cancel rolls
```
/cr
```

---


### Showing SRed items
```
/srs
```

---


### Checking SRed items
```
/src
```

---


### Clearing SR data
Do this if you're starting a new raid.
```
/sr init
```

---


## Need more help?

Feel free to hit me up in-game if you need more help.  
Whisper **Jogobobek** on Nordaanar Turtle WoW or
**Obszczymucha** on Discord.

