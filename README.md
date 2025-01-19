# Search Demo

The objective is to demonstrate the capabilities of Elasticsearch for searching articles and products.

## Running the Demo

To run the demo, you must have Docker installed. This has been tested on Windows using WSL2. It is known to have issues on Apple Silicon.

You must also have `jq` installed. Use the following command to install it on Ubuntu:

```bash
sudo apt install jq
```

## Running the Demo

Use Docker Compose to create the containers:

```bash
cd content-search
docker compose pull
docker compose up
```

Then you can open [Drupal](http://localhost:8080/) and set up the Umami Food Magazine demo site. Enter the following settings for the MySQL database:

- Database name: `drupal`
- Database username: `drupal`
- Database password: `drupal`
- Host (under Advanced Options): `db`

After the site is created, you will be prompted to configure the site. Enter the following settings:

- Site name: `Umami Food Magazine`
- Site email: `umami@improving.com`
- Site maintenance account username: `admin`
- Site maintenance account password: `admin`
- Check for updates automatically: `unchecked`

Enable the JSON:API module. Go to Admin > Extend, search for JSON:API, select the module, and click the Install button.

## Indexing Content

The content is now available via the following URLs:

- [Articles](http://localhost:8080/en/jsonapi/node/article)
- [Recipes](http://localhost:8080/en/jsonapi/node/recipe)

You can import the articles into Elasticsearch using the `index-articles.sh` script.

## Searching Content

Run a few searches against the Elasticsearch index using the following curl commands.

First, search for articles with the word "herbs" in the title:

```bash
curl -X GET 'http://localhost:9200/articles/_search?pretty' \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match": { "title": "herbs" } }
  }'
```

Next, find articles with the word "orange" in the body:

```bash
curl -X GET 'http://localhost:9200/articles/_search?pretty' \
  -H 'Content-Type: application/json' \
  -d '{
    "query": { "match": { "body": "orange" } }
  }'
```
