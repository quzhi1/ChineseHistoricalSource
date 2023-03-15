package main

import (
	"crypto/tls"
	"io"
	"net/http"
	"os"

	"github.com/rs/zerolog/log"

	opensearch "github.com/opensearch-project/opensearch-go/v2"
)

func main() {
	NewClient()
}

func NewClient() *opensearch.Client {
	os.Setenv("OPENSEARCH_URL", "http://localhost:9200")
	client, err := opensearch.NewClient(opensearch.Config{
		Username: "elastic",
		Password: "admin",
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec // Localhost, no cert
		},
	})
	if err != nil {
		log.Fatal().Err(err).Msg("Error creating the client")
	}

	// Print opensearch status
	res, err := client.Info()
	if err != nil {
		log.Fatal().Err(err).Msg("Error getting response")
	}

	defer res.Body.Close()

	// Read status body
	body, err := io.ReadAll(res.Body)
	if err != nil {
		log.Fatal().Err(err).Msg("Error loading opensearch body")
	}

	log.Info().Str("statusResponse", string(body)).Msg("Got status response")

	return client
}
