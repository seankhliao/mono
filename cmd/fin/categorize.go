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
		"CSE",
		[]string{
			"kuan-hsuan liao chase", "sean chase chase",
		},
		nil,
	},
	{
		"CLT",
		[]string{
			"lululemon", "ryohin keikaku", "h&m", "dusk.com",
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
			"fotografiska", "youtube", "museum",
		},
		[]string{
			"entertainment",
		},
	},
	{
		"FIN",
		[]string{
			"gic funds",
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
			"la capannina", "bar tabacchi", "Molo",
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
			"boots", "baroque hair and nails", "pharmacie",
		},
		nil,
	},
	{
		"HOS",
		[]string{
			"chesterton global f17 36", "chestertons rent", "r.b.k.c", "thames water", "e.on",
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
			"ebay", "london graphic centre",
		},
		[]string{
			"government_services",
		},
	},
	{
		"SAL",
		[]string{
			"snyk ltd", "circle uk trading",
		},
		nil,
	},
	{
		"TEC",
		[]string{
			"my o2 bill payment", "o2 balanceweb", "amznmktplace", "aliexpress", "h3g dd",
			"gsuite", "o2 online", "amazon", "hutchison 3g", "google",
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
			"transport",
			"amex tls", "airlines", "airways", "radisson blu", "stansted express",
			"autolinee", "editerraneo grand hot", "trenitalia", "fiumicino aeroporto",
			"sorrento", "ferryhopper", "travel", "funicolare", "lbergo excelsior",
			"eav", "smartrip", "shinkansen", "seven bank",
		},
		[]string{
			"hotels", "automobile",
		},
	},
	{
		"TRP",
		[]string{
			"tfl travel ch",
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
