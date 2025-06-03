# zot-chart-extractor

A simple tool to extract Helm chart metadata from a Zot OCI registry folder structure and produce a summary listing.

## Features

- Scans all likely Helm chart archives (`.tgz`, `.tar.gz`, `.tar`) under a given directory.
- Extracts and summarizes `Chart.yaml` metadata from each chart.
- Deduplicates charts by name and version.
- Outputs a colorized summary table to the terminal.
- Can list charts from an existing `helm-charts.yml` file.

## Requirements

- Bash
- GNU coreutils (`find`, `tar`, etc.)
- [yq (Go version, v4+)](https://github.com/mikefarah/yq)

## Usage

```sh
# Scan all likely chart archives under ./zot (or a custom path)
./zot-chart-tool.sh scan [-p|--path <zot-root>]

# Example:
./zot-chart-tool.sh scan -p ./zot/bitnami/

# List charts from an existing helm-charts.yml file
./zot-chart-tool.sh list [-f|--file <helm-charts.yml>]

# Example:
./zot-chart-tool.sh list -f helm-charts.yml
```

## Output

- `helm-charts.yml` — deduplicated YAML summary of all found charts.
- Colorized summary table printed to the terminal.

## Inline Demo

[![asciicast](https://asciinema.org/a/cqLb8r0VEE6KNz7Zph4x0NmfA.svg)](https://asciinema.org/a/cqLb8r0VEE6KNz7Zph4x0NmfA)


Replace `your-demo-id` with your actual asciinema recording ID.

## Notes

- Only files with `.tgz`, `.tar.gz`, or `.tar` extensions and size >10kB are scanned for performance.
- The tool will skip files that do not contain a `Chart.yaml`.
- Deduplication is performed by chart name and version.

---
# zot-chart-extractor
