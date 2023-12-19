#!/bin/bash

# Set your SQS queue URL
queue_url="https://sqs.<your-region>.amazonaws.com/<your-account-id>/YourQueueName"

# Set the output JSON file
output_file="output.json"

# Initialize an empty array to store all messages
all_messages=()

# Function to retrieve messages from SQS
get_messages() {
    local result
    result=$(aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages 10)

    if [[ $(echo "$result" | jq -r '.Messages | length') -gt 0 ]]; then
        all_messages+=($(echo "$result" | jq -c -r '.Messages[].Body'))
        local receipt_handles=$(echo "$result" | jq -c -r '.Messages[].ReceiptHandle')
        aws sqs delete-message --queue-url "$queue_url" --receipt-handle "$receipt_handles" > /dev/null
    fi
}

# Loop to retrieve all messages
while : ; do
    get_messages
    if [[ $(echo "$result" | jq -r '.Messages | length') -eq 0 ]]; then
        break
    fi
done

# Create a JSON array from all message bodies
json_array="[$(echo "${all_messages[@]}" | jq -c -s '.' | sed ':a;N;$!ba;s/\n/,/g')]"

# Output the JSON array to a file
echo "$json_array" > "$output_file"

echo "JSON file '$output_file' created with all received messages."
