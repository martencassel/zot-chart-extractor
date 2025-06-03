#!/bin/bash

set -e


# --- Dependency checker ---
REQUIRED_TOOLS=(bash tar find yq sed grep)
MISSING=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING+=("$tool")
    fi
done
if [ "${#MISSING[@]}" -ne 0 ]; then
    echo "Missing required tools: ${MISSING[*]}"
    echo "Please install them and try again."
    exit 1
fi

# Check yq version (must be Go version v4+)
if ! yq --version 2>&1 | grep -qE '^yq (version )?4\.'; then
    echo "yq v4+ (Go version) is required. Install from https://github.com/mikefarah/yq"
    exit 1
fi
# --- End dependency checker ---

# Color definitions for output
CYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[1;32m'
MAGENTA=$'\033[1;35m'
RESET=$'\033[0m'

# Constants for file names
RAW_OUTPUT="helm-charts-raw.yml"
OUTPUT_FILE="helm-charts.yml"
TMP_CHART="chart.yaml.tmp"

# Function to display usage information
usage() {
    echo "Usage:"
    echo "  $0 scan [-p|--path <zot-root>]   # Scan all subpaths (default: ./zot)"
    echo "  $0 list [-f|--file <helm-charts.yml>]  # List charts from an existing helm-charts.yml"
    exit 1
}


# Function to list Helm charts from the output file
list_charts() {
    local file="${1:-$OUTPUT_FILE}"
    if ! command -v yq >/dev/null 2>&1; then
        printf "${YELLOW}yq not found, cannot print summary table.${RESET}\n"
        exit 1
    fi
    printf "\n${CYAN}Summary of extracted Helm charts:${RESET}\n"
    yq -r '
      .helm_charts[] |
      . as $item |
      ($item.chart_yaml | from_yaml) as $c |
      "Path: \($item.path)\nName: \($c.name)\nVersion: \($c.version)\nAppVersion: \($c.appVersion)\nDescription: \($c.description)\n"
    ' "$file" | \
    while IFS= read -r line; do
        case "$line" in
            Path:*) printf "${CYAN}%s${RESET}\n" "$line" ;;
            Name:*) printf "${MAGENTA}%s${RESET}\n" "$line" ;;
            Version:*) printf "${YELLOW}%s${RESET}\n" "$line" ;;
            AppVersion:*) printf "${GREEN}%s${RESET}\n" "$line" ;;
            Description:*) printf "${CYAN}%s${RESET}\n" "$line" ;;
            *) printf "%s\n" "$line" ;;
        esac
    done
}

# Function to scan all subpaths for Helm charts
scan_all() {
    local ROOT_DIR="${1:-./zot}"

    if [ ! -d "$ROOT_DIR" ]; then
        echo -e "${YELLOW}Directory $ROOT_DIR does not exist.${RESET}"
        exit 1
    fi
    echo -e "${CYAN}Scanning all subpaths in: $ROOT_DIR${RESET}"

    echo "helm_charts:" > "$RAW_OUTPUT"

    total_files=$(find "$ROOT_DIR" -type f | wc -l)
    current_file=0

    # Find all tar.gz files and extract Chart.yaml
    find "$ROOT_DIR" -type f | while read -r archive; do
        current_file=$((current_file + 1))
        echo -ne "${CYAN}[$current_file/$total_files]${RESET} Processing: ${YELLOW}${archive}${RESET}          \r"
        chart_path=$(tar -tzf "$archive" 2>/dev/null | grep 'Chart.yaml' | head -n1)
        if [ -n "$chart_path" ]; then
            tar -xOzf "$archive" "$chart_path" > "$TMP_CHART"
            if [ -s "$TMP_CHART" ]; then
                echo -e "\n${GREEN}Found Chart.yaml in:${RESET} ${archive}"
                echo "  - path: \"$archive\"" >> "$RAW_OUTPUT"
                echo "    chart_yaml: |" >> "$RAW_OUTPUT"
                sed 's/^/      /' "$TMP_CHART" >> "$RAW_OUTPUT"
            fi
            rm -f "$TMP_CHART"
        fi
    done
    echo -e "\n${GREEN}Processing complete!${RESET}"

    # # Deduplicate by Chart.yaml content (optional, using yq)
    # yq -y '
    #   .helm_charts |= (unique_by(.chart_yaml | from_yaml | .name + ":" + (.version // "")))
    # ' "$RAW_OUTPUT" > "$OUTPUT_FILE"

    echo -e "${CYAN}Writing final output to ${OUTPUT_FILE}${RESET}"
    cp -f "$RAW_OUTPUT" "$OUTPUT_FILE"
    list_charts "$OUTPUT_FILE"
}


# Main logic
case "$1" in
    scan)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -p|--path)
                    ROOT_DIR="$2"
                    shift 2
                    ;;
                *)
                    usage
                    ;;
            esac
        done
        scan_all "${ROOT_DIR:-./zot}"
        ;;
    list)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -f|--file)
                    LIST_FILE="$2"
                    shift 2
                    ;;
                *)
                    usage
                    ;;
            esac
        done
        list_charts "${LIST_FILE:-$OUTPUT_FILE}"
        ;;
    *)
        usage
        ;;
esac
