#!/bin/bash

# Coverage and Test Summary Script
# ================================
# This script displays key highlights from pytest coverage runs

echo "🚀 UNIT TEST RESULTS SUMMARY"
echo "========================="
echo ""

# Get coverage.xml file path from argument or default to current directory
COVERAGE_FILE="${1:-coverage.xml}"
# Get coverage threshold from argument or default to 80
COVERAGE_THRESHOLD="${2:-80}"

# Check if coverage.xml exists
if [ ! -f "$COVERAGE_FILE" ]; then
    echo "❌ coverage.xml not found at: $COVERAGE_FILE"
    echo "   Run pytest first: uv run pytest"
    exit 1
fi

echo "📁 Using coverage file: $COVERAGE_FILE"
echo ""

# Clover XML (vitest/jest frontends) vs Cobertura XML (pytest)
IS_CLOVER=false
grep -q '<coverage[^>]*clover=' "$COVERAGE_FILE" && IS_CLOVER=true

# Prints "<file> <covered> <total>" for each file in a Clover report
clover_files() {
    awk -F'"' '
    /<package / { for(i=1; i<NF; i++) if($i ~ /name=$/) { pkg = $(i+1); gsub(/\./, "/", pkg) } }
    /<file / { for(i=1; i<NF; i++) if($i ~ / name=$/) file = $(i+1); in_file = 1; next }
    in_file && /<metrics / {
        for(i=1; i<NF; i++) {
            if($i ~ / statements=$/) total = $(i+1)
            if($i ~ /coveredstatements=$/) covered = $(i+1)
        }
        printf "%s %s %s\n", (pkg ? pkg "/" : "") file, covered, total
        in_file = 0
    }' "$1"
}

# Extract coverage data from XML (optimized)
if [[ "$IS_CLOVER" == "true" ]]; then
    # First <metrics> is the project total; statements map to lines, conditionals to branches
    PROJECT_METRICS=$(grep -m1 -o '<metrics [^>]*' "$COVERAGE_FILE")
    clover_attr() { echo "$PROJECT_METRICS" | grep -o " $1=\"[0-9]*\"" | grep -o '[0-9]*'; }
    lines_valid=$(clover_attr statements)
    lines_covered=$(clover_attr coveredstatements)
    conditionals=$(clover_attr conditionals)
    covered_conditionals=$(clover_attr coveredconditionals)
    line_rate=$(awk "BEGIN {print (${lines_valid:-0} > 0) ? ${lines_covered:-0}/${lines_valid} : 0}")
    branch_rate=$(awk "BEGIN {print (${conditionals:-0} > 0) ? ${covered_conditionals:-0}/${conditionals} : 0}")
else
{
    read -r lines_valid
    read -r lines_covered
    read -r line_rate
    read -r branch_rate
} < <(
    grep -o -E 'lines-valid="[0-9]*"|lines-covered="[0-9]*"|line-rate="[0-9.]*"|branch-rate="[0-9.]*"' "$COVERAGE_FILE" | \
    head -4 | \
    grep -o '[0-9.]*'
)
fi

COVERAGE_PERCENT=$(awk "BEGIN {printf \"%.0f%%\", $line_rate*100}")
TOTAL_LINES="$lines_valid"
COVERED_LINES="$lines_covered"
BRANCH_PERCENT=$(awk "BEGIN {printf \"%.0f%%\", $branch_rate*100}")

# Display results
echo "📊 Coverage: ${COVERAGE_PERCENT:-N/A}"
echo "📈 Lines: ${COVERED_LINES:-N/A} covered / ${TOTAL_LINES:-N/A} total"
echo "🌿 Branches: ${BRANCH_PERCENT:-N/A}"

