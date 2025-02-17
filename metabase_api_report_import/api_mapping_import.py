import os
import json
import requests
import logging
from tabulate import tabulate
from collections import OrderedDict

# Metabase API credentials and endpoints
SOURCE_API_URL = "https://castle.jobxcel.report/api"
TARGET_API_URL = "https://sagexcel.jobxcel.report/api"
SOURCE_API_KEY = "mb_vsr+JXyizthuSTeWiVzf5BZu1lXc1gS5hUsExbEsvyI="
TARGET_API_KEY = "mb_blLUnFYZ+diBCC1OY8zBmLXRkKZiRy5f+iFHf1Cj+9E=" # Set the target to SageXcel Demo
SOURCE_DATABASE_ID = 2 # Set the source database ID
TARGET_DATABASE_ID = 2  # Set the target database ID
COLLECTION_ID = 9

# List of dashboards to migrate
DASHBOARDS = [4]
CARDS = []

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
        field["id"]: {"name": field["name"], "table_id": table["id"], "table_name": table["name"].lower()}
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



def update_joins(joins, source_table_mapping, target_table_mapping, source_field_mapping, target_field_mapping):
    """
    Update the joins array to map source field IDs to target field IDs and source-table IDs to target-table IDs.
    """
    # Reverse the source table mapping for lookup by table ID
    reversed_source_table_mapping = {v: k for k, v in source_table_mapping.items()}

    for join in joins:
        # Update "source-table"
        if "source-table" in join:
            source_table_id = join["source-table"]
            logger.debug(f"Original source-table ID: {source_table_id}")

            # Ensure `source_table_id` is an integer
            if not isinstance(source_table_id, int):
                logger.error(f"Invalid source-table ID: {source_table_id}")
                continue

            # Get source table name using the reversed mapping
            source_table_name = reversed_source_table_mapping.get(source_table_id)
            logger.debug(f"Source table name: {source_table_name}")

            if source_table_name:
                # Get target table ID using source table name
                target_table_id = target_table_mapping.get(source_table_name.lower())
                logger.debug(f"Target table ID: {target_table_id}")

                if target_table_id:
                    join["source-table"] = target_table_id
                else:
                    logger.warning(f"Target table ID not found for source table name: {source_table_name}")
            else:
                logger.warning(f"Source table name not found for source-table ID: {source_table_id}")

        # Update "condition"
        if "condition" in join:
            join["condition"] = update_condition(join["condition"], source_field_mapping, target_field_mapping)

def update_condition(condition, source_field_mapping, target_field_mapping):
    """
    Updates field references within a condition array.
    """
    if isinstance(condition, list):
        for i, item in enumerate(condition):
            if isinstance(item, list) and len(item) > 1:
                # Check if this is a field reference
                if item[0] == "field" and isinstance(item[1], int):  # If the second item is a field ID
                    source_field_id = item[1]
                    source_field_name = source_field_mapping.get(source_field_id, {}).get("name")
                    if source_field_name:
                        target_field_id = next(
                            (field_id for field_id, field_data in target_field_mapping.items()
                             if field_data["name"] == source_field_name),
                            source_field_id  # Default to the original ID if no match
                        )
                        condition[i][1] = target_field_id  # Replace with target field ID
                elif isinstance(item, list):  # Recurse into nested conditions
                    condition[i] = update_condition(item, source_field_mapping, target_field_mapping)

    return condition

def map_field_id(source_field_id, source_field_mapping, target_field_mapping):
    """
    Map a source field ID to a target field ID using source and target field mappings.

    :param source_field_id: The source field ID to map.
    :param source_field_mapping: Dictionary of source field mappings.
    :param target_field_mapping: Dictionary of target field mappings.
    :return: Mapped target field ID or the original source field ID if no match is found.
    """
    source_field_name = source_field_mapping.get(source_field_id, {}).get("name")
    source_table_name = source_field_mapping.get(source_field_id, {}).get("table_name")

    if source_field_name and source_table_name:
        # Map source field and table names to target field ID
        target_field_id = next(
            (
                field_id for field_id, field_data in target_field_mapping.items()
                if field_data["name"] == source_field_name and
                   field_data.get("table_name", "").lower() == source_table_name.lower()
            ),
            source_field_id  # Default to original if no match
        )
        return target_field_id
    else:
        # Log a warning if the source field name or table name is missing
        logger.warning(f"Field or table name missing for source field ID {source_field_id}.")
        return source_field_id

def update_aggregation_options(aggregation_options, source_field_mapping, target_field_mapping):
    """
    Update field references within aggregation-options, including "default" fields.
    """
    if isinstance(aggregation_options, list):
        for i, option in enumerate(aggregation_options):
            if isinstance(option, list):
                # Recursively handle nested structures
                update_aggregation_options(option, source_field_mapping, target_field_mapping)
            elif option == "field" and i + 1 < len(aggregation_options):
                # Map the field ID
                if isinstance(aggregation_options[i + 1], int):
                    source_field_id = aggregation_options[i + 1]
                    aggregation_options[i + 1] = map_field_id(source_field_id, source_field_mapping, target_field_mapping)
            elif isinstance(option, dict) and "default" in option:
                # Handle "default" field
                default_value = option["default"]
                if isinstance(default_value, list) and default_value[0] == "field" and isinstance(default_value[1], int):
                    source_field_id = default_value[1]
                    option["default"][1] = map_field_id(source_field_id, source_field_mapping, target_field_mapping)

def update_aggregations(aggregations, source_field_mapping, target_field_mapping):
    """
    Update field references within the aggregations array, including in aggregation-options.
    """
    for aggregation in aggregations:
        if isinstance(aggregation, list):
            for i, item in enumerate(aggregation):
                if isinstance(item, list):
                    # Handle nested structures or aggregation-options
                    update_aggregations([item], source_field_mapping, target_field_mapping)
                elif item == "field" and i + 1 < len(aggregation):
                    # Map the field ID
                    if isinstance(aggregation[i + 1], int):
                        source_field_id = aggregation[i + 1]
                        aggregation[i + 1] = map_field_id(source_field_id, source_field_mapping, target_field_mapping)
                elif isinstance(item, dict) and "default" in item:
                    # Handle "default" field in aggregation-options
                    update_aggregation_options([item], source_field_mapping, target_field_mapping)

def update_field_ref(field_ref, source_field_mapping, target_field_mapping):
    if isinstance(field_ref, list):
        if len(field_ref) > 1 and isinstance(field_ref[1], int):
            # Look up the source field name using the field ID
            field_ref[1]  = map_field_id(field_ref[1], source_field_mapping, target_field_mapping)
    elif isinstance(field_ref, int):
        # Handle cases where field_ref is a simple integer (field ID)
        field_ref = map_field_id(field_ref, source_field_mapping, target_field_mapping)
    return field_ref

def update_expressions(expressions, source_field_mapping, target_field_mapping):
    """
    Update field references within expressions.
    """
    if isinstance(expressions, dict):
        for key, expression in expressions.items():
            expressions[key] = update_expression_fields(expression, source_field_mapping, target_field_mapping)
    return expressions

def update_expression_fields(expression, source_field_mapping, target_field_mapping):
    """
    Recursively update field IDs within an expression.
    """
    if isinstance(expression, list):
        for i, item in enumerate(expression):
            if isinstance(item, list) and len(item) > 1:
                if item[0] == "field" and isinstance(item[1], int):  # If it's a field ID
                    source_field_id = item[1]
                    target_field_id = map_field_id(source_field_id, source_field_mapping, target_field_mapping)
                    expression[i][1] = target_field_id  # Replace with target field ID
                else:  # Recurse into nested structures
                    expression[i] = update_expression_fields(item, source_field_mapping, target_field_mapping)
    return expression

