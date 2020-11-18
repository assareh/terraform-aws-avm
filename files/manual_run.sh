#!/bin/bash

# NOTE: ensure TFC token is present as TOKEN env variable
# usage: ./manual_run.sh <YOUR TFC ORG> <YOUR TFC WORKSPACE>
TFC_ORG=$1
TFC_WORKSPACE=$2

if [ -z "$TOKEN" ]
then
      echo "Missing required environment variable TOKEN, see usage."
else

if [ $# -lt 2 ]
  then
    echo "Missing required arguments, see usage."
  else

# 2. Get workspace ID
WORKSPACE_ID="$(curl --silent \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request GET \
  https://app.terraform.io/api/v2/organizations/$TFC_ORG/workspaces/$TFC_WORKSPACE | jq -r '.data.id')"

# 3. Queue a destroy plan
read -r -d '' RUN_PAYLOAD << EOM
{
  "data": {
    "type":"runs",
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "$WORKSPACE_ID"
        }
      }
    }
  }
}
EOM

curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data "$(echo $RUN_PAYLOAD)" \
  https://app.terraform.io/api/v2/runs | jq -r '.data'

fi
fi
