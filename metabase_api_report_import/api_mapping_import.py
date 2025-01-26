import requests
import json
import logging
from tabulate import tabulate  # For displaying the mappings as a table

# Metabase API credentials and endpoints
SOURCE_API_URL = "https://sagexcel.jobxcel.report/api"
TARGET_API_URL = "https://asg.xcel.report/api"
SOURCE_API_KEY = "mb_blLUnFYZ+diBCC1OY8zBmLXRkKZiRy5f+iFHf1Cj+9E="
TARGET_API_KEY = "mb_/eIVf6avszWL2YkjlUU21gfD2//Ip2iLgzhuVs+g2rI="
SOURCE_DATABASE_ID = 2  # Set the source database ID
TARGET_DATABASE_ID = 2  # Set the target database ID

# List of dashboards to migrate
DASHBOARDS = [4]  # Replace with your actual dashboard IDs

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


def build_table_field_mapping(tables):
    """
    Build a mapping of table names and field names from the tables data.
    """
    table_mapping = {table["name"].lower(): table["id"] for table in tables}
    field_mapping = {
        field["name"].lower(): (field["id"], table["id"])
        for table in tables
        for field in table.get("fields", [])
    }
    return table_mapping, field_mapping


def log_field_mappings(source_tables, target_tables, field_mapping):
    """
    Log a detailed mapping of source and target tables and fields, ensuring table names are correctly resolved.
    """
    mappings = []
    for source_field_name, (source_field_id, source_table_id) in field_mapping["source"].items():
        source_table_name = next(
            (table["name"] for table in source_tables if table["id"] == source_table_id), "Unknown Table"
        )
        if source_field_name in field_mapping["target"]:
            target_field_id, target_table_id = field_mapping["target"][source_field_name]
            target_table_name = next(
                (table["name"] for table in target_tables if table["id"] == target_table_id), "Unknown Table"
            )
            mappings.append([
                source_table_id, source_table_name, source_field_id, source_field_name,
                target_table_id, target_table_name, target_field_id, source_field_name
            ])
        else:
            mappings.append([source_table_id, source_table_name, source_field_id, source_field_name, "N/A", "N/A", "N/A", source_field_name])

    # Log the table
    logger.info("\n" + tabulate(mappings, headers=[
        "Source Table ID", "Source Table Name", "Source Field ID", "Source Field Name",
        "Target Table ID", "Target Table Name", "Target Field ID", "Target Field Name"
    ], tablefmt="grid"))


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
    """
    Migrate collections from source to target. Check if a collection already exists in the target before creating it.
    """
    source_collections = fetch_resource(source_api_url, "collection", headers_source)
    target_collections = fetch_resource(target_api_url, "collection", headers_target)

    if not source_collections:
        logger.warning("No collections found in the source.")
        return {}

    if not target_collections:
        logger.warning("No collections found in the target.")
        target_collections = []

    target_collection_lookup = {collection["name"]: collection["id"] for collection in target_collections}

    collection_mapping = {}
    for source_collection in source_collections:
        source_collection_name = source_collection["name"]

        if source_collection_name in target_collection_lookup:
            collection_mapping[source_collection["id"]] = target_collection_lookup[source_collection_name]
            logger.info(f"Collection '{source_collection_name}' already exists in the target. Skipping creation.")
        else:
            created_collection = create_resource(
                target_api_url, "collection", headers_target, {"name": source_collection_name}
            )
            if created_collection:
                collection_mapping[source_collection["id"]] = created_collection["id"]
                logger.info(f"Collection '{source_collection_name}' created successfully.")
            else:
                logger.error(f"Failed to create collection: {source_collection_name}")

    return collection_mapping


def fetch_cards(api_url, dashboard_id, headers):
    dashboard = fetch_resource(api_url, f"dashboard/{dashboard_id}", headers)
    if not dashboard:
        logger.error(f"Dashboard with ID {dashboard_id} not found.")
        return []
    return dashboard.get("dashcards", [])