def update_query_recursively(query, source_field_mapping, target_field_mapping, source_tables, target_tables,
                             source_table_mapping, target_table_mapping, is_top_level=True,):
    if isinstance(query, dict):

        if "aggregation" in query:
            update_aggregations(query["aggregation"], source_field_mapping, target_field_mapping)

        # Process "database" field inside dataset_query
        if "database" in query:
            if query["database"] == SOURCE_DATABASE_ID:
                logger.debug(f"Updating dataset_query database ID from {query['database']} to {TARGET_DATABASE_ID}")
                query["database"] = TARGET_DATABASE_ID

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
            update_joins(query["joins"], source_table_mapping, target_table_mapping, source_field_mapping,
                         target_field_mapping)

        # Process "breakout"
        if "breakout" in query:
            for breakout in query["breakout"]:
                if isinstance(breakout, list) and len(breakout) > 1:
                    if isinstance(breakout[1], int):  # Process field ID in breakout
                        breakout[1] = map_field_id(breakout[1], source_field_mapping, target_field_mapping)
                    elif isinstance(breakout[1], list):  # Handle nested field refs
                        breakout[1] = update_field_ref(breakout[1], source_field_mapping, target_field_mapping)

        # Process "condition"
        if "condition" in query:
            query["condition"] = update_condition(query["condition"], source_field_mapping, target_field_mapping)

        # Process "expressions" (NEW ADDITION)
        if "expressions" in query:
            query["expressions"] = update_expressions(query["expressions"], source_field_mapping, target_field_mapping)

        # Process "aggregation"
        if "aggregation" in query:
            for aggregation in query["aggregation"]:
                if isinstance(aggregation, list) and len(aggregation) > 1:
                    aggregation[1] = update_field_ref(aggregation[1], source_field_mapping, target_field_mapping)

        # If we are at the top level, process `dataset_query` specifically
        if is_top_level and "dataset_query" in query:
            query["dataset_query"] = update_query_recursively(query.get("dataset_query", {}), source_field_mapping,
                                                                target_field_mapping, source_tables, target_tables,
                                                              source_table_mapping, target_table_mapping,
                                                              is_top_level=False)
            return query

        # Process "source-query"
        if "source-query" in query:
            query["source-query"] = update_query_recursively(query["source-query"], source_field_mapping,
                                                             target_field_mapping, source_tables, target_tables,
                                                             source_table_mapping, target_table_mapping,
                                                             is_top_level=False)

        # Process "query" (specific to dataset_query)
        if "query" in query:
            query["query"] = update_query_recursively(query["query"],source_field_mapping,
                                                      target_field_mapping, source_tables, target_tables,
                                                      source_table_mapping, target_table_mapping,
                                                      is_top_level=False)

    elif isinstance(query, list):
        for i, item in enumerate(query):
            query[i] = update_query_recursively(item, source_field_mapping,
                                                target_field_mapping, source_tables, target_tables,
                                                source_table_mapping, target_table_mapping,
                                                is_top_level=False)

    return query


def migrate_cards(
        source_api_url, target_api_url, headers_source, headers_target,
        dashboard_id, source_tables, target_tables, source_field_mapping, target_field_mapping,
        source_table_mapping, target_table_mapping
):
    """
    Migrate cards from source to target. Update the database, collection, table, field references, and field ids.
    """
    if (DASHBOARDS):
        # Fetch card IDs from the dashboard
        source_card_ids = fetch_cards_from_dashboard(source_api_url, dashboard_id, headers_source)
    else:
        source_card_ids = CARDS

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

        # Begin by updating the top-level source_card
        dataset_query = update_query_recursively(source_card, source_field_mapping,
                                                 target_field_mapping, source_tables, target_tables,
                                                 source_table_mapping, target_table_mapping)

        updated_card["dataset_query"] = dataset_query

        # Update table_id in the card metadata
        if "table_id" in updated_card:
            source_table_name = next(
                (table["name"] for table in source_tables if table["id"] == updated_card["table_id"]), None)
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
        updated_card["database_id"] = TARGET_DATABASE_ID
        updated_card["enable_embedding"] = source_card.get("enable_embedding", False)
        updated_card["collection_id"] = COLLECTION_ID
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

        created_card = create_resource(target_api_url, "card", headers_target, updated_card)

        json_payload = json.dumps(updated_card, indent=4)
        logger.debug(f"Updated card JSON: {json_payload}")
        if created_card:
            card_mapping[source_card["id"]] = created_card["id"]
            logger.info(f"Card '{updated_card.get('name', 'Unnamed')}, Source Card ID: {source_card['id']}, Target Card ID: {created_card['id']}: ' migrated successfully.")
        else:
            logger.error(f"Failed to create card: {updated_card.get('name', 'Unnamed')}")

    return card_mapping


