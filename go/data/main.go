package main

import (
	"github.com/rs/zerolog/log"

	"github.com/quzhi1/chinese-historical-source/go/util"
)

func main() {
	ctx := util.GetLoggerCtx()
	client := util.GetClient("admin", "admin")
	files, err := util.ListFiles(ctx, "json")
	if err != nil {
		panic(err)
	}
	for _, file := range files {
		documents := util.ReadFileAndDeserialize(ctx, "json/"+file)
		log.Ctx(ctx).Debug().Msgf("Insert %d documents from file %s", len(documents), file)
		for _, document := range documents {
			// log.Ctx(ctx).Debug().Msgf("Insert document: %v", document)
			err = util.InsertMessage(ctx, client, document)
			if err != nil {
				panic(err)
			}
		}
	}
}
