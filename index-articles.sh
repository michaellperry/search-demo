#!/bin/bash

# Elasticsearch endpoint and index name.
ES_HOST="http://localhost:9200"
INDEX_NAME="articles"
TAGS_INDEX_NAME="tags"

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
  # Extract tag IDs as a JSON array.
  tag_ids=$(echo "$article" | jq -c '.relationships.field_tags.data | map(.id)')

  # Fetch tag names from the tags index.
  tag_names=$(echo "$tag_ids" | jq -r '.[]' | while read -r tag_id; do
    response=$(curl -s -X GET "${ES_HOST}/${TAGS_INDEX_NAME}/_doc/${tag_id}")
    name=$(echo "$response" | jq -r '._source.name')
    if [ "$name" != "null" ]; then
      echo "\"$name\""
    fi
  done | jq -cs '.')

  # Ensure tag_names is valid JSON array.
  if [ -z "$tag_names" ]; then
    tag_names="[]"
  fi
  
  # Build a simplified JSON object for Elasticsearch indexing, e.g., title, body, etc.
  payload=$(echo "$article" | jq --argjson tags "$tag_names" '{
    title: .attributes.title,
    body: .attributes.body.value,
    nid: .attributes.drupal_internal__nid,
    created: .attributes.created,
    tags: $tags
  }')
  
  # Index the document.
  curl -s -X PUT "${ES_HOST}/${INDEX_NAME}/_doc/${id}" -H 'Content-Type: application/json' -d "$payload"
  echo "Indexed article $id"
done

echo "Indexing complete."
