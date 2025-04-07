#!/bin/sh

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
BOLD=`tput bold`
RESET=`tput sgr0`
# echo "hello ${RED}some red text${RESET} world"

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

    # get current tunnel configurations

    CURRENT_RESULT=$(curl "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" )

    #echo "${RED} CURRENT_RESULT ${RESET}"
    #echo "$CURRENT_RESULT" | jq '.'    

    # Add new app to config

    CONFIG_SECTION=$(echo "$CURRENT_RESULT" | jq '.result.config.ingress')
    
    PUBLIC_HOSTNAMES=$(echo "$CONFIG_SECTION" | jq ". = (.[:-1] + [{
                    \"hostname\": \"${NEW_TUNNEL_HOSTNAME}\",
                    \"service\": \"${NEW_TUNNEL_LOCAL_URL}\",
                    \"originRequest\": {
                        \"access\": {
                            \"audTag\": [\"${CLOUDFLARE_AUD_TAG}\"],
                            \"required\": true,
                            \"teamName\": \"${CLOUDFLARE_TEAM_NAME}\"
                        }
                    }
                  }] + .[-1:])")

    # echo "${RED} NEW_CONFIG ${RESET}"
    # echo "$NEW_CONFIG" | jq '.'

    NEW_CONFIG=$(jq -n "{config: {ingress: $PUBLIC_HOSTNAMES}}")

    # connect app

    CONNECTION_APP_RESULT=$(curl \
        --request PUT "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        --data $(echo "$NEW_CONFIG" | jq -r '.|tojson') )


  # CONNECTION_APP_RESULT=$(curl --request PUT "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
  #      --header 'Content-Type: application/json' \
  #      --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  #      --data "{
  #            \"config\": {
  #              \"ingress\": [
  #                {
  #                  \"hostname\": \"${NEW_TUNNEL_HOSTNAME}\",
  #                  \"service\": \"${NEW_TUNNEL_LOCAL_URL}\",
  #                  \"originRequest\": {
  #                      \"access\": {
  #                          \"audTag\": [\"69b1a03f0782ea89fb7e57fc64bca18903c57be96bdeeb8eeb4a7348f4e6f4d8\"],
  #                          \"required\": true,
  #                          \"teamName\": \"kiefercloud\"
  #                      }
  #                  }
  #                },
  #                {
  #                  \"service\": \"http_status:404\"
  #                }
  #            ]
  #        }
  # }")

    echo "$CONNECTION_APP_RESULT" | jq '.'

    # create DNS entry

    ADD_DNS_RESULT=$(curl "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        --data "{
            \"type\": \"CNAME\",
            \"proxied\": true,
            \"name\": \"${NEW_TUNNEL_HOSTNAME}\",
            \"content\": \"${TUNNEL_ID}.cfargotunnel.com\"
        }")

    echo "$ADD_DNS_RESULT" | jq '.'
}

# load credentials from .env
# CLOUDFLARE_ACCOUNT_ID
# CLOUDFLARE_API_TOKEN
# CLOUDFLARE_ZONE_ID
# CLOUDFLARE_ACCESS_APPLICATION_ID

. .env

# Example usage:
# create_tunnel "testtunnel-1" # this will set $TUNNEL_ID. If you don't call this function first, you'll need to set it manually
# connect_app "new_public.domain.com" "http://localhost:9090"
