#!/bin/bash

# Elasticsearch endpoint and index name.
ES_HOST="http://localhost:9200"
INDEX_NAME="articles"

# Drupal JSON API.
DRUPAL_JSON="drupal_articles.json"
DRUPAL_JSON_API="http://localhost:8080/jsonapi/node/article"

# Check if the index exists, and if not, create it with a basic mapping.
if ! curl -s -o /dev/null -w "%{http_code}" "${ES_HOST}/${INDEX_NAME}" | grep -q "200"; then
  echo "Creating index '${INDEX_NAME}'..."
  curl -X PUT "${ES_HOST}/${INDEX_NAME}" -H 'Content-Type: application/json' -d'
  {
    "mappings": {
      "properties": {
        "title": { "type": "text" },
        "body": { "type": "text" },
        "drupal_internal__nid": { "type": "integer" },
        "created": { "type": "date" },
        "tags": { "type": "keyword" }
      }
    }
  }'
  echo
fi

# Download articles from Drupal JSON API and store in a file.
echo "Downloading articles from Drupal JSON API..."
curl -s -o "$DRUPAL_JSON" "$DRUPAL_JSON_API"

# Iterate over each article in the JSON file and index it.
echo "Indexing articles..."
jq -c '.data[]' "$DRUPAL_JSON" | while read -r article; do
  # Extract the Drupal node id (if needed) or use the JSON API id.
  id=$(echo "$article" | jq -r '.id')
  # Build a simplified JSON object for Elasticsearch indexing, e.g., title, body, etc.
  payload=$(echo "$article" | jq '{
    title: .attributes.title,
    body: .attributes.body.value,
    nid: .attributes.drupal_internal__nid,
    created: .attributes.created,
    tags: .relationships.field_tags.data | map(.id)
  }')

  # Index the document.
  curl -s -X PUT "${ES_HOST}/${INDEX_NAME}/_doc/${id}" -H 'Content-Type: application/json' -d "$payload"
  echo "Indexed article $id"
done

echo "Indexing complete."
