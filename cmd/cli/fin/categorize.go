package main

import "strings"

var categories = []struct {
	name     string   // category we use
	match    []string // specific shop names
	category []string // vendor provided category
}{
	{
		"AMX",
		[]string{
			"american exp",
		},
		nil,
	},
	{
		"BAR",
		[]string{
			"b/card rewards", "barclaycard",
		},
		nil,
	},
	{
		"CSC",
		[]string{"to credit card"},
		nil,
	},
	{
		"CSE",
		[]string{
			"kuan-hsuan liao chase", "sean chase chase",
			"me chase current",
		},
		nil,
	},
	{
		"CSS",
		[]string{"chase saver"},
		nil,
	},
	{
		"CLT",
		[]string{
			"lululemon", "ryohin keikaku", "h&m", "dusk.com", "etsy",
			"muji", "uniqlo",
		},
		[]string{
			"clothing_stores",
		},
	},
	{
		"ENT",
		[]string{
			"ticketmaster", "axslonvenuegbpecomm", "adyen n.v.", "dice.fm",
			"www.wegottickets.com", "tcktweb", "tickets", "inflight services",
			"fotografiska", "youtube", "museum", "megacon", "axslon", "breakingsounduk",
			"royal albert hall", "axs", "muzeum",
		},
		[]string{
			"entertainment",
		},
	},
	{
		"FIN",
		[]string{
			"gic funds", "from rewards", "yonder membership",
		},
		nil,
	},
	{
		"FOD",
		[]string{
			"mcdonald", "ole and steen", "co-op", "seoul plaza", "kissaten",
			"watchhouse", "china town", "shoryu ramen", "ls minamoto", "kiss the hippo",
			"wa cafe", "kaffeine", "japan h.l.", "notes coffee", "arcade food hall",
			"omotesando koffee", "katsute", "five guys", "hotel chocolat", "marks&spencer",
			"tesco stores", "asda store", "dixy chicken", "m&s simply food", "be-oom",
			"workshop coffee", "loon fung supermkt", "xing long men", "apan centre",
			"see woo", "pret a manger", "bakery", "winebar", "starbucks", "unicoop",
			"costa coffee", "burger king", "cafe", "kryp in", "humlegardsgatan",
			"kafe", "stiftelsen", "supermarket",
			"roda huset", "7eleven", "kaffe", "familymart",
			"lower stable", "wh smith", "foyles", "seewoo", "loon fung",
			"fresco trattoria pizze", "k food", "kfc", "shibuya soho",
			"chinatown", "pasticceria", "uragano srl", "unico campania", "il gabbiano",
			"la capannina", "bar tabacchi", "molo", "happy lamb hotpot",
			"m&s earls", "covent garden market", "tesco", "costa", "cafe",
			"kuba cabana", "taco stand", "ole & steen", "soderberg", "coffe",
			"the lower third", "eventim", "misato", "o2 academy islington",
			"waitrose", "paul", "marks & spencer", "koffee", "sainsbury",
			"whole foods market", "k. minamoto", "7-eleven",
			"coca-cola",
		},
		[]string{
			"restaurants", "retail_stores",
		},
	},
	{
		"HSC",
		[]string{
			"hsbc bnk vsa", "hsbc credit card",
		},
		nil,
	},
	{
		"HLT",
		[]string{
			"boots", "baroque hair and nails", "pharmacie", "stylevana",
			"Tomod",
		},
		nil,
	},
	{
		"HOS",
		[]string{
			"chesterton uk", "chestertons rent", "r.b.k.c", "thames water", "e.on",
			"ikea",
		},
		nil,
	},
	{
		"INV",
		[]string{
			"investengine",
		},
		nil,
	},
	{
		"PER",
		[]string{
			"ebay", "london graphic centre", "crazycolor.co.uk",
		},
		[]string{
			"government_services",
		},
	},
	{
		"SAL",
		[]string{
			"snyk ltd", "circle uk trading", "navan",
		},
		nil,
	},
	{
		"TEC",
		[]string{
			"my o2 bill payment", "o2 balanceweb", "amznmktplace", "aliexpress", "h3g dd",
			"gsuite", "o2 online", "amazon", "hutchison 3g", "google", "bic camera",
			"framework", "hetzner", "viasat", "sp arace tech", "anker", "three", "o2",
			"spotify", "tailscale",
		},
		nil,
	},
	{
		"TOC",
		[]string{
			"trading 212", "trading twoonetwo",
		},
		nil,
	},
	{
		"TRA",
		[]string{
			"amex tls", "airlines", "airways", "radisson blu", "stansted express",
			"autolinee", "editerraneo grand hot", "trenitalia", "fiumicino aeroporto",
			"sorrento", "ferryhopper", "funicolare", "lbergo excelsior",
			"eav", "smartrip", "shinkansen", "seven bank", "jr west", "uber",
			"vaa mobile app", "uscustoms", "öbb", "booking", "lufthansa",
			"premier inn", "mta nyct paygo", "hilton hotels",
			"marriott", "jakdojade", "hotel", "bolt",
		},
		[]string{
			"hotels", "automobile",
			"transport", "travel",
		},
	},
	{
		"TRP",
		[]string{
			"tfl travel ch", "tfl - transport for london",
		},
		nil,
	},
	{
		"YON",
		[]string{
			"yonder-autopayonly",
		},
		nil,
	},
}

func categorize(desc, category string) string {
	desc, category = strings.ToLower(desc), strings.ToLower(category)
	for _, cat := range categories {
		for _, match := range cat.match {
			if len(match) < 4 {
				if desc == match {
					return cat.name
				}
			} else {
				if strings.Contains(desc, match) {
					return cat.name
				}
			}
		}
	}
	for _, cat := range categories {
		for _, match := range cat.category {
			if strings.Contains(category, match) {
				return cat.name
			}
		}
	}
	return "_"
}
