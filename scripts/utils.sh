check_aws_env_vars() {
    local aws_vars=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_SESSION_TOKEN" "AWS_REGION" "AWS_DEFAULT_REGION")
    local missing_vars=false

    for var in "${aws_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: $var is not set."
            missing_vars=true
        fi
    done

    if [ "$missing_vars" = true ]; then
        exit 1
    else
        return 0
    fi
}


get_tf_remote_state_infra() {
    local s3_prefix="tf-state"
    local dynamodb_prefix="tf-state"

    # Check if any S3 bucket with the tf-state prefix exists
    local s3_bucket=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, \`$s3_prefix\`)].Name" --output text)

    # Check if any DynamoDB table with the tf-state-locks prefix exists
    local dynamodb_table=$(aws dynamodb list-tables --query "TableNames[?starts_with(@, \`$dynamodb_prefix\`)]" --output text)
    if [ -z "$s3_bucket" ] || [ -z "$dynamodb_table" ]; then
        return 1
    else
        printf '{"s3_bucket": "%s", "dynamodb_table": "%s"}\n' "$s3_bucket" "$dynamodb_table"
    fi
}