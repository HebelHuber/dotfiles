#!/bin/sh

function create_tunnel {
    TUNNEL_NAME="$1"

    CREATE_RESULT=$(curl "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        --data "{
          \"name\": \"${TUNNEL_NAME}\",
          \"config_src\": \"cloudflare\"
    }")

    echo "$CREATE_RESULT" | jq '.'
    TUNNEL_ID=$(echo "$CREATE_RESULT" | jq -r '.result.id')
    TUNNEL_TOKEN=$(echo "$CREATE_RESULT" | jq -r '.result.token')
    echo "Tunnel ID: $TUNNEL_ID"
    echo "Tunnel Token: $TUNNEL_TOKEN"
}

function connect_app {
    NEW_TUNNEL_HOSTNAME="$1"
    NEW_TUNNEL_LOCAL_URL="$2"

    CONNECTION_APP_RESULT=$(curl --request PUT "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        --data "{
              \"config\": {
                \"ingress\": [
                  {
                    \"hostname\": \"${NEW_TUNNEL_HOSTNAME}\",
                    \"service\": \"${NEW_TUNNEL_LOCAL_URL}\",
                    \"originRequest\": {}
                  },
                  {
                    \"service\": \"http_status:404\"
                  }
              ]
          }
    }")

    echo "$CONNECTION_APP_RESULT" | jq '.'
}

# load credentials from .env
# CLOUDFLARE_ACCOUNT_ID
# CLOUDFLARE_API_TOKEN
# CLOUDFLARE_ZONE_ID

. .env

# Example usage:
# create_tunnel "testtunnel-1" # this will set $TUNNEL_ID. If you don't call this function first, you'll need to set it manually
# connect_app "new_public.domain.com" "http://localhost:9090"