def save_json_payload(json_payload, filename="updated_card.json"):
    """
    Save JSON payload to a file if in debug mode.

    :param json_payload: JSON payload to save.
    :param filename: Name of the file to save the payload to.
    """
    if logger.getEffectiveLevel() <= logging.DEBUG:
        try:
            project_dir = os.path.dirname(os.path.abspath(__file__))  # Project directory
            debug_dir = os.path.join(project_dir, "debug_payloads")
            os.makedirs(debug_dir, exist_ok=True)  # Ensure the directory exists
            file_path = os.path.join(debug_dir, filename)

            with open(file_path, "w", encoding="utf-8") as file:
                json.dump(json_payload, file, indent=4)

            logger.debug(f"JSON payload saved to {file_path}")
        except Exception as e:
            logger.error(f"Failed to save JSON payload: {e}")
    else:
        logger.debug("Debug mode is off; payload not saved.")

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
    source_metadata = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/metadata", HEADERS_SOURCE)
    target_metadata = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/metadata", HEADERS_TARGET)

    source_tables = source_metadata.get("tables", [])
    target_tables = target_metadata.get("tables", [])
    logger.debug(f"Target Tables: {target_tables}")
    logger.debug(f"Source Tables: {source_tables}")

    source_table_mapping, source_field_mapping = build_table_field_mapping(source_tables)
    target_table_mapping, target_field_mapping = build_table_field_mapping(target_tables)

    field_mapping = {"source": source_field_mapping, "target": target_field_mapping}

    log_field_mappings(source_tables, target_tables, field_mapping)

    if (DASHBOARDS):
        for dashboard_id in DASHBOARDS:
            logger.info(f"Processing dashboard ID: {dashboard_id}")
            source_dashboard = fetch_resource(SOURCE_API_URL, f"dashboard/{dashboard_id}", HEADERS_SOURCE)
            if not source_dashboard:
                logger.error(f"Failed to fetch dashboard ID {dashboard_id}. Skipping.")
                continue

            card_mapping = migrate_cards(
                SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET,
                dashboard_id, source_tables, target_tables, source_field_mapping, target_field_mapping,
                source_table_mapping, target_table_mapping
            )

            # Update dashboard with new cards
            # updated_dashboard = update_dashboard_with_cards(source_dashboard, card_mapping)
            updated_dashboard = update_query_recursively(source_dashboard, source_field_mapping,
                                                     target_field_mapping, source_tables, target_tables,
                                                     source_table_mapping, target_table_mapping)
            if not updated_dashboard:
                logger.error(f"Failed to update dashboard ID {dashboard_id}. Skipping.")
                continue

            dashboard_order_dict = OrderedDict([
                ("description", updated_dashboard.get("description", "")),
                ("archived", False),
                ("view_count", updated_dashboard.get("view_count", 0)),
                ("collection_position", updated_dashboard.get("collection_position", None)),
                ("dashcards", updated_dashboard.get("dashcards", [])),
                ("param_values", updated_dashboard.get("param_values", {})),
                ("initially_published_at", updated_dashboard.get("initially_published_at", None)),
                ("can_write", True),
                ("tabs", updated_dashboard.get("tabs", [])),
                ("enable_embedding", updated_dashboard.get("enable_embedding", False)),
                ("collection_id", COLLECTION_ID),
                ("show_in_getting_started", updated_dashboard.get("show_in_getting_started", False)),
                ("name", updated_dashboard.get("name", "Unnamed")),
                ("width", updated_dashboard.get("width", 800)),
                ("caveats", updated_dashboard),
                ("collection_authority_level", updated_dashboard.get("collection_authority_level", "all")),
                ("creator_id", None),
                ("updated_at", None),
                ("made_public_by_id", None),
                ("embedding_params", updated_dashboard.get("embedding_params", None)),
                ("cache_ttl", updated_dashboard.get("cache_ttl", None)),
                ("last_used_param_values", {}),
                ("id", None),
                ("position", updated_dashboard.get("position", 0)),
                ("entity_id", updated_dashboard.get("entity_id", None)),
                ("param_fields", updated_dashboard.get("param_fields", [])),
                ("last-edit-info", updated_dashboard.get("last-edit-info", {})),
                ("collection", updated_dashboard.get("collection", {})),
                ("parameters", updated_dashboard.get("parameters", [])),
                ("auto_apply_filters", updated_dashboard.get("auto_apply_filters", False)),
                ("created_at", updated_dashboard.get("created_at", None)),
                ("public_uuid", updated_dashboard.get("public_uuid", None)),
                ("points_of_interest", updated_dashboard.get("points_of_interest", [])),
            ])

            # json_payload = json.dumps(dashboard_order_dict, indent=4)
            # logger.debug(f"Updated card JSON: {json_payload}")
            # Create the updated dashboard in the target
            create_resource(TARGET_API_URL, "dashboard", HEADERS_TARGET, dashboard_order_dict)
            logger.info(f"Dashboard ID {dashboard_id} migrated successfully.")
    else:
        card_mapping = migrate_cards(
            SOURCE_API_URL, TARGET_API_URL, HEADERS_SOURCE, HEADERS_TARGET,
            [], source_tables, target_tables, source_field_mapping, target_field_mapping,
            source_table_mapping, target_table_mapping
        )
        logger.info(f"New card mappings. {card_mapping}")

    logger.info("Migration process completed.")


if __name__ == "__main__":
    main()
