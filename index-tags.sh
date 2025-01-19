#!/bin/bash

# Elasticsearch endpoint and index name.
ES_HOST="http://localhost:9200"
INDEX_NAME="tags"

# Drupal JSON API.
DRUPAL_JSON="drupal_tags.json"
DRUPAL_JSON_API="http://localhost:8080/en/jsonapi/taxonomy_term/tags"

# Check if the index exists, and if not, create it with a basic mapping.
if ! curl -s -o /dev/null -w "%{http_code}" "${ES_HOST}/${INDEX_NAME}" | grep -q "200"; then
  echo "Creating index '${INDEX_NAME}'..."
  curl -X PUT "${ES_HOST}/${INDEX_NAME}" -H 'Content-Type: application/json' -d'
  {
    "mappings": {
      "properties": {
        "name": { "type": "keyword" },
        "id": { "type": "keyword" }
      }
    }
  }'
  echo
fi

# Download tags from Drupal JSON API and store in a file.
echo "Downloading tags from Drupal JSON API..."
curl -s -o "$DRUPAL_JSON" "$DRUPAL_JSON_API"

# Iterate over each tag in the JSON file and index it.
echo "Indexing tags..."
jq -c '.data[]' "$DRUPAL_JSON" | while read -r tag; do
  # Extract the tag id and name.
  tag_id=$(echo "$tag" | jq -r '.id')
  name=$(echo "$tag" | jq -r '.attributes.name')
  # Build a JSON payload with tag id and name.
  payload=$(jq -n --arg id "$tag_id" --arg name "$name" '{ id: $id, name: $name }')
  
  # Index the tag document in Elasticsearch.
  curl -s -X PUT "${ES_HOST}/${INDEX_NAME}/_doc/${tag_id}" -H 'Content-Type: application/json' -d "$payload"
  echo "Indexed tag ${tag_id}"
done

echo "Tag indexing complete."
