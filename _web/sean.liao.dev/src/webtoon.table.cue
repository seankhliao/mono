Title:    "Webtoons"
Subtitle: "weekly drip feed of entertainment"

PageTitle: "webtoons"
Description: """
	Things I read to psas the time.
	Or spend money on because I'm impulsive and impatient.
	"""

Tables: [{
	Heading:     "Originals"
	Description: "Webtoon originals"
	LinkFormat:  "https://www.webtoons.com/en/-/-/list?title_no=%d"
	Rows: [for row in _originals {
		Rating: row[0]
		ID:     row[1]
		Title: [row[2]]
	}]
}, {
	Heading:     "Originals completed"
	Description: "Webtoon originals that I've read to completed"
	LinkFormat:  "https://www.webtoons.com/en/-/-/list?title_no=%d"
	Rows: [for row in _complete {
		Rating: row[0]
		ID:     row[1]
		Title: [row[2]]
	}]
}, {
	Heading:     "Originals dropped"
	Description: "Webtoon originals that I dropped for whatever reason"
	LinkFormat:  "https://www.webtoons.com/en/-/-/list?title_no=%d"
	Rows: [for row in _incomplete {
		Rating: row[0]
		ID:     row[1]
		Title: [row[2]]
	}]
}, {
	Heading:     "Canvas"
	Description: "Webtoon canvas"
	LinkFormat:  "https://www.webtoons.com/en/canvas/-/list?title_no=%d"
	Rows: [for row in _canvas {
		Rating: row[0]
		ID:     row[1]
		Title: [row[2]]
	}]
}]

_originals: [
	[10, 2745, "Hero Killer"],
	[10, 6054, "The Price Is Your Everything"],
	[10, 2009, "Your Throne"],
	[9, 5815, "Cry, or Better Yet, Beg"],
	[8, 8384, "Ctrl+Alt+Resign"],
	[8, 6821, "Even When I’m Dead"],
	[8, 7124, "The Count's Secret Maid"],
	[8, 4464, "The Dark Lord's Confession"],
	[8, 6465, "The Extra’s Academy Survival Guide"],
	[8, 95, "Tower of God"],
	[7, 6752, "Behind Her Highness’s Smile"],
	[7, 5813, "Cleric of Decay"],
	[7, 3414, "Clinic of Horrors"],
	[7, 5111, "Retired Demon King"],
	[7, 7567, "The Archmage’s Restaurant"],
	[7, 6531, "The Demon King's Warrior Daughter"],
	[7, 6751, "Trapped in a Soap Opera"],
	[7, 8198, "Villainess Streamer"],
	[6, 4286, "+99 Reinforced Wooden Stick"],
	[6, 5845, "Secretly More Powerful than the Hero"],
	[6, 6080, "Stalker x Stalker"],
	[6, 5515, "Surviving the Game as a Barbarian"],
	[6, 6400, "Winter Before Spring"],
	[6, 7846, "Ugly Duckling Complex"],
]

_complete: [
	[9, 3198, "God, Please Make Me a Demon!"],
	[8, 6745, "Our Night Shift"],
	[8, 5811, "Ten Ways to Get Dumped by a Tyrant"],
	[8, 5478, "The Crown Princess Scandal"],
	[8, 2467, "There's Love Hidden in Lies"],
	[8, 4209, "Twilight Poem"],
	[8, 1262, "Unholy Blood"],
	[7, 6912, "Amelia the Level Zero Hero"],
	[7, 2674, "His Majesty's Proposal"],
	[7, 4469, "Monster Duke's Daughter"],
	[7, 961, "My Dear Cold-Blooded King"],
	[7, 5839, "The Age of Arrogance"],
	[7, 4678, "The Duke's Cursed Charm"],
	[7, 6692, "The New Hire is the Demon Lord"],
	[7, 2448, "The Newlywed Diary of a Witch and a Dragon"],
	[7, 6476, "To Whom It No Longer Concerns"],
	[7, 1093, "Winter Moon"],
	[6, 6017, "Bunny Girl and the Cult"],
	[6, 1598, "Everywhere & Nowhere"],
	[6, 1467, "Freaking Romance"],
	[6, 1438, "Mage & Demon Queen"],
	[6, 5517, "The Dragon King’s Bride"],
	[6, 3591, "Wished You Were Dead"],
]

