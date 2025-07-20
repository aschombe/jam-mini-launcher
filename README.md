# JAM Mini Launcher
This is the game launcher for the JAM Mini.  
It is a simple game launcher for Stevens Game Development club's games.  
The JAM Mini itself is a small, portable machine that will be put into the UCC Game Room for anyone to use.  

Hardware details:
- M4 Mac Mini.... thats it.
- 4 wireless XBox One controllers

Any club members can port their game to the JAM Mini, by following the form in our discord server's "jam-mini" channel.

# Game Library Structure (can change based on specific device this is used on) (this has to be updated):
```
|__ /
   |__ Users
	  |__ sgdcuser
		 |__ MiniLauncher.app
		 |__ games
			|__ game1
			   |__ Game1.app
			   |__ game1.json
			   |__ game1.ogv
			   |__ game1.png
			|__ game2
			   |__ Game2.app
			   |__ game2.json
			   |__ game2.ogv
			   |__ game2.png   
```

# Json structure:
```json
{
  "name": "Game Name",
  "author": "Author Name",
  "description": "Game Description",
  "genres": "Genre1-Genre2-Genre3",
  "type": "# of players",
  "creation_year": "Year Created",
  "grad_year": "Year Graduated",
}
```
# Todo:
- [ ] Keep track of the # of times a game has been launched and the time a game as spent open, and save it to that game's respective folder as stats.json
- [ ] Clean up files and style
