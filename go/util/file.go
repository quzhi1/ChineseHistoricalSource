package util

import (
	"context"
	"encoding/json"
	"os"

	"github.com/rs/zerolog/log"
)

func ReadFileAndDeserialize(ctx context.Context, fileLoc string) []Document {
	// Read the JSON file into a byte array
	fileBytes, err := os.ReadFile(fileLoc)
	if err != nil {
		panic(err)
	}
	// log.Ctx(ctx).Debug().Str("fileContent", string(fileBytes)).Msg("Read file")

	// Deserialize the JSON into a slice of Document structs
	var documents []Document
	err = json.Unmarshal(fileBytes, &documents)
	if err != nil {
		panic(err)
	}
	return documents
}

func ListFiles(ctx context.Context, dir string) ([]string, error) {
	fileNames := []string{}

	files, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if !file.IsDir() {
			log.Ctx(ctx).Debug().Str("file", file.Name()).Msg("Found file")
			fileNames = append(fileNames, file.Name())
		}
	}

	return fileNames, nil
}