# Function to check if coverage meets requirement
check_coverage_requirement() {
    local coverage_percent="$1"
    local required_threshold="${2:-80}"
    local silent="${3:-false}"

    # Early return if no coverage data
    [[ -z "$coverage_percent" ]] && return 1

    # Extract numeric value more efficiently
    local coverage_num="${coverage_percent%\%}"

    # Use arithmetic expansion for comparison
    if (( coverage_num >= required_threshold )); then
        [[ "$silent" != "true" ]] && echo "🎯 Required: ${required_threshold}% (EXCEEDED ✅)"
        return 0
    else
        [[ "$silent" != "true" ]] && echo "🎯 Required: ${required_threshold}% (BELOW THRESHOLD ❌)"
        return 1
    fi
}

# Check if coverage meets requirement and store result
if check_coverage_requirement "$COVERAGE_PERCENT" "$COVERAGE_THRESHOLD"; then
    COVERAGE_PASSED=true
else
    COVERAGE_PASSED=false
fi
echo ""

# Show coverage rate for each module (optimized)
echo "📋 MODULE COVERAGE RATES:"
echo "========================="

# Function to get emoji for coverage rate
get_coverage_emoji() {
    local rate="$1"
    if (( $(awk "BEGIN {print ($rate >= 100)}") )); then
        echo "🟢"
    elif (( $(awk "BEGIN {print ($rate >= 90)}") )); then
        echo "🟡"
    elif (( $(awk "BEGIN {print ($rate >= 80)}") )); then
        echo "🟠"
    else
        echo "🔴"
    fi
}

if [[ "$IS_CLOVER" == "true" ]]; then
    CLOVER_RATES=$(clover_files "$COVERAGE_FILE" | awk '{ printf "%s %.4f\n", $1, ($3 > 0) ? $2/$3 : 1 }')
    echo "$CLOVER_RATES" | awk '{
        coverage_val = $2 * 100
        if(coverage_val >= 100) emoji = "🟢"
        else if(coverage_val >= 90) emoji = "🟡"
        else if(coverage_val >= 80) emoji = "🟠"
        else emoji = "🔴"
        printf "%s %s: %.0f%%\n", emoji, $1, coverage_val
    }' | sort -k2
    echo ""

    PERFECT_COUNT=$(echo "$CLOVER_RATES" | awk '$2 >= 1' | wc -l)
    GOOD_COUNT=$(echo "$CLOVER_RATES" | awk '$2 >= 0.8 && $2 < 1' | wc -l)
    TOTAL_FILES=$(echo "$CLOVER_RATES" | grep -c .)
else
# Process all classes in one pass
awk -F'"' '
/<class/ {
    # Extract filename and line-rate
    for(i=1; i<=NF; i++) {
        if($i ~ /filename=/) filename = $(i+1)
        if($i ~ /line-rate=/) line_rate = $(i+1)
    }

    # Clean filename
    gsub(/.*src\/[^\/]*\//, "", filename)

    # Skip empty or directory names
    if(filename && filename !~ /\/$/) {
        coverage_val = line_rate * 100
        coverage_percent = sprintf("%.0f%%", coverage_val)

        # Determine emoji
        if(coverage_val >= 100) emoji = "🟢"
        else if(coverage_val >= 90) emoji = "🟡"
        else if(coverage_val >= 80) emoji = "🟠"
        else emoji = "�"

        printf "%s %s: %s\n", emoji, filename, coverage_percent
    }
}' "$COVERAGE_FILE" | sort -k2
echo ""

# Summary statistics
PERFECT_COUNT=$(grep -c 'line-rate="1"' "$COVERAGE_FILE")
GOOD_COUNT=$(grep 'line-rate="0\.[89]' "$COVERAGE_FILE" | wc -l)
TOTAL_FILES=$(grep -c '<class' "$COVERAGE_FILE")
fi

echo "📊 COVERAGE SUMMARY:"
echo "• Perfect (100%): $PERFECT_COUNT modules"
echo "• Good (80-99%): $GOOD_COUNT modules"
echo "• Total modules: $TOTAL_FILES"

# Exit with appropriate code based on coverage
if [[ "$COVERAGE_PASSED" == "false" ]]; then
    exit 1
else
    exit 0
fi
