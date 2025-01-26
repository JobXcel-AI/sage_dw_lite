import json
import requests
import logging
from tabulate import tabulate
from collections import OrderedDict

# Metabase API credentials and endpoints
SOURCE_API_URL = "https://sagexcel.jobxcel.report/api"
TARGET_API_URL = "https://asg.xcel.report/api"
SOURCE_API_KEY = "mb_blLUnFYZ+diBCC1OY8zBmLXRkKZiRy5f+iFHf1Cj+9E="
TARGET_API_KEY = "mb_/eIVf6avszWL2YkjlUU21gfD2//Ip2iLgzhuVs+g2rI="
SOURCE_DATABASE_ID = 2  # Set the source database ID
TARGET_DATABASE_ID = 2  # Set the target database ID

# List of dashboards to migrate
DASHBOARDS = [4]

HEADERS_SOURCE = {
    "x-api-key": SOURCE_API_KEY,
}

HEADERS_TARGET = {
    "x-api-key": TARGET_API_KEY,
}

# Configure logger
logging.basicConfig(level=logging.DEBUG, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

def fetch_resource(api_url, endpoint, headers):
    try:
        response = requests.get(f"{api_url}/{endpoint}", headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching resource from {api_url}/{endpoint}: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        return None

def create_resource(api_url, endpoint, headers, payload):
    try:
        # Ensure Content-Type is set to application/json
        headers["Content-Type"] = "application/json"
        json_payload = json.dumps(payload, indent=4)
        response = requests.post(
            f"{api_url}/{endpoint}", headers=headers, data=json_payload, timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        if e.response is not None:
            logger.error(f"Error creating resource: {e}, Response: {e.response.text}")
        else:
            logger.error(f"Error creating resource: {e}")
        return None

def build_table_field_mapping(tables):
    """
    Build a mapping of table names and field names from the tables data.
    """
    table_mapping = {table["name"].lower(): table["id"] for table in tables}
    field_mapping = {
        field["id"]: {"name": field["name"], "table_id": table["id"]}
        for table in tables
        for field in table.get("fields", [])
    }
    return table_mapping, field_mapping


def log_field_mappings(source_tables, target_tables, field_mapping):
    """
    Log a detailed mapping of source and target tables and fields, ensuring table names and field names are matched.
    """
    mappings = []

    for source_field_id, source_field_data in field_mapping["source"].items():
        source_table_id = source_field_data["table_id"]
        source_field_name = source_field_data["name"]
        source_table_name = next(
            (table["name"] for table in source_tables if table["id"] == source_table_id), "Unknown Table"
        )

        # Find matching target table and field by name
        target_table = next(
            (table for table in target_tables if table["name"].lower() == source_table_name.lower()), None
        )
        if target_table:
            target_table_id = target_table["id"]
            target_field = next(
                (field for field in target_table.get("fields", [])
                 if field["name"].lower() == source_field_name.lower()), None
            )
            if target_field:
                target_field_id = target_field["id"]
                target_table_name = target_table["name"]
                target_field_name = target_field["name"]
                mappings.append([
                    source_table_id, source_table_name, source_field_id, source_field_name,
                    target_table_id, target_table_name, target_field_id, target_field_name
                ])
            else:
                mappings.append([
                    source_table_id, source_table_name, source_field_id, source_field_name,
                    target_table_id, target_table["name"], "N/A", source_field_name
                ])
        else:
            mappings.append([
                source_table_id, source_table_name, source_field_id, source_field_name,
                "N/A", "N/A", "N/A", source_field_name
            ])

    # Log the table
    logger.debug("\n" + tabulate(mappings, headers=[
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

    # Map target collections by name to avoid duplicates
    target_collection_lookup = {collection["name"]: collection["id"] for collection in target_collections}

    collection_mapping = {}
    for source_collection in source_collections:
        source_collection_name = source_collection["name"]

        if source_collection_name in target_collection_lookup:
            # Collection exists, map its ID
            collection_mapping[source_collection["id"]] = target_collection_lookup[source_collection_name]
            logger.info(f"Collection '{source_collection_name}' already exists in the target. Skipping creation.")
        else:
            # Collection does not exist, create it
            created_collection = create_resource(
                target_api_url, "collection", headers_target, {"name": source_collection_name}
            )
            if created_collection:
                collection_mapping[source_collection["id"]] = created_collection["id"]
                logger.info(f"Collection '{source_collection_name}' created successfully.")
            else:
                logger.error(f"Failed to create collection: {source_collection_name}")

    return collection_mapping


def fetch_cards_from_dashboard(api_url, dashboard_id, headers):
    """
    Fetch the list of card IDs from a dashboard.

    :param api_url: The base URL of the API.
    :param dashboard_id: The ID of the dashboard to fetch.
    :param headers: Headers for the API request.
    :return: A list of card IDs in the dashboard.
    """
    dashboard = fetch_resource(api_url, f"dashboard/{dashboard_id}", headers)
    if not dashboard:
        logger.error(f"Dashboard with ID {dashboard_id} not found.")
        return []

    dashcards = dashboard.get("dashcards", [])
    return [dashcard.get("card_id") for dashcard in dashcards if dashcard.get("card_id") is not None]


def migrate_cards(
        source_api_url, target_api_url, headers_source, headers_target,
        dashboard_id, collection_mapping, source_tables, target_tables, source_field_mapping, target_field_mapping
):
    """
    Migrate cards from source to target. Update the database, collection, table, field references, and field ids.
    """
    # Fetch card IDs from the dashboard
    source_card_ids = fetch_cards_from_dashboard(source_api_url, dashboard_id, headers_source)
    source_cards = []
    card_mapping = {}
    # Fetch the card data for each card ID
    for card_id in source_card_ids:
        card_data = fetch_resource(source_api_url, f"card/{card_id}", headers_source)
        if card_data:
            source_cards.append(card_data)
        else:
            logger.warning(f"Card with ID {card_id} not found or could not be retrieved.")

    for source_card in source_cards:
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

        def update_query_recursively(query, is_top_level=True):
            if isinstance(query, dict):
                # Process "source-table"
                if "source-table" in query:
                    source_table_name = next(
                        (table["name"] for table in source_tables if table["id"] == query["source-table"]), None
                    )
                    if source_table_name:
                        query["source-table"] = next(
                            (table["id"] for table in target_tables if table["name"] == source_table_name),
                            query["source-table"]
                        )

                # Process "table_id"
                if "table_id" in query:
                    source_table_name = next(
                        (table["name"] for table in source_tables if table["id"] == query["table_id"]), None
                    )
                    if source_table_name:
                        query["table_id"] = next(
                            (table["id"] for table in target_tables if table["name"] == source_table_name),
                            query["table_id"]
                        )

                # Process "field_ref"
                if "field_ref" in query:
                    query["field_ref"] = update_field_ref(
                        query["field_ref"], source_field_mapping, target_field_mapping
                    )

                # Process "joins"
                if "joins" in query:
                    for join in query["joins"]:
                        if "source-table" in join:
                            source_table_name = next(
                                (table["name"] for table in source_tables if table["id"] == join["source-table"]),
                                None
                            )
                            if source_table_name:
                                join["source-table"] = next(
                                    (table["id"] for table in target_tables if table["name"] == source_table_name),
                                    join["source-table"]
                                )

                # Process "breakout"
                if "breakout" in query:
                    for breakout in query["breakout"]:
                        # Validate that breakout[1] is a list or another updatable structure
                        if isinstance(breakout, list) and len(breakout) > 1 and isinstance(breakout[1], (list, int)):
                            if isinstance(breakout[1], list):
                                breakout[1] = update_field_ref(breakout[1], source_field_mapping, target_field_mapping)
                            else:
                                # Handle cases where breakout[1] is not updatable
                                logger.debug(f"Skipping update for breakout[1]: {breakout[1]} (not a list)")

                # If we are at the top level, process `dataset_query` specifically
                if is_top_level and "dataset_query" in query:
                    query["dataset_query"] = update_query_recursively(query.get("dataset_query", {}), is_top_level=False)
                    return query

                # Process "source-query"
                if "source-query" in query:
                    query["source-query"] = update_query_recursively(query["source-query"], is_top_level=False)

                # Process "query" (specific to dataset_query)
                if "query" in query:
                    query["query"] = update_query_recursively(query["query"], is_top_level=False)

            elif isinstance(query, list):
                for i, item in enumerate(query):
                    query[i] = update_query_recursively(item, is_top_level=False)

            return query


        def update_field_ref(field_ref, source_field_mapping, target_field_mapping):
            if len(field_ref) > 1 and isinstance(field_ref[1], str):
                # Keep the field name as is and avoid converting it to an ID
                return field_ref
            elif len(field_ref) > 1 and isinstance(field_ref[1], int):
                # Only replace the ID if necessary
                source_field_id = field_ref[1]
                source_field_name = source_field_mapping.get(source_field_id, {}).get("name")
                if source_field_name:
                    target_field_id = next(
                        (field_id for field_id, field_data in target_field_mapping.items()
                         if field_data["name"] == source_field_name), None
                    )
                    if target_field_id:
                        field_ref[1] = target_field_id
            return field_ref

        # Begin by updating the top-level source_card
        dataset_query = update_query_recursively(source_card)
        updated_card["dataset_query"] = dataset_query

        # Update table_id in the card metadata
        if "table_id" in updated_card:
            source_table_name = next((table["name"] for table in source_tables if table["id"] == updated_card["table_id"]), None)
            if source_table_name:
                updated_card["table_id"] = next(
                    (table["id"] for table in target_tables if table["name"] == source_table_name),
                    updated_card["table_id"]
                )

        # Update result_metadata field ids and field_ref
        if "result_metadata" in updated_card:
            for metadata in updated_card["result_metadata"]:
                # Update id directly (next to fingerprint)
                if "id" in metadata:
                    source_field_id = metadata["id"]
                    source_field_name = source_field_mapping.get(source_field_id, {}).get("name")
                    if source_field_name:
                        metadata["id"] = next(
                            (field_id for field_id, field_data in target_field_mapping.items()
                             if field_data["name"] == source_field_name),
                            metadata["id"]
                        )

                # Update field_ref
                if "field_ref" in metadata:
                    metadata["field_ref"] = update_field_ref(
                        metadata["field_ref"], source_field_mapping, target_field_mapping
                    )
        updated_card = OrderedDict()
        updated_card["cache_invalidated_at"] = source_card.get("cache_invalidated_at", None)
        updated_card["description"] = source_card.get("description", "") or None
        updated_card["archived"] = source_card.get("archived", False)
        updated_card["view_count"] = source_card.get("view_count", 0)
        updated_card["collection_position"] = source_card.get("collection_position", None)
        updated_card["table_id"] = source_card.get("table_id", None)
        updated_card["can_run_adhoc_query"] = source_card.get("can_run_adhoc_query", True)
        updated_card["result_metadata"] = source_card.get("result_metadata", [])
        updated_card["creator"] = source_card.get("creator", {})
        updated_card["database_id"] = source_card.get("database_id", TARGET_DATABASE_ID)
        updated_card["enable_embedding"] = source_card.get("enable_embedding", False)
        updated_card["collection_id"] = collection_mapping.get(source_card.get("collection_id"), None)
        updated_card["query_type"] = source_card.get("query_type", "query")
        updated_card["name"] = source_card.get("name", "Unnamed")
        updated_card["type"] = source_card.get("type", "question")
        updated_card["dataset_query"] = source_card.get("dataset_query", {})
        updated_card["visualization_settings"] = source_card.get("visualization_settings", {})
        updated_card["last_query_start"] = source_card.get("last_query_start", None)
        updated_card["last_used_at"] = source_card.get("last_used_at", None)
        updated_card["created_at"] = source_card.get("created_at", None)
        updated_card["updated_at"] = source_card.get("updated_at", None)
        updated_card["id"] = source_card.get("id")
        updated_card["initially_published_at"] = source_card.get("initially_published_at", None)
        updated_card["can_write"] = source_card.get("can_write", True)
        updated_card["dashboard_count"] = source_card.get("dashboard_count", 0)
        updated_card["average_query_time"] = source_card.get("average_query_time", None)
        updated_card["creator_id"] = source_card.get("creator_id", None)
        updated_card["moderation_reviews"] = source_card.get("moderation_reviews", [])
        updated_card["made_public_by_id"] = source_card.get("made_public_by_id", None)
        updated_card["embedding_params"] = source_card.get("embedding_params", None)
        updated_card["cache_ttl"] = source_card.get("cache_ttl", None)
        updated_card["parameter_mappings"] = source_card.get("parameter_mappings", [])
        updated_card["display"] = source_card.get("display", "table")
        updated_card["entity_id"] = source_card.get("entity_id", None)
        updated_card["collection_preview"] = source_card.get("collection_preview", False)
        updated_card["last-edit-info"] = source_card.get("last-edit-info", {})
        updated_card["collection"] = source_card.get("collection", {})
        updated_card["metabase_version"] = source_card.get("metabase_version", None)
        updated_card["parameters"] = source_card.get("parameters", [])
        updated_card["parameter_usage_count"] = source_card.get("parameter_usage_count", 0)
        updated_card["public_uuid"] = source_card.get("public_uuid", None)

        json_payload = json.dumps(updated_card, indent=4)
        created_card = create_resource(target_api_url, "card", headers_target, updated_card)
        if created_card:
            card_mapping[source_card["id"]] = created_card["id"]
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

    source_metadata = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/metadata", HEADERS_SOURCE)
    target_metadata = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/metadata", HEADERS_TARGET)

    source_tables = source_metadata.get("tables", [])
    target_tables = target_metadata.get("tables", [])

    source_table_mapping, source_field_mapping = build_table_field_mapping(source_tables)
    target_table_mapping, target_field_mapping = build_table_field_mapping(target_tables)

    field_mapping = {"source": source_field_mapping, "target": target_field_mapping}

    log_field_mappings(source_tables, target_tables, field_mapping)

    for dashboard_id in DASHBOARDS:
        logger.info(f"Processing dashboard ID: {dashboard_id}")
        source_dashboard = fetch_resource(SOURCE_API_URL, f"dashboard/{dashboard_id}", HEADERS_SOURCE)
        if not source_dashboard:
            logger.error(f"Failed to fetch dashboard ID {dashboard_id}. Skipping.")
            continue

        card_mapping = migrate_cards(
            SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET,
            dashboard_id, collection_mapping, source_tables, target_tables, source_field_mapping, target_field_mapping
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