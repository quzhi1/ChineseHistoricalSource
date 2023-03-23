package util

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/rs/zerolog/log"

	"github.com/opensearch-project/opensearch-go"
	"github.com/opensearch-project/opensearch-go/opensearchapi"
)

func GetClient(username, password string) *opensearch.Client {
	osClient, err := opensearch.NewClient(opensearch.Config{
		Addresses: []string{"https://localhost:9200"},
		Username:  username,
		Password:  password,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec // Localhost, no cert
		},
	})
	if err != nil {
		log.Fatal().Msgf("Error creating the client: %s", err)
	}

	return osClient
}

func InsertMessage(ctx context.Context, client *opensearch.Client, document Document) error {
	contentBytes, err := json.Marshal(document)
	if err != nil {
		return fmt.Errorf("failed to marshal insert query: %w", err)
	}
	// log.Ctx(ctx).Debug().Str("document", string(contentBytes)).Msg("Insert document")

	insertRequest := opensearchapi.IndexRequest{
		Index: "history_source",
		Body:  bytes.NewReader(contentBytes),
	}

	createResponse, err := insertRequest.Do(ctx, client)
	if err != nil {
		return fmt.Errorf("failed to insert document %w", err)
	}

	responseBody, err := readResponse(createResponse)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}
	// log.Ctx(ctx).Debug().Str("responseBody", responseBody).Msg("Insert response")

	if createResponse.StatusCode != http.StatusOK && createResponse.StatusCode != http.StatusCreated {
		return fmt.Errorf(
			"opensearch insert response status code was %d not 200, responseBody: %s",
			createResponse.StatusCode,
			responseBody,
		)
	}
	return nil
}

func readResponse(response *opensearchapi.Response) (string, error) {
	buf := new(strings.Builder)
	_, err := io.Copy(buf, response.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response body: %w", err)
	}

	return buf.String(), nil
}
