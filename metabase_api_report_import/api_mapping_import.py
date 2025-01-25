import requests
import json
import logging

# Metabase API credentials and endpoints
SOURCE_API_URL = "https://sagexcel.jobxcel.report/api"
TARGET_API_URL = "https://asg.xcel.report/api"
SOURCE_API_KEY = "mb_blLUnFYZ+diBCC1OY8zBmLXRkKZiRy5f+iFHf1Cj+9E="
TARGET_API_KEY = "mb_/eIVf6avszWL2YkjlUU21gfD2//Ip2iLgzhuVs+g2rI="
SOURCE_DATABASE_ID = 2  # Set the source database ID
TARGET_DATABASE_ID = 2  # Set the target database ID

# List of dashboards to migrate
DASHBOARDS = [4, 5, 6]  # Replace with your actual dashboard IDs

HEADERS_SOURCE = {
    "x-api-key": SOURCE_API_KEY,
    "Content-Type": "application/json"
}

HEADERS_TARGET = {
    "x-api-key": TARGET_API_KEY,
    "Content-Type": "application/json"
}

# Configure logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


def fetch_resource(api_url, endpoint, headers):
    try:
        response = requests.get(f"{api_url}/{endpoint}", headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching resource from {api_url}/{endpoint}: {e}")
        return None


def create_resource(api_url, endpoint, headers, payload):
    try:
        response = requests.post(
            f"{api_url}/{endpoint}", headers=headers, data=json.dumps(payload), timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        logger.error(f"Error creating resource: {e}")
        return None


def get_table_mapping(source_tables, target_tables):
    mapping = {}
    target_table_lookup = {table["name"].lower(): table["id"] for table in target_tables}
    for source_table in source_tables:
        source_table_name = source_table["name"].lower()
        target_id = target_table_lookup.get(source_table_name)
        if target_id:
            mapping[source_table["id"]] = target_id
        else:
            logger.debug(f"Source table '{source_table['name']}' not found in target tables.")
    return mapping


def get_field_mapping(source_fields, target_fields):
    mapping = {}
    target_field_lookup = {field["name"].lower(): field["id"] for field in target_fields}
    for source_field in source_fields:
        source_field_name = source_field["name"].lower()
        target_id = target_field_lookup.get(source_field_name)
        if target_id:
            mapping[source_field["id"]] = target_id
        else:
            logger.debug(f"Source field '{source_field['name']}' not found in target fields.")
    return mapping


def migrate_collections(source_api_url, target_api_url, headers_source, headers_target):
    source_collections = fetch_resource(source_api_url, "collection", headers_source)
    if not source_collections:
        logger.warning("No collections found in the source.")
        return {}

    collection_mapping = {}
    for collection in source_collections:
        created_collection = create_resource(
            target_api_url, "collection", headers_target, {"name": collection["name"]}
        )
        if created_collection:
            collection_mapping[collection["id"]] = created_collection["id"]
            logger.info(f"Collection '{collection['name']}' migrated successfully.")
        else:
            logger.error(f"Failed to migrate collection: {collection['name']}")
    return collection_mapping


def fetch_cards(api_url, dashboard_id, headers):
    dashboard = fetch_resource(api_url, f"dashboard/{dashboard_id}", headers)
    if not dashboard:
        logger.error(f"Dashboard with ID {dashboard_id} not found.")
        return []
    return dashboard.get("dashcards", [])


def migrate_cards(source_api_url, target_api_url, headers_source, headers_target, dashboard_id, table_mapping, field_mapping):
    source_cards = fetch_cards(source_api_url, dashboard_id, headers_source)
    card_mapping = {}

    for card in source_cards:
        updated_card = card.get("card", {})
        if not updated_card:
            logger.warning("Skipping dashcard without a valid card.")
            continue

        dataset_query = updated_card.get("dataset_query", {})
        query = dataset_query.get("query", {})

        # Update table IDs
        if "source-query" in query and "table_id" in query["source-query"]:
            query["source-query"]["table_id"] = table_mapping.get(
                query["source-query"]["table_id"], query["source-query"]["table_id"]
            )

        # Update field IDs
        for agg in query.get("aggregation", []):
            if isinstance(agg, list) and len(agg) > 1 and isinstance(agg[1], dict):
                field_id = agg[1].get("id")
                if field_id:
                    agg[1]["id"] = field_mapping.get(field_id, field_id)

        for breakout in query.get("breakout", []):
            if isinstance(breakout, list) and len(breakout) > 1 and isinstance(breakout[1], dict):
                field_id = breakout[1].get("id")
                if field_id:
                    breakout[1]["id"] = field_mapping.get(field_id, field_id)

        # Create the updated card
        created_card = create_resource(target_api_url, "card", headers_target, updated_card)
        if created_card:
            card_mapping[card["id"]] = created_card["id"]
            logger.info(f"Card '{updated_card.get('name', 'Unnamed')}' migrated successfully.")
        else:
            logger.error(f"Failed to create card: {updated_card.get('name', 'Unnamed')}")

    return card_mapping


def update_dashboard_with_cards(source_dashboard, card_mapping):
    if not source_dashboard:
        logger.error("Source dashboard data is empty.")
        return None

    for dashcard in source_dashboard.get("dashcards", []):
        old_card_id = dashcard.get("card_id")
        if old_card_id in card_mapping:
            dashcard["card_id"] = card_mapping[old_card_id]

    logger.info("Dashboard updated with new card mappings.")
    return source_dashboard


def main():
    logger.info("Starting migration process...")

    # Migrate collections
    migrate_collections(SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET)

    # Fetch and map tables and fields
    source_tables = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/metadata", HEADERS_SOURCE).get("tables", [])
    target_tables = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/metadata", HEADERS_TARGET).get("tables", [])
    table_mapping = get_table_mapping(source_tables, target_tables)

    source_fields = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/fields", HEADERS_SOURCE)
    target_fields = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/fields", HEADERS_TARGET)
    field_mapping = get_field_mapping(source_fields, target_fields)

    # Iterate over dashboards
    for dashboard_id in DASHBOARDS:
        logger.info(f"Processing dashboard ID: {dashboard_id}")

        # Fetch and migrate cards
        card_mapping = migrate_cards(
            SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET, dashboard_id, table_mapping, field_mapping
        )

        # Fetch the source dashboard
        source_dashboard = fetch_resource(SOURCE_API_URL, f"dashboard/{dashboard_id}", HEADERS_SOURCE)
        if not source_dashboard:
            logger.error(f"Failed to fetch dashboard ID {dashboard_id}. Skipping.")
            continue

        # Update dashboard with new cards
        updated_dashboard = update_dashboard_with_cards(source_dashboard, card_mapping)
        if not updated_dashboard:
            logger.error(f"Failed to update dashboard ID {dashboard_id}. Skipping.")
            continue

        # Create the updated dashboard in the target
        create_resource(TARGET_API_URL, "dashboard", HEADERS_TARGET, updated_dashboard)
        logger.info(f"Dashboard ID {dashboard_id} migrated successfully.")

    logger.info("Migration process completed.")


if __name__ == "__main__":
    main()