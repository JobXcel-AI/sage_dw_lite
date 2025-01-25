import requests
import json

# Metabase API credentials and endpoints
SOURCE_API_URL = "https://sagexcel.jobxcel.report/api"
TARGET_API_URL = "https://asg.xcel.report/api"
SOURCE_API_KEY = "mb_blLUnFYZ+diBCC1OY8zBmLXRkKZiRy5f+iFHf1Cj+9E="
TARGET_API_KEY = "mb_/eIVf6avszWL2YkjlUU21gfD2//Ip2iLgzhuVs+g2rI="
SOURCE_DATABASE_ID = 2  # Set the source database ID
TARGET_DATABASE_ID = 2  # Set the target database ID

HEADERS_SOURCE = {
    "x-api-key": SOURCE_API_KEY,
    "Content-Type": "application/json"
}

HEADERS_TARGET = {
    "x-api-key": TARGET_API_KEY,
    "Content-Type": "application/json"
}

def get_table_mapping(source_tables, target_tables):
    """
    Map source table names to target table IDs.
    """
    mapping = {}
    target_table_lookup = {table["name"]: table["id"] for table in target_tables}
    for source_table in source_tables:
        target_id = target_table_lookup.get(source_table["name"])
        if target_id:
            mapping[source_table["id"]] = target_id
    return mapping

def get_field_mapping(source_fields, target_fields):
    """
    Map source field names to target field IDs.
    """
    mapping = {}
    target_field_lookup = {field["name"]: field["id"] for field in target_fields}
    for source_field in source_fields:
        target_id = target_field_lookup.get(source_field["name"])
        if target_id:
            mapping[source_field["id"]] = target_id
    return mapping

def fetch_resource(api_url, endpoint, headers):
    try:
        response = requests.get(f"{api_url}/{endpoint}", headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching resource from {api_url}/{endpoint}: {e}")
        return None

def fetch_fields(api_url, database_id, headers):
    """
    Fetch all fields for a given database ID.
    """
    endpoint = f"database/{database_id}/fields"
    return fetch_resource(api_url, endpoint, headers)

def update_dashboard_and_cards(source_dashboard, table_mapping, field_mapping):
    """
    Update the dashboard's cards to reflect the new table and field IDs.
    """
    if not source_dashboard:
        print("Source dashboard data is empty.")
        return None

    for dashcard in source_dashboard.get("dashcards", []):
        card = dashcard.get("card")
        if card:
            dataset_query = card.get("dataset_query")
            if dataset_query:
                query = dataset_query.get("query")

                # Update table IDs
                if "source-query" in query:
                    query["source-query"]["table_id"] = table_mapping.get(query["source-query"].get("table_id"), query["source-query"].get("table_id"))

                # Update field IDs in aggregations and breakout
                for agg in query.get("aggregation", []):
                    if isinstance(agg, list) and len(agg) > 1:
                        field_id = agg[1].get("id")
                        if field_id:
                            agg[1]["id"] = field_mapping.get(field_id, field_id)
                        else:
                            print(f"Warning: Unexpected structure in aggregation: {agg}")

                for breakout in query.get("breakout", []):
                    if isinstance(breakout, list) and len(breakout) > 1:
                        field_id = breakout[1].get("id")
                        if field_id:
                            breakout[1]["id"] = field_mapping.get(field_id, field_id)
                        else:
                            print(f"Warning: Unexpected structure in breakout: {breakout}")

    return source_dashboard

def validate_dashboard_id(dashboard_id):
    """
    Validate and sanitize the dashboard ID to ensure it is an integer.
    """
    if not isinstance(dashboard_id, int) or dashboard_id <= 0:
        raise ValueError("Invalid dashboard ID. It must be a positive integer.")
    return dashboard_id

def main():
    # Fetch tables from source and target databases
    source_tables = fetch_resource(SOURCE_API_URL, f"database/{SOURCE_DATABASE_ID}/metadata", HEADERS_SOURCE).get("tables", [])
    target_tables = fetch_resource(TARGET_API_URL, f"database/{TARGET_DATABASE_ID}/metadata", HEADERS_TARGET).get("tables", [])

    if not source_tables or not target_tables:
        print("Failed to fetch tables. Aborting.")
        return

    table_mapping = get_table_mapping(source_tables, target_tables)

    # Fetch fields from source and target databases
    source_fields = fetch_fields(SOURCE_API_URL, SOURCE_DATABASE_ID, HEADERS_SOURCE)
    target_fields = fetch_fields(TARGET_API_URL, TARGET_DATABASE_ID, HEADERS_TARGET)

    if not source_fields or not target_fields:
        print("Failed to fetch fields. Aborting.")
        return

    field_mapping = get_field_mapping(source_fields, target_fields)

    # Fetch the source dashboard
    dashboard_id = 4  # Replace with your dashboard ID
    try:
        dashboard_id = validate_dashboard_id(dashboard_id)
        source_dashboard = fetch_resource(SOURCE_API_URL, f"dashboard/{dashboard_id}", HEADERS_SOURCE)
    except ValueError as e:
        print(e)
        return

    # Update dashboard with target IDs
    updated_dashboard = update_dashboard_and_cards(source_dashboard, table_mapping, field_mapping)
    if not updated_dashboard:
        print("Failed to update the dashboard. Aborting.")
        return

    # Create the updated dashboard in the target Metabase
    try:
        response = requests.post(
            f"{TARGET_API_URL}/dashboard",
            headers=HEADERS_TARGET,
            data=json.dumps(updated_dashboard),
            timeout=10
        )
        response.raise_for_status()
        print("Dashboard migrated successfully.")
    except requests.exceptions.RequestException as e:
        print(f"Failed to migrate dashboard: {e}")

if __name__ == "__main__":
    main()
