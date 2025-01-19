#!/bin/bash

# Elasticsearch URL
ES_URL="http://localhost:9200"

# Index name
INDEX_NAME="products"

# Create the index with mappings
curl -X PUT "$ES_URL/$INDEX_NAME" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "id": { "type": "keyword" },
      "name": { "type": "text" },
      "description": { "type": "text" },
      "image_url": { "type": "keyword" },
      "kind": { "type": "keyword" },
      "category": { "type": "keyword" }
    }
  }
}'

# Read products from JSON file and index them
jq -c '.products[]' ./products.json | while read -r product; do
  curl -X POST "$ES_URL/$INDEX_NAME/_doc/" -H 'Content-Type: application/json' -d"$product"
done

echo "Indexing completed."