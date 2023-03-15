package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"passthru/src/external"
	"strings"
	"time"

	"github.com/opensearch-project/opensearch-go/v2"
	"github.com/opensearch-project/opensearch-go/v2/opensearchapi"
)

func main() {
	os.Setenv("OPENSEARCH_URL", "http://localhost:9200")
	client := getClient()
	createIndex(client)
	insertMessage(client, external.OpenSearchMessageSource{
		MessageID: "test-1",
		ImapUID:   1,
		GrantID:   "nylas_test_imap_user_b",
		Folder:    "INBOX",
		Subject:   "test-1",
		From: []string{
			"user-a@localhost",
		},
		To: []string{
			"user-b@localhost",
		},
		CC: []string{
			"user-c@localhost",
		},
		IsUnread: true,
	})
	insertMessage(client, external.OpenSearchMessageSource{
		MessageID: "test-2",
		ImapUID:   1,
		GrantID:   "nylas_test_imap_user_a",
		Folder:    "INBOX",
		Subject:   "test-2",
		From: []string{
			"user-b@localhost",
		},
		To: []string{
			"user-a@localhost",
		},
		BCC: []string{
			"user-c@localhost",
		},
	})
	insertMessage(client, external.OpenSearchMessageSource{
		MessageID: "test-3",
		ImapUID:   2, //nolint:gomnd // it's an init script
		GrantID:   "nylas_test_imap_user_a",
		Folder:    "SENT",
		Subject:   "test-3",
		From: []string{
			"user-a@localhost",
		},
		To: []string{
			"user-b@localhost",
		},
		IsStarred: true,
	})
	insertMessage(client, external.OpenSearchMessageSource{
		MessageID: "test-4",
		ImapUID:   2, //nolint:gomnd // it's an init script
		GrantID:   "nylas_test_imap_user_b",
		Folder:    "SENT",
		Subject:   "test-4",
		From: []string{
			"user-b@localhost",
		},
		To: []string{
			"user-a@localhost",
		},
	})
	time.Sleep(3 * time.Second)
	searchMessages(client, "test-1")
	searchMessages(client, "test-2")
	searchMessagesByGrantAndSubject(client, "nylas_test_imap_user_a", "test-3")

	updateMessage(client, "test-2")
	time.Sleep(3 * time.Second)
	searchMessages(client, "test-2")
}

const MESSAGES_INDEX = "messages"

func getClient() *opensearch.Client {
	client, err := opensearch.NewClient(opensearch.Config{
		Username: "elastic",
		Password: "admin",
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec // Localhost, no cert
		},
	})
	if err != nil {
		log.Fatalf("Error creating the client: %s", err)
	}

	// Print opensearch status
	res, err := client.Info()
	if err != nil {
		log.Fatalf("Error getting response: %s", err)
	}

	defer res.Body.Close()
	log.Println(res)
	return client
}

func createIndex(client *opensearch.Client) {
	// Define index mapping.
	mapping := strings.NewReader(`{
	    "mappings": {
			"properties": {
				"message_id": {
					"type": "keyword"
				},
				"grant_id": {
					"type": "keyword"
				},
				"imap_uid": {
					"type": "long"
				},
				"imap_uid_validity": {
					"type": "long"
				},
				"folder": {
					"type": "keyword"
				},
				"from": {
					"type": "keyword"
				},
				"to": {
					"type": "keyword"
				},
				"cc": {
					"type": "keyword"
				},
				"bcc": {
					"type": "keyword"
				},
				"subject": {
					"type": "keyword"
				},
				"sent_at": {
					"type": "date"
				},
				"is_unread": {
					"type": "boolean"
				},
				"is_starred": {
					"type": "boolean"
				},
				"attachment_ids": {
					"type": "keyword"
				},
				"updated_at": {
					"type": "date"
				}
			}
	    }
	}`)

	// Create an index with non-default settings.
	messagesIndexRequest := opensearchapi.IndicesCreateRequest{
		Index: MESSAGES_INDEX,
		Body:  mapping,
	}
	createIndexResponse, err := messagesIndexRequest.Do(context.Background(), client)
	if err != nil {
		log.Fatalf("failed to create index %v", err)
	}
	log.Println(createIndexResponse)
}

func insertMessage(client *opensearch.Client, message external.OpenSearchMessageSource) {
	// Add a document to the index.
	document, err := json.Marshal(message)
	if err != nil {
		log.Fatalf("failed to unmarshal document: %v", message)
	}

	documentReader := bytes.NewReader(document)

	req := opensearchapi.IndexRequest{
		Index:      MESSAGES_INDEX,
		DocumentID: message.MessageID,
		Body:       documentReader,
	}
	insertResponse, err := req.Do(context.Background(), client)
	if err != nil {
		log.Fatalf("failed to insert document %v", err)
	}
	log.Println(insertResponse)
}

func searchMessages(client *opensearch.Client, messageID string) {
	content := strings.NewReader(fmt.Sprintf(`{
	    "query": {
	        "match": {
	            "message_id": "%v"
	        }
	    }
	}`, messageID))

	search := opensearchapi.SearchRequest{
		Body: content,
	}

	searchResponse, err := search.Do(context.Background(), client)
	if err != nil {
		log.Fatalf("failed to search document %v", err)
	}
	log.Println(searchResponse)
}

func searchMessagesByGrantAndSubject(client *opensearch.Client, grantID, subject string) {
	query := external.OpenSearchQuery{
		Query: struct {
			Bool struct {
				Must []struct {
					Match external.OpenSearchMatch "json:\"match\""
				} "json:\"must\""
			} "json:\"bool\""
		}{
			Bool: struct {
				Must []struct {
					Match external.OpenSearchMatch "json:\"match\""
				} "json:\"must\""
			}{
				Must: []struct {
					Match external.OpenSearchMatch "json:\"match\""
				}{
					{
						Match: external.OpenSearchMatch{
							GrantID: grantID,
						},
					},
					{
						Match: external.OpenSearchMatch{
							Subject: subject,
						},
					},
				},
			},
		},
	}

	contentBytes, err := json.Marshal(query)
	if err != nil {
		log.Fatalf("failed to marshal query %v", err)
	}

	content := bytes.NewReader(contentBytes)

	search := opensearchapi.SearchRequest{
		Body: content,
	}

	searchResponse, err := search.Do(context.Background(), client)
	if err != nil {
		log.Fatalf("failed to search document %v", err)
	}
	log.Println(searchResponse)
}

func updateMessage(client *opensearch.Client, messageID string) {
	content := strings.NewReader(`{
	    "doc": {
	    }
	}`)

	update := opensearchapi.UpdateRequest{
		Index:      MESSAGES_INDEX,
		DocumentID: messageID,
		Body:       content,
	}

	updateResponse, err := update.Do(context.Background(), client)
	if err != nil {
		log.Fatalf("failed to update document %v", err)
	}

	log.Println(updateResponse)
}