_incomplete: [
	[8, 6146, "Adopted by a Murderous Duke Family"],
	[8, 5896, "Obsidian Bride"],
	[8, 5419, "That Which Flows By"],
	[8, 5730, "The Fateful Invitation"],
	[7, 7122, "At Your Mercy"],
	[7, 5835, "Cross My Heart and Hope to Die"],
	[7, 4687, "Dragon Savior"],
	[7, 7490, "Don't Worry, Dear NPC!"],
	[7, 6528, "I Didn’t Sign Up to be a Nanny!"],
	[7, 5954, "I Will Live the Life of a Villainess"],
	[7, 2606, "My Gently Raised Beast"],
	[7, 6406, "My Lord was Already Into Me When I Noticed"],
	[7, 6530, "My Virtual God is a Teenage Girl"],
	[7, 6677, "One Husband Is Enough"],
	[7, 6416, "Peace Restaurant"],
	[7, 6545, "Stealing Her Place"],
	[7, 6993, "The Flower That Swallowed the Beast"],
	[7, 2966, "The Princess's Jewels"],
	[7, 6315, "The Reason for the Twin Lady’s Disguise"],
	[7, 5201, "The Tyrant Wants to Be Good"],
	[7, 6879, "The Villainess Just Wants to Live in Peace!"],
	[7, 7456, "What Death Taught Me"],
	[7, 5844, "What the Evil Dragon Lives For"],
	[7, 6741, "When the Mad Emperor Holds Me"],
	[7, 6748, "You Can’t Kill Me: The Secret Bride of the Black Wolf"],
	[6, 7121, "A Savage Proposal"],
	[6, 5268, "Heartbeat Conquest"],
	[6, 6880, "I Became a Level 999 Demon Queen"],
	[6, 7411, "Lock Me Up, Duke!"],
	[6, 2725, "Maid for Hire"],
	[6, 6534, "Monster Princess of the Snowy Mountain"],
	[6, 7178, "My Aggravating Sovereign"],
	[6, 6537, "The Cup of Vengeance Is in Your Hands"],
	[6, 1892, "The Witch and The Bull"],
	[6, 6991, "To Die or To Fall In Love"],
	[6, 6282, "Wrong Quest"],
]

_canvas: [
	[8, 506168, "Leave Me Alone, I Don't Want a Romantic Comedy"],
	[7, 551177, "Apollonia"],
	[7, 812729, "Beyond Blood"],
	[7, 693372, "Crow Time"],
	[7, 960877, "How I Failed To Save The World"],
	[7, 696410, "How To Be A Dragon"],
	[7, 716273, "Kill Me, Please"],
	[7, 250209, "Lucid"],
	[7, 304446, "Meme Girls"],
	[7, 902138, "My Emo Crush!"],
	[7, 1045990, "Sally Sinclair"],
	[7, 774402, "The Villainess Wants to Live"],
	[7, 989997, "The World's Strongest Guild Receptionist"],
	[6, 552816, "A City Called Nowhere"],
	[6, 216341, "Conspiracy Research Club"],
	[6, 141539, "Crawling Dreams"],
	[6, 764411, "Goth Girl & The Jock"],
	[6, 219164, "Internet Explorer"],
	[6, 821693, "Justice x Heresy"],
	[6, 764794, "Mines & Monster Girls"],
	[6, 327163, "One Million Gold"],
	[6, 847872, "Sell Me Your Organs!"],
	[6, 881734, "Stella of Shadow"],
	[6, 788689, "THE PRINCE’S PRIVATE SERVANT"],
	[6, 682718, "The Witch Princess"],
]
