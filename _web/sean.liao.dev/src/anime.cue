package Table

import "time"

Title:    "anime"
Subtitle: "binge watch record"

PageTitle: "anime"
Description: """
	> If I were to utter those words and realize I was in fact lying...
	> The thought of it scares me.
	>
	> — _Hoshino Ai_, Oshi no Ko, Season 1 Episode 1

	Boredom strikes,
	and I aim to binge watch an entire series per day.
	"""

LinkFormat: "https://myanimelist.net/anime/%d"
Table: [for row in _data {
	Date:   time.Parse(time.RFC3339Date, row[0])
	Rating: row[1]
	ID:     row[2]
	Title:  row[3]
	if len(row) > 4 {
		Note: row[4]
	}
}]

_data: [
	["2024-09-11", 7, 54837, ["Akuyaku Reijou Level 99: Watashi wa Ura-Boss desu ga Maou dewa Arimasen", "Villainess Level 99: I May Be the Hidden Boss but I'm Not the Demon Lord"]],
	["2024-05-13", 10, 47917, ["Bocchi the Rock!", "Bocchi the Rock!"], "**Bocchi** is relatable"],
	["2024-06-20", 8, 44511, ["Chainsaw Man", "Chainsaw Man"], "**Makima** dominates, **Power** is playfully wild"],
	["2024-09-27", 8, 52701, ["Dungeon Meshi", "Delicious in Dungeon"]],
	["2024-05-27", 6, 52081, ["Edomae Elf", "Otaku Elf"]],
	["2024-10-08", 6, 51212, ["Futoku no Guild", "Immoral Guild"]],
	["2024-12-24", 8, 54968, ["Giji Harem", "Pseudo Harem"]],
	["2025-05-22", 7, 52481, ["Gimai Seikatsu", "Days with My Stepsister"]],
	["2024-08-13", 8, 55102, ["Girls Band Cry", "Girls Band Cry"]],
	["2024-08-26", 7, 17729, ["Grisaia no Kajitsu", "The Fruit of Grisaia"]],
	["2024-05-27", 5, 51265, ["Inu ni Nattara Suki na Hito ni Hirowareta", "My Life as Inukai-san's Dog"]],
	["2024-05-27", 5, 54225, ["Inu ni Nattara Suki na Hito ni Hirowareta Special", "My Life as Inukai-sanâs Dog. OVA"]],
	["2025-01-19", 7, 44524, ["Isekai Meikyuu de Harem wo", "Isekai Meikyuu de Harem wo"]],
	["2024-10-05", 6, 51219, ["Isekai One Turn Kill Neesan: Ane Douhan no Isekai Seikatsu Hajimemashita", "My One-Hit Kill Sister"]],
	["2024-05-16", 9, 37999, ["Kaguya-sama wa Kokurasetai: Tensai-tachi no Renai Zunousen", "Kaguya-sama: Love is War"], "**Fujiwara Chika** is chaotic good"],
	["2024-05-17", 9, 40591, ["Kaguya-sama wa Kokurasetai? Tensai-tachi no Renai Zunousen", "Kaguya-sama: Love is War Season 2"]],
	["2024-05-18", 9, 43609, ["Kaguya-sama wa Kokurasetai? Tensai-tachi no Renai Zunousen OVA", "Kaguya-sama: Love is War OVA"]],
	["2024-05-18", 8, 43608, ["Kaguya-sama wa Kokurasetai: Ultra Romantic", "Kaguya-sama: Love is War - Ultra Romantic"]],
	["2024-05-18", 8, 52198, ["Kaguya-sama wa Kokurasetai: First Kiss wa Owaranai", "Kaguya-sama: Love is War - The First Kiss That Never Ends"]],
	["2024-05-11", 8, 40221, ["Kami no Tou", "Tower of God"]],
	["2024-12-11", 7, 52635, ["Kami no Tou: Ouji no Kikan", "Tower of God Season 2: Return of the Prince"]],
	["2024-07-22", 7, 5042, ["Kiss x Sis (OVA)", "Kiss x Sis"]],
	["2024-09-02", 6, 7593, ["Kiss x Sis (TV)", "Kiss x Sis"]],
	["2024-05-31", 7, 14713, ["Kamisama Hajimemashita", "Kamisama Kiss"]],
	["2024-06-06", 7, 18661, ["Kamisama Hajimemashita OVA", "Kamisama Kiss OVA"]],
	["2024-06-04", 7, 25681, ["Kamisama Hajimemashita◎", "Kamisama Kiss Season 2"]],
	["2024-06-05", 7, 30709, ["Kamisama Hajimemashita: Kako-hen", "Kamisama Hajimemashita: Kako-hen"]],
	["2024-06-04", 7, 33323, ["Kamisama Hajimemashita: Kamisama, Shiawase ni Naru", "Kamisama Hajimemashita: Kamisama, Shiawase ni Naru"]],
	["2024-09-28", 7, 51213, ["Kinsou no Vermeil: Gakeppuchi Majutsushi wa Saikyou no Yakusai to Mahou Sekai wo Tsukisusumu", "Vermeil in Gold"]],
	["2025-01-10", 7, 50796, ["Kimi wa Houkago Insomnia", "Insomniacs After School"]],
	["2024-12-23", 7, 55996, ["Koi wa Futago de Warikirenai", "Love Is Indivisible by Twins"]],
	["2024-07-14", 8, 30831, ["Kono Subarashii Sekai ni Shukufuku wo!", "KonoSuba: God's Blessing on This Wonderful World!"]],
	["2024-07-14", 8, 32380, ["Kono Subarashii Sekai ni Shukufuku wo!: Kono Subarashii Choker ni Shukufuku wo!", "KonoSuba: God's Blessing on This Wonderful World! - God's Blessing on This Wonderful Choker!"]],
	["2024-06-25", 8, 51958, ["Kono Subarashii Sekai ni Bakuen wo!", "KonoSuba: An Explosion on This Wonderful World!"]],
	["2024-07-16", 8, 32937, ["Kono Subarashii Sekai ni Shukufuku wo! 2", "KonoSuba: God's Blessing on This Wonderful World! 2"]],
	["2024-07-16", 8, 34626, ["Kono Subarashii Sekai ni Shukufuku wo! 2: Kono Subarashii Geijutsu ni Shukufuku wo!", "KonoSuba: God's Blessing on This Wonderful World! 2 - God's Blessing on This Wonderful Art!"]],
	["2024-07-19", 8, 38040, ["Kono Subarashii Sekai ni Shukufuku wo! Movie: Kurenai Densetsu", "KonoSuba: God's Blessing on This Wonderful World! - Legend of Crimson"]],
	["2024-07-27", 8, 49458, ["Kono Subarashii Sekai ni Shukufuku wo! 3", "KonoSuba: God's Blessing on This Wonderful World! 3"]],
	["2024-05-19", 9, 54492, ["Kusuriya no Hitorigoto", "The Apothecary Diaries"], "Maomao feels... down to earth"],
	["2025-02-06", 9, 58125, ["Look Back", "Look Back"]],
	["2024-08-14", 8, 56352, ["Loop 7-kaime no Akuyaku Reijou wa, Moto Tekikoku de Jiyuu Kimama na Hanayome Seikatsu wo Mankitsu suru", "7th Time Loop: The Villainess Enjoys a Carefree Life Married to Her Worst Enemy!"]],
	["2024-05-20", 7, 50380, ["Paripi Koumei", "Ya Boy Kongming!"]],
	["2024-08-21", 7, 54722, ["Mahou Shoujo ni Akogarete", "Gushing over Magical Girls"], "Utena Hiiragi / Magia Baiser has a lovable twisted side"],
	["2024-06-29", 8, 40571, ["Majo no Tabitabi", "Wandering Witch: The Journey of Elaina"], "**Elaina** is confidently cute"],
	["2024-12-19", 8, 57524, ["Make Heroine ga Oosugiru!", "Makeine: Too Many Losing Heroines!"]],
	["2025-03-27", 7, 49470, ["Mamahaha no Tsurego ga Motokano datta", "My Stepmom's Daughter Is My Ex"]],
	["2024-10-28", 7, 52973, ["Megami no Café Terrace", "The Café Terrace and Its Goddesses"]],
	["2024-06-21", 8, 39535, ["Mushoku Tensei: Isekai Ittara Honki Dasu", "Mushoku Tensei: Jobless Reincarnation"], "**Roxy** is cute (and surrounded by creeps), **Eris** is wild in a cute way"],
	["2024-06-22", 8, 45576, ["Mushoku Tensei: Isekai Ittara Honki Dasu Part 2", "Mushoku Tensei: Jobless Reincarnation Part 2"]],
	["2024-06-22", 8, 50360, ["Mushoku Tensei: Isekai Ittara Honki Dasu - Eris no Goblin Toubatsu", "Mushoku Tensei: Jobless Reincarnation - Eris the Goblin Slayer"]],
	["2024-06-28", 7, 51179, ["Mushoku Tensei II: Isekai Ittara Honki Dasu", "Mushoku Tensei: Jobless Reincarnation Season 2"]],
	["2024-07-05", 7, 55888, ["Mushoku Tensei II: Isekai Ittara Honki Dasu Part 2", "Mushoku Tensei: Jobless Reincarnation Season 2 Part 2"]],
	["2025-05-02", 7, 58082, ["NEET Kunoichi to Nazeka Dousei Hajimemashita", "I'm Living with an Otaku NEET Kunoichi!?"]],
	["2024-05-03", 8, 51105, ["NieR:Automata Ver1.1a", "NieR:Automata Ver1.1a"]],
	["2024-11-21", 8, 56063, ["NieR:Automata Ver1.1a (Cour 2)", "NieR:Automata Ver1.1a Part 2"]],
	["2024-06-03", 8, 19815, ["No Game No Life", "No Game, No Life"]],
	["2024-06-03", 8, 24991, ["No Game No Life Specials", "No Game, No Life Specials"]],
	["2024-06-03", 8, 33674, ["No Game No Life: Zero", "No Game, No Life: Zero"]],
	["2024-06-19", 9, 52034, ["Oshi no Ko", "Oshi no Ko"], "**Hoshino Ai** is the embodiment of the perfect lie we want to believe in"],
	["2024-12-23", 8, 55791, ["[Oshi No Ko] Season 2", "Oshi no Ko 2nd Season"]],
	["2024-06-02", 8, 50739, ["Otonari no Tenshi-sama ni Itsunomanika Dame Ningen ni Sareteita Ken", "The Angel Next Door Spoils Me Rotten"]],
	["2024-10-12", 5, 40436, ["Peter Grill to Kenja no Jikan", "Peter Grill and the Philosopher's Time"]],
	["2024-12-11", 5, 50348, ["Peter Grill to Kenja no Jikan: Super Extra", "Peter Grill and the Philosopher's Time: Super Extra"]],
	["2024-04-06", 7, 51403, ["Renai Flops", "Love Flops"]],
	["2025-05-18", 7, 32951, ["Rokudenashi Majutsu Koushi to Akashic Records", "Akashic Records of Bastard Magic Instructor"]],
	["2024-09-09", 7, 48363, ["RPG Fudousan", "RPG Real Estate"]],
	["2024-07-07", 8, 37450, ["Seishun Buta Yarou wa Bunny Girl Senpai no Yume wo Minai", "Rascal Does Not Dream of Bunny Girl Senpai"]],
	["2024-07-08", 8, 38329, ["Seishun Buta Yarou wa Yumemiru Shoujo no Yume wo Minai", "Rascal Does Not Dream of a Dreaming Girl"]],
	["2024-07-10", 7, 53129, ["Seishun Buta Yarou wa Odekake Sister no Yume wo Minai", "Rascal Does Not Dream of a Sister Venturing Out"]],
	["2024-08-26", 8, 53912, ["Seiyuu Radio no Uraomote", "The Many Sides of Voice Actor Radio"]],
	["2024-05-23", 8, 199, ["Sen to Chihiro no Kamikakushi", "Spirited Away"]],
	["2024-06-13", 8, 42351, ["Senpai ga Uzai Kouhai no Hanashi", "My Senpai is Annoying"]],
	["2024-05-27", 8, 18119, ["Servant x Service", "Servant x Service"]],
	["2024-06-07", 7, 38759, ["Sewayaki Kitsune no Senko-san", "The Helpful Fox Senko-san"]],
	["2024-10-09", 7, 58426, ["Shikanoko Nokonoko Koshitantan", "My Deer Friend Nokotan"]],
	["2024-05-07", 10, 52991, ["Sousou no Frieren", "Frieren: Beyond Journey's End"]],
	["2024-05-18", 8, 56885, ["Sousou no Frieren: ●● no Mahou", "Frieren: Beyond Journey's End Mini Anime"]],
	["2024-07-02", 8, 50265, ["Spy x Family", "SPY×FAMILY"]],
	["2024-08-08", 8, 50602, ["Spy x Family Part 2", "SPY×FAMILY"]],
	["2025-02-02", 8, 53887, ["Spy x Family Season 2", "SPY×FAMILY Season 2"]],
	["2024-11-28", 8, 52736, ["Tensei Oujo to Tensai Reijou no Mahou Kakumei", "The Magical Revolution of the Reincarnated Princess and the Genius Young Lady"], "Anis's cheery side is warming"],
	["2025-02-16", 8, 54744, ["Tokidoki Bosotto Russia-go de Dereru Tonari no Alya-san", "Alya Sometimes Hides Her Feelings in Russian"]],
	["2024-06-23", 7, 52305, ["Tomo-chan wa Onnanoko!", "Tomo-chan Is a Girl!"]],
	["2025-04-27", 8, 4224, ["Toradora!", "Toradora!"]],
	["2025-04-27", 7, 11553, ["Toradora!: Bentou no Gokui", "Toradora! Special"]],
	["2025-04-27", 6, 6127, ["Toradora!: SOS! Kuishinbou Banbanzai", "Toradora!: SOS! Hurray for Gourmands"]],
	["2024-06-28", 6, 38573, ["Tsuujou Kougeki ga Zentai Kougeki de Ni-kai Kougeki no Okaasan wa Suki desu ka?", "Do You Love Your Mom and Her Two-Hit Multi-Target Attacks?"]],
	["2024-06-28", 6, 40102, ["Tsuujou Kougeki ga Zentai Kougeki de Ni-kai Kougeki no Okaasan wa Suki desu ka? Namiuchigiwa no Okaasan wa Suki desu ka?", "Do You Love Your Mom and Her Two-Hit Multi-Target Attacks? Do You Love Your Mom on the Shore?"]],
	["2024-12-24", 7, 53379, ["Uchi no Kaisha no Chiisai Senpai no Hanashi", "My Tiny Senpai"]],
	["2025-03-18", 5, 57031, ["Vampire Dormitory", "Vampire Dormitory"]],
	["2024-06-16", 8, 35968, ["Wotaku ni Koi wa Wotaku", "Wotakoi: Love is Hard for Otaku"]],
	["2024-06-05", 8, 35968, ["Wotaku ni Koi wa Muzukashii OVA", "Wotakoi: Love is Hard for Otaku OVA"]],
	["2024-07-06", 9, 54839, ["Yoru no Kurage wa Oyogenai", "Jellyfish Can't Swim in the Night"]],
]
