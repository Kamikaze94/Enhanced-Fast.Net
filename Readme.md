#Enhanced Fast.Net
####Payday 2 Server Browser
  
This mod is a visually upgraded Version of Lastbullet_Big Bushy Beard's 'Fast.Net Standalone'.  
It started with the background panels, because the list was very hard to read with the blue default background.  
~~(Maybe my Monitor is just crap?  :P )~~
  
![Screenshot Preview](http://www.imghost.eu/images/2016/02/18/EnhancedFast.Net.jpg)
  
###Installation:
   Simply drag and drop the Contents of the downloaded archive into your mods-folder, and you are good to go.  
   __(You need the [BLT Hook](http://paydaymods.com/download/) for this mod to work)__
  
###Included Mods:
- __[FastNet Standalone](http://paydaymods.com/mods/79/fastnetstand)__, made by _Big Bushy Beard_, modified by me
	- Removed filters from the Serverlist
	- Added Background panels to different parts of the UI
	- Made labels on the left side permanent
	- Created a button panel in the bottom left for Filters, Sidejobs, Brooker, etc.
	- Added working keyboard shortcut support for Filters
	- Added marking of friends lobbies in the serverlist
	- Added advanced difficulty filters, for Hard+ to Overkill+
	- Added option to display 50 servers at once
- __[Persistent Filter Settings](https://steamcommunity.com/app/218620/discussions/15/46476691291148659/)__, made by _Seven_
	- Updated to load advanced filter settings correctly
- __[Reconnect to Server](http://forums.lastbullet.net/mydownloads.php?action=view_down&did=13546)__, made by _Luffy_
- __[Stale Lobby Fix](http://paydaymods.com/mods/277/stalelobbycontractfix)__, made by _Snh20_
  
###TODO:
- ~~Add aditional filter options~~ DONE!
- ~~Remove crimenet Map from the importet crimenet UIs~~
	- Probably not worth it, given I would need to detect, wether the UI was called through CrimeNet or FastNet and replace the fullscreen_ws in 'lib/managers/menu/...' for the second case
- ~~Restructure the way, the reconnect script is implemented~~ DONE!
