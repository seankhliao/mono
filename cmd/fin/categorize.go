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
		[]string{"lululemon", "ryohin keikaku", "h&m", "dusk.com"},
	},
	{
		"ENT",
		[]string{
			"ticketmaster", "axslonvenuegbpecomm", "adyen n.v.", "dice.fm",
			"www.wegottickets.com",
		},
	},
	{
		"FIN",
		[]string{"gic funds"},
	},
	{
		"FOD",
		[]string{
			"mcdonald", "ole and steen", "co-op", "seoul plaza", "kissaten",
			"watchhouse", "china town", "shoryu ramen", "ls minamoto", "kiss the hippo coffee",
			"wa cafe", "kaffeine", "japan h.l.", "notes coffee", "arcade food hall",
			"omotesando koffee", "katsute", "five guys", "hotel chocolat", "marks&spencer",
			"tesco stores", "asda store", "dixy chicken", "m&s simply food", "be-oom",
			"workshop coffee", "loon fung supermkt", "xing long men", "apan centre",
			"see woo",
		},
	},
	{
		"HSC",
		[]string{"hsbc bnk vsa"},
	},
	{
		"HLT",
		[]string{"boots"},
	},
	{
		"HOS",
		[]string{"chesterton global f17 36", "r.b.k.c", "thames water"},
	},
	{
		"INV",
		[]string{"investengine"},
	},
	{
		"PER",
		[]string{"ebay"},
	},
	{
		"SAL",
		[]string{"snyk ltd", "circle uk trading"},
	},
	{
		"TEC",
		[]string{
			"my o2 bill payment", "o2 balanceweb", "amznmktplace", "aliexpress", "h3g dd",
			"gsuite", "o2 online", "amazon",
		},
	},
	{
		"TOC",
		[]string{"trading 212", "trading twoonetwo"},
	},
	{
		"TRA",
		[]string{"amex tls", "airlines", "airways", "radisson blu", "stansted express"},
	},
	{
		"TRP",
		[]string{"tfl travel ch"},
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
