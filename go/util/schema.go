package util

type Document struct {
	Source      string `json:"source"`
	Chapter     string `json:"chapter"`
	Text        string `json:"text"`
	ChapterURL  string `json:"chapter_url"`
	Translation string `json:"translation"`
}
