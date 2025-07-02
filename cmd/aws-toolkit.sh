#!/bin/bash

# Helper: Delete OIDC Providers
delete_oidc_providers() {
    OIDC_PROVIDERS=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output text)
    read -ra PROVIDER_ARRAY <<< "$OIDC_PROVIDERS"

    if [[ ${#PROVIDER_ARRAY[@]} -eq 0 ]]; then
        whiptail --msgbox "No OIDC providers found." 10 40
        return
    fi

    OUTPUT="Found ${#PROVIDER_ARRAY[@]} OIDC provider(s):\n"
    for ARN in "${PROVIDER_ARRAY[@]}"; do
        OUTPUT+="$ARN\n"
    done

    whiptail --scrolltext --title "OIDC Providers" --msgbox "$OUTPUT" 20 70

    if whiptail --yesno "Do you want to delete ALL of these OIDC providers?" 10 60; then
        SUCCESS=0
        FAIL=0
        for ARN in "${PROVIDER_ARRAY[@]}"; do
            if aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$ARN"; then
                ((SUCCESS++))
            else
                ((FAIL++))
            fi
        done
        whiptail --msgbox "Deleted: $SUCCESS\nFailed: $FAIL" 10 40
    else
        whiptail --msgbox "Aborted. No providers deleted." 10 40
    fi
}

# Helper: Scan EC2 Instances
# echo "Searching in region ${REGION}"
scan_ec2_instances() {
    REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
        if [[ -z "$REGIONS" ]]; then
            whiptail --msgbox "Could not retrieve AWS regions." 10 50
            return
        fi

        TMPFILE=$(mktemp)

        printf "%-20s %-15s %-50s\n" "Instance ID" "State" "Name (Tag)" > "$TMPFILE"
        printf "%s\n" "--------------------------------------------------------------" >> "$TMPFILE"

        for REGION in $REGIONS; do
            echo "Searching in region ${REGION}"
            INSTANCES=$(aws ec2 describe-instances \
                --region "$REGION" \
                --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value | [0]]' \
                --output text)

            if [[ -n "$INSTANCES" ]]; then
                echo -e "\nRegion: $REGION" >> "$TMPFILE"
                while IFS=$'\n' read -r LINE; do
                    INSTANCE_ID=$(echo "$LINE" | awk '{print $1}')
                    STATE=$(echo "$LINE" | awk '{print $2}')
                    NAME=$(echo "$LINE" | cut -d' ' -f3-)
                    printf "%-20s %-15s %-50s\n" "$INSTANCE_ID" "$STATE" "$NAME" >> "$TMPFILE"
                done <<< "$INSTANCES"
            fi
        done

        if [[ $(wc -l < "$TMPFILE") -le 2 ]]; then
            whiptail --msgbox "No EC2 instances found in any region." 10 50
        else
            whiptail --title "EC2 Instances in All Regions" --textbox "$TMPFILE" 30 110
        fi

        rm -f "$TMPFILE"
}

# Main Menu
while true; do
    CHOICE=$(whiptail --title "AWS Toolkit" --menu "Choose an operation:" 15 60 4 \
        "1" "Delete OIDC Providers" \
        "2" "Scan EC2 Instances" \
        "3" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) delete_oidc_providers ;;
        2) scan_ec2_instances ;;
        3) break ;;
        *) whiptail --msgbox "Invalid choice." 10 40 ;;
    esac
done
