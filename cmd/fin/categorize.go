package main

import "strings"

var categories = []struct {
	name  string
	match []string
}{
	{
		"AMX",
		[]string{"american exp"},
	},
	{
		"BAR",
		[]string{"b/card rewards", "barclaycard"},
	},
	{
		"CSE",
		[]string{"kuan-hsuan liao chase", "sean chase chase"},
	},
	{
		"CLT",
		[]string{
			"clothing_stores",
			"lululemon", "ryohin keikaku", "h&m", "dusk.com",
		},
	},
	{
		"ENT",
		[]string{
			"entertainment",
			"ticketmaster", "axslonvenuegbpecomm", "adyen n.v.", "dice.fm",
			"www.wegottickets.com", "tcktweb", "tickets", "inflight services",
			"fotografiska",
		},
	},
	{
		"FIN",
		[]string{"gic funds"},
	},
	{
		"FOD",
		[]string{
			"restaurants", "retail_stores",
			"mcdonald", "ole and steen", "co-op", "seoul plaza", "kissaten",
			"watchhouse", "china town", "shoryu ramen", "ls minamoto", "kiss the hippo",
			"wa cafe", "kaffeine", "japan h.l.", "notes coffee", "arcade food hall",
			"omotesando koffee", "katsute", "five guys", "hotel chocolat", "marks&spencer",
			"tesco stores", "asda store", "dixy chicken", "m&s simply food", "be-oom",
			"workshop coffee", "loon fung supermkt", "xing long men", "apan centre",
			"see woo", "pret a manger", "bakery", "winebar", "starbucks", "UNICOOP",
			"costa coffee", "burger king", "cafe", "kryp in", "humlegardsgatan",
			"kafe", "stiftelsen", "supermarket",
			"roda huset", "7eleven", "kaffe", "familymart",
			"lower stable", "wh smith",
		},
	},
	{
		"HSC",
		[]string{"hsbc bnk vsa", "hsbc credit card"},
	},
	{
		"HLT",
		[]string{"boots"},
	},
	{
		"HOS",
		[]string{
			"chesterton global f17 36", "chestertons rent", "r.b.k.c", "thames water", "e.on next",
			"ikea",
		},
	},
	{
		"INV",
		[]string{"investengine"},
	},
	{
		"PER",
		[]string{
			"government_services",
			"ebay", "london graphic centre",
		},
	},
	{
		"SAL",
		[]string{"snyk ltd", "circle uk trading"},
	},
	{
		"TEC",
		[]string{
			"my o2 bill payment", "o2 balanceweb", "amznmktplace", "aliexpress", "h3g dd",
			"gsuite", "o2 online", "amazon", "hutchison 3g",
		},
	},
	{
		"TOC",
		[]string{"trading 212", "trading twoonetwo"},
	},
	{
		"TRA",
		[]string{
			"hotels", "automobile",
			"amex tls", "airlines", "airways", "radisson blu", "stansted express",
			"autolinee", "editerraneo grand hot", "trenitalia", "fiumicino aeroporto",
		},
	},
	{
		"TRP",
		[]string{
			"transport",
			"tfl travel ch",
		},
	},
	{
		"YON",
		[]string{"yonder-autopayonly"},
	},
}

func categorize(s string) string {
	s = strings.ToLower(s)
	for _, category := range categories {
		for _, m := range category.match {
			if strings.Contains(s, m) {
				return category.name
			}
		}
	}
	return "_"
}
