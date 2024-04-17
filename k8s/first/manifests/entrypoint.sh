#!/bin/sh

# Read and decode the 'flag' secret
flag_secret=$(kubectl get secret flag -n medium -o=jsonpath='{.data.flag}')
decoded_flag=$(echo "$flag_secret" | base64 -d)

# Read and decode the 'db' secret
db_secret=$(kubectl get secret db -n medium -o=jsonpath='{.data.flag}')
decoded_db=$(echo "$db_secret" | base64 -d)

# Output the decoded secrets
echo "Flag Secret: $decoded_flag"
echo "DB Secret: $decoded_db"