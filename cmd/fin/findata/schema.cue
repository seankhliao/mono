one: #Currency

#Currency: {
	currency: string
	holdings: [...string]
	incomes: [...string]
	expenses: [...string]
	months: [...#Month]
}

#Month: {
	year:  int & >=1996 & <=2100
	month: int & >=1 & <=12
	transactions: [...#Transaction]
}

#Transaction: {
	src:   string
	dst:   string
	val:   int
	note?: string
}
