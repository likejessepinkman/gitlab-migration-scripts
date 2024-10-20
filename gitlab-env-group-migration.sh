#!/bin/bash

# Kaynak ve hedef GitLab bilgileri
SOURCE_GITLAB_URL="<source-gitlab-url>"
TARGET_GITLAB_URL="<target-gitlab-url>"
SOURCE_GROUP_ID="<group_id>"            # Kaynak group ID'si
TARGET_GROUP_ID="<target_group_id>"  # Hedef group ID'si (buraya hedef ID'yi girin)
SOURCE_TOKEN="<source_token>"
TARGET_TOKEN="<target_token>"

# Kaynak Group'taki tüm değişkenleri al
VARIABLES=$(curl --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "$SOURCE_GITLAB_URL/api/v4/groups/$SOURCE_GROUP_ID/variables")

# Her bir değişkeni hedef Group'a ekle
echo "$VARIABLES" | jq -c '.[]' | while read variable; do
  KEY=$(echo $variable | jq -r '.key')
  VALUE=$(echo $variable | jq -r '.value')

  # Hedef group'a değişken ekle
  curl --request POST --header "PRIVATE-TOKEN: $TARGET_TOKEN" \
    --data "key=$KEY&value=$VALUE" \
    "$TARGET_GITLAB_URL/api/v4/groups/$TARGET_GROUP_ID/variables"
done
