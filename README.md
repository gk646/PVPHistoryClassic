![Maintained](https://img.shields.io/badge/Maintained%3F-yes-green.svg)
![WoW Classic](https://img.shields.io/badge/WoW%20Classic-v1.15.0-9cf.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![CurseForge Downloads](https://img.shields.io/curseforge/dt/960937)
### Download from the official [CurseForge website](https://legacy.curseforge.com/wow/addons/pvphistoryclassic)



PVPHistoryClassic+
------------------

**PVPHistoryClassic+ is a maintained addon for World of Warcraft Classic (Season of Discovery). It will automatically detect and save battleground data and present it in a easy way. 
It allows for sorting after common criteria like kills, deaths, or duration and plans to offer even more information like the player in your party, winrate across different battlegrounds and more.**

It will be maintained and updated with new features for the upcoming phases with simplicity and efficiency in mind.



## Purpose

Every time you enter a new battleground the addon will track its stats. When you leave the battleground it will finish the report and add it to a server wide database.
Per default all entries are filtered by the current character but you can remove and add this and other filters like type of BG, date, minimum amount of kills etc.

The first Tab shows you a history of all entries that match the filter, sortable after the main stats: Date, Name, Kills, HK's, Deahts, Honour, Duration.
The second Tab displays calculated stats across all entries. This includes the average per match for the main attributes above but also their totals and the winrate.

I plan to add line charts for tracking selected stats along timeframes and another one for average class distribution. 

**In the end it should be easy to answer the following questions with the help of the addon:**

-  Across all my winning Warsong Gluch games, how is the class distrubtion different from my losing ones? (And is this different across my charcters?)
- Did my average HK's go up in the last month? And if yes from where to where?
- Whats the average duration of all my losing Arathi Basin games?


## Tracking

It tracks all stats accesible from the WoW API, including both teams composition and stats (class, kills etc.).


## Planned Features

1. **Filters**: Filters are not implemented yet. Will work as described above.
2. **Tool Tip**: When enabled will share your winrate with other players if both have the addon installed to display each others stats on their tooltip

## Usage

Simply install the addon, and you wil get a minimap button. Clicking it toggles the Battleground Frame with all the tabs. You can also reach it by typing */pvphistory*. There are no additional commands or
configurations yet.
