#!/bin/bash

# Fetch all OIDC provider ARNs
OIDC_PROVIDERS=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text)

# Convert to array
read -ra PROVIDER_ARRAY <<< "$OIDC_PROVIDERS"

# Check if any OIDC providers were found
if [[ ${#PROVIDER_ARRAY[@]} -eq 0 ]]; then
    echo "No OIDC providers found."
    exit 0
fi

echo "Found ${#PROVIDER_ARRAY[@]} OIDC provider(s):"
echo

# Print each provider in a new line
for ARN in "${PROVIDER_ARRAY[@]}"; do
    echo "$ARN"
done

echo
read -p "Do you want to delete ALL of these OIDC providers? (yes/no): " CONFIRM

if [[ "$CONFIRM" == "yes" ]]; then
    echo "Deleting all listed OIDC providers..."

    SUCCESS_COUNT=0
    FAIL_COUNT=0

    for ARN in "${PROVIDER_ARRAY[@]}"; do
        echo "Deleting $ARN ..."
        if aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$ARN"; then
            echo "Deleted: $ARN"
            ((SUCCESS_COUNT++))
        else
            echo "Failed to delete: $ARN"
            ((FAIL_COUNT++))
        fi
        echo
    done

    echo "=============================="
    echo "✅ Successfully deleted: $SUCCESS_COUNT"
    echo "❌ Failed to delete:       $FAIL_COUNT"
    echo "=============================="
else
    echo "Aborted. No providers were deleted."
fi
