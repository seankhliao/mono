package midnight

import "github.com/alecthomas/chroma/v2"

func Style() (*chroma.Style, error) {
	return chroma.NewStyleBuilder("midnight").
		AddEntry(chroma.Background, chroma.StyleEntry{
			Colour:     chroma.ParseColour("#eceff1"),
			Background: chroma.ParseColour("#303030"),
		}).
		AddEntry(chroma.Keyword, chroma.StyleEntry{
			Colour: chroma.ParseColour("#a665d0"),
		}).
		AddEntry(chroma.Name, chroma.StyleEntry{
			Colour: chroma.ParseColour("#9ac6e0"),
		}).
		AddEntry(chroma.NameAttribute, chroma.StyleEntry{
			Colour: chroma.ParseColour("#7ac098"),
		}).
		AddEntry(chroma.NameFunction, chroma.StyleEntry{
			Colour: chroma.ParseColour("#c8b670"),
		}).
		AddEntry(chroma.Literal, chroma.StyleEntry{
			Colour: chroma.ParseColour("#5080ff"),
		}).
		AddEntry(chroma.LiteralString, chroma.StyleEntry{
			Colour: chroma.ParseColour("#e0a076"),
		}).
		AddEntry(chroma.LiteralNumber, chroma.StyleEntry{
			Colour: chroma.ParseColour("#5080ff"),
		}).
		AddEntry(chroma.Operator, chroma.StyleEntry{
			Colour: chroma.ParseColour("#ff7279"),
		}).
		AddEntry(chroma.Comment, chroma.StyleEntry{
			Colour: chroma.ParseColour("#878d96"),
		}).
		AddEntry(chroma.Text, chroma.StyleEntry{
			Colour: chroma.ParseColour("#b5bdc5"),
		}).
		Build()
}
