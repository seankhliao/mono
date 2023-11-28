package midnight

import "github.com/alecthomas/chroma/v2"

func Style() (*chroma.Style, error) {
	b := chroma.NewStyleBuilder("midnight")
	b.Add(chroma.Background, "#080c10")
	// b.Add(chroma.LineHighlight, "")
	// b.Add(chroma.Error, "")
	b.Add(chroma.Keyword, "#a665d0")
	// b.Add(chroma.KeywordType, )
	b.Add(chroma.Name, "#9ac6e0")
	b.Add(chroma.NameAttribute, "#7ac098")
	b.Add(chroma.NameFunction, "#c8b670")
	b.Add(chroma.Literal, "#5080ff")
	b.Add(chroma.LiteralString, "#e0a076")
	b.Add(chroma.LiteralNumber, "#5080ff")
	b.Add(chroma.Operator, "#ff7279")
	b.Add(chroma.Comment, "#878d96")
	// b.Add(chroma.Generic, "")
	b.Add(chroma.Text, "#b5bdc5")
	// b.Add(chroma.Punctuation, )
	return b.Build()
}
