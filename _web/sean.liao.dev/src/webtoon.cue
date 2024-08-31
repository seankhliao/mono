Title:    "Webtoons"
Subtitle: "weekly drip feed of entertainment"

PageTitle: "webtoons"
Description: """
	Things I read to psas the time.
	Or spend money on because I'm impulsive and impatient.
	"""

LinkFormat: "https://www.webtoons.com/en/-/-/list?title_no=%d"
Table: [for row in _data {
	Rating: row[0]
	ID:     row[1]
	Title: [row[2]]
}]

_data: [
	// rating, webtoon title number, name
	[10, 2745, "Hero Killer"],
	[10, 5811, "Ten Ways to Get Dumped by a Tyrant"],
	[10, 6054, "The Price Is Your Everything"],
	[10, 2009, "Your Throne"],
	[8, 6146, "Adopted by a Murderous Duke Family"],
	[8, 5835, "Cross My Heart and Hope to Die"],
	[8, 5815, "Cry, or Better Yet, Beg"],
	[8, 3198, "God, Please Make Me a Demon!"],
	[8, 506168, "Leave Me Alone, I Don't Want a Romantic Comedy"],
	[8, 6406, "My Lord was AlreadyInto Me When I Noticed"],
	[8, 5896, "Obsidian Bride"],
	[8, 5419, "That Which Flows By"],
	[8, 5478, "The Crown Princess Scandal"],
	[8, 4464, "The Dark Lord's Confession"],
	[8, 5730, "The Fateful Invitation"],
	[8, 2467, "There's Love Hidden in Lies"],
	[8, 95, "Tower of God"],
	[8, 4209, "Twilight Poem"],
	[8, 1262, "Unholy Blood"],
	[7, 812729, "Beyond Blood"],
	[7, 3414, "Clinic of Horrors"],
	[7, 693372, "Crow Time"],
	[7, 696410, "How To Be A Dragon"],
	[7, 5954, "I Will Live the Life of a Villainess"],
	[7, 250209, "Lucid"],
	[7, 304446, "Meme Girls"],
	[7, 4469, "Monster Duke's Daughter"],
	[7, 961, "My Dear Cold-Blooded King"],
	[7, 902138, "My Emo Crush!"],
	[7, 6416, "Peace Restaurant"],
	[7, 5839, "The Age of Arrogance"],
	[7, 6531, "The Demon King's Warrior Daughter"],
	[7, 5517, "The Dragon King’s Bride"],
	[7, 2448, "The Newlywed Diary of a Witch and a Dragon"],
	[7, 2966, "The Princess's Jewels"],
	[7, 6315, "The Reason for the Twin Lady’s Disguise"],
	[7, 5201, "The Tyrant Wants to Be Good"],
	[7, 5844, "What the Evil Dragon Lives For"],
	[7, 1093, "Winter Moon"],
	[6, 4286, "+99 Reinforced Wooden Stick"],
	[6, 552816, "A City Called Nowhere"],
	[6, 6017, "Bunny Girl and the Cult"],
	[6, 216341, "Conspiracy Research Club"],
	[6, 141539, "Crawling Dreams"],
	[6, 1598, "Everywhere & Nowhere"],
	[6, 1467, "Freaking Romance"],
	[6, 764411, "Goth Girl & The Jock"],
	[6, 5268, "Heartbeat Conquest"],
	[6, 219164, "Internet Explorer"],
	[6, 821693, "Justice x Heresy"],
	[6, 1438, "Mage & Demon Queen"],
	[6, 2725, "Maid for Hire"],
	[6, 764794, "Mines & Monster Girls"],
	[6, 327163, "One Million Gold"],
	[6, 5845, "Secretly More Powerful than the Hero"],
	[6, 847872, "Sell Me Your Organs!"],
	[6, 6080, "Stalker x Stalker"],
	[6, 881734, "Stella of Shadow"],
	[6, 5515, "Surviving the Game as a Barbarian"],
	[6, 788689, "THE PRINCE’S PRIVATE SERVANT"],
	[6, 1892, "The Witch and The Bull"],
	[6, 682718, "The Witch Princess"],
	[6, 6400, "Winter Before Spring"],
	[6, 3591, "Wished You Were Dead"],
	[6, 6282, "Wrong Quest"],
]