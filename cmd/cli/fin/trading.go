package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"

	"go.seankhliao.com/mono/ycli"
)

type stock struct {
	isin, ticker, name string
	currency           string
	shares, total      float64
}

func TradingCommand() ycli.Command {
	var filename string
	return ycli.New(
		"trading",

		"calculate trading gain/loss",

		func(fs *flag.FlagSet) {
			fs.StringVar(&filename, "file", "trading.csv", "path to trading212 history file")
		},

		func(stdout, stderr io.Writer) error {
			file, err := os.Open(filename)
			if err != nil {
				return fmt.Errorf("open file: %w", err)
			}
			cr := csv.NewReader(file)
			_, err = cr.Read()
			if err != nil {
				return fmt.Errorf("read headers: %w", err)
			}

			results := make(map[string]float64)

			var gbp2usd, gbp2gbx float64

			stocks := make(map[string]stock)
			profits := make(map[profitKey]float64)

			transactions, err := cr.ReadAll()
			if err != nil {
				return fmt.Errorf("read transactions: %w", err)
			}
			for _, tr := range transactions {
				// row := transactionRow{tr[0], tr[1], tr[2], tr[3], tr[4], tr[5], tr[6], tr[7], tr[8], tr[9], tr[10], tr[11], tr[12], tr[13], tr[14], tr[15], tr[16], tr[17], tr[18], tr[19], tr[20]}
				row := transactionRow{tr[0], tr[1], tr[2], tr[3], tr[4], tr[5], tr[6], tr[7], tr[8], tr[9], tr[10], tr[11], tr[12], tr[13], tr[14], tr[15]}
				_, _, _, _ = row.ID, row.Total, row.Currency_conversion_fee, row.Currency_Currency_conversion_fee
				if !strings.HasSuffix(row.Action, "buy") && !strings.HasSuffix(row.Action, "sell") {
					continue
				}

				st, ok := stocks[row.Ticker]
				if !ok {
					st.isin, st.ticker, st.name = row.ISIN, row.Ticker, row.Name
					st.currency = row.Currency_Price___share
				}

				exchange, err := strconv.ParseFloat(row.Exchange_rate, 64)
				if err != nil {
					return fmt.Errorf("parse exchange rate: %w", err)
				}
				date, err := time.Parse(time.DateTime, row.Time)
				if err != nil {
					return fmt.Errorf("parse time: %w", err)
				}
				shares, err := strconv.ParseFloat(row.No__of_shares, 64)
				if err != nil {
					return fmt.Errorf("parse shares as float: %w", err)
				}
				total, err := strconv.ParseFloat(row.Price___share, 64)
				if err != nil {
					return fmt.Errorf("parse total as float: %w", err)
				}
				total = shares * total

				var result float64
				if row.Result != "" {
					result, err = strconv.ParseFloat(row.Result, 64)
					if err != nil {
						return fmt.Errorf("parse result: %w", err)
					}
					results[row.Currency_Result] += result
				}

				if row.Currency_Price___share == "USD" && row.Currency_Total == "GBP" {
					gbp2usd = exchange
				} else if row.Currency_Price___share == "GBX" && row.Currency_Total == "GBP" {
					gbp2gbx = exchange
				}

				if strings.HasSuffix(row.Action, "buy") {
					st.shares += shares
					st.total += total

					if st.ticker == "NVDA" {
						fmt.Println(shares, total, st.shares, st.total)
					}

				} else if strings.HasSuffix(row.Action, "sell") {
					avgBuyPPS := st.total / st.shares

					st.shares -= shares
					cost := shares * avgBuyPPS
					st.total -= cost

					profit := total - cost
					profits[profitKey{date.Year(), st.currency}] += profit

					profitGBP := profit
					if st.currency == "USD" {
						profitGBP /= gbp2usd
					} else if st.currency == "GBX" {
						profitGBP /= gbp2gbx
					}
					resGBP := result
					switch row.Currency_Result {
					case "USD":
						resGBP /= gbp2usd
					case "GBX":
						resGBP /= gbp2gbx
					}

					fmt.Printf("%f\t%f\t%f\t%s\t%s\t%s\t%s\n", profitGBP, resGBP, profit, st.currency, date.Format(time.DateOnly), st.ticker, st.name)
				}

				stocks[st.ticker] = st
				if st.total < 0.01 {
					if st.shares < 0 {
						fmt.Println("err", st)
					}
					delete(stocks, st.ticker)
				}
			}

			fmt.Println()
			for key, val := range stocks {
				fmt.Println(key, val)
			}

			fmt.Println()
			fmt.Println(gbp2gbx)
			fmt.Println(gbp2usd)

			fmt.Println()
			for curr, res := range results {
				resGBP := res
				if curr == "USD" {
					resGBP /= gbp2usd
				} else if curr == "GBX" {
					resGBP /= gbp2gbx
				}
				fmt.Println(curr, res, resGBP)
			}

			fmt.Println()
			for key, profit := range profits {
				profitGBP := profit
				if key.curr == "USD" {
					profitGBP = profitGBP / gbp2usd
				} else if key.curr == "GBX" {
					profitGBP = profitGBP / gbp2gbx
				}
				fmt.Println(key.year, key.curr, profit, profitGBP)
			}

			return nil
		},
	)
}

type profitKey struct {
	year int
	curr string
}

type transactionRow struct {
	Action string
	Time   string
	ISIN   string
	Ticker string
	Name   string
	// Notes                            string
	ID                     string
	No__of_shares          string
	Price___share          string
	Currency_Price___share string
	Exchange_rate          string
	Result                 string
	Currency_Result        string
	Total                  string
	Currency_Total         string
	// Withholding_tax                  string
	// Currency_Withholding_tax         string
	Currency_conversion_fee          string
	Currency_Currency_conversion_fee string
	// Merchant_name                    string
	// Merchant_category                string
}