def migrate_cards(
        source_api_url, target_api_url, headers_source, headers_target, dashboard_id,
        table_mapping, field_mapping, collection_mapping, source_tables, target_tables
):
    """
    Migrate cards from source to target. Update the database, collection, table, field references, and fk_target_field_id.
    """
    source_cards = fetch_cards(source_api_url, dashboard_id, headers_source)
    card_mapping = {}

    for card in source_cards:
        source_card = card.get("card", {})
        if not source_card:
            logger.warning("Skipping dashcard without a valid card.")
            continue

        # Transform the source card JSON
        updated_card = source_card.copy()

        # Update database ID
        if SOURCE_DATABASE_ID != TARGET_DATABASE_ID:
            updated_card["database_id"] = TARGET_DATABASE_ID

        # Update collection ID
        source_collection_id = source_card.get("collection_id")
        if source_collection_id and source_collection_id in collection_mapping:
            updated_card["collection_id"] = collection_mapping[source_collection_id]

        # Update dataset_query
        dataset_query = source_card.get("dataset_query", {})
        if dataset_query:
            if "database" in dataset_query:
                dataset_query["database"] = TARGET_DATABASE_ID

            # Function to recursively update nested queries
            def update_query(query):
                if not isinstance(query, dict):
                    return query

                # Update source-table and table_id
                if "source-table" in query:
                    source_table_id = query["source-table"]
                    query["source-table"] = table_mapping.get(source_table_id, source_table_id)

                if "table_id" in query:
                    source_table_id = query["table_id"]
                    query["table_id"] = table_mapping.get(source_table_id, source_table_id)

                # Update joins in the query
                if "joins" in query:
                    for join in query["joins"]:
                        if "source-table" in join:
                            source_table_id = join["source-table"]
                            join["source-table"] = table_mapping.get(source_table_id, source_table_id)

                # Update fk_target_field_id in aggregations
                if "aggregation" in query:
                    for agg in query["aggregation"]:
                        if isinstance(agg, list) and len(agg) > 1 and isinstance(agg[1], dict):
                            if "fk_target_field_id" in agg[1]:
                                source_field_id = agg[1]["fk_target_field_id"]
                                if source_field_id in field_mapping["source"]:
                                    target_field_id = field_mapping["target"].get(source_field_id)
                                    agg[1]["fk_target_field_id"] = target_field_id

                # Update fk_target_field_id in breakout fields
                if "breakout" in query:
                    for breakout in query["breakout"]:
                        if isinstance(breakout, list) and len(breakout) > 1 and isinstance(breakout[1], dict):
                            if "fk_target_field_id" in breakout[1]:
                                source_field_id = breakout[1]["fk_target_field_id"]
                                if source_field_id in field_mapping["source"]:
                                    target_field_id = field_mapping["target"].get(source_field_id)
                                    breakout[1]["fk_target_field_id"] = target_field_id

                # Update nested source-query
                if "source-query" in query:
                    query["source-query"] = update_query(query["source-query"])

                return query

            # Apply updates to the top-level query
            dataset_query["query"] = update_query(dataset_query.get("query", {}))

        updated_card["dataset_query"] = dataset_query

        # Update table_id in the card metadata
        if "table_id" in updated_card:
            source_table_id = updated_card["table_id"]
            updated_card["table_id"] = table_mapping.get(source_table_id, source_table_id)

        # Update metadata fields such as fk_target_field_id in result_metadata
        if "result_metadata" in updated_card:
            for metadata in updated_card["result_metadata"]:
                if "fk_target_field_id" in metadata and metadata["fk_target_field_id"] is not None:
                    source_field_id = metadata["fk_target_field_id"]
                    if source_field_id in field_mapping["source"]:
                        target_field_id = field_mapping["target"].get(source_field_id)
                        metadata["fk_target_field_id"] = target_field_id

        # Create the updated card in the target
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
    collection_mapping = migrate_collections(SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET)

    # Fetch and map tables and fields
    source_tables = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/metadata", HEADERS_SOURCE).get("tables", [])
    target_tables = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/metadata", HEADERS_TARGET).get("tables", [])

    # Build table and field mappings
    source_table_mapping, source_field_mapping = build_table_field_mapping(source_tables)
    target_table_mapping, target_field_mapping = build_table_field_mapping(target_tables)

    field_mapping = {
        "source": source_field_mapping,
        "target": target_field_mapping
    }

    # Log the mappings
    log_field_mappings(source_tables, target_tables, field_mapping)

    # Collections migration
    collection_mapping = migrate_collections(SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET)

    # Iterate over dashboards
    for dashboard_id in DASHBOARDS:
        logger.info(f"Processing dashboard ID: {dashboard_id}")
        source_dashboard = fetch_resource(SOURCE_API_URL, f"dashboard/{dashboard_id}", HEADERS_SOURCE)
        if not source_dashboard:
            logger.error(f"Failed to fetch dashboard ID {dashboard_id}. Skipping.")
            continue

        # Fetch and migrate cards
        card_mapping = migrate_cards(
            SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET,
            dashboard_id, source_table_mapping, field_mapping, collection_mapping,
            source_tables, target_table_mapping
        )

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