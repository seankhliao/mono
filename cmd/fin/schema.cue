output: #Currency

#Currency: {
	// name of the current currency
	currency: string

	groupings: [...#Group]

	// record of transactions
	months: [...#Month]
}

#Group: {
	// name of group
	name: string
	// names of accounts
	names: [...string]
	// flip for income
	invert: bool | *false
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
