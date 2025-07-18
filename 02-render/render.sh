#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="./templates"
OUTPUT_DIR="../03-install"
OUTPUTS_FILE="../01-infra/outputs.json"

echo "🛠️ Rendering templates to $OUTPUT_DIR..."
mkdir -p "$OUTPUT_DIR/rendered-manifests"
mkdir -p "$OUTPUT_DIR/helm-values"

for template in "$TEMPLATE_DIR"/*.gotmpl; do
  filename=$(basename "$template" .gotmpl)

  if [[ "$filename" == *-values.yaml ]]; then
    outpath="$OUTPUT_DIR/helm-values/${filename}"
  else
    outpath="$OUTPUT_DIR/rendered-manifests/${filename}"
  fi

  gomplate \
    --context .=${OUTPUTS_FILE} \
    --file "$template" \
    --out "$outpath"

  echo "✅ Rendered $outpath"
done

echo "🎉 All templates rendered successfully!"