output: #Currency

#Currency: {
	// name of the current currency
	currency: string

	// classes of money
	assets: [...string]
	debts: [...string]
	incomes: [...string]
	expenses: [...string]

	// record of transactions
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
