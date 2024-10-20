#!/bin/bash

# Kaynak ve hedef GitLab bilgileri
SOURCE_GITLAB_URL="<source-gitlab-url>"
TARGET_GITLAB_URL="<target-gitlab-url>"
SOURCE_GROUP_ID="<group_id>"           # Kaynak group ID'si
TARGET_GROUP_ID="<target_group_id>"          # Hedef group ID'si (buraya hedef ID'yi girin)
SOURCE_TOKEN="<source_token>"
TARGET_TOKEN="<target_token>"

# Kaynak Group'taki tüm üyeleri al
MEMBERS=$(curl --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "$SOURCE_GITLAB_URL/api/v4/groups/$SOURCE_GROUP_ID/members/all" | jq -c '.[]')

# Her üyeyi hedef group'a ekle
echo "$MEMBERS" | while read member; do
  USERNAME=$(echo $member | jq -r '.username')
  ACCESS_LEVEL=$(echo $member | jq -r '.access_level')

  # Hedef GitLab instance'ındaki kullanıcı ID'sini bul (username ile)
  TARGET_USER_ID=$(curl --header "PRIVATE-TOKEN: $TARGET_TOKEN" "$TARGET_GITLAB_URL/api/v4/users?username=$USERNAME" | jq -r '.[0].id')

  if [ -z "$TARGET_USER_ID" ] || [ "$TARGET_USER_ID" == "null" ]; then
    echo "Hedef GitLab'da $USERNAME kullanıcı bulunamadı. Atlanıyor."
    continue
  fi

  # Hedef group'a aynı kullanıcıyı ekle
  curl --request POST --header "PRIVATE-TOKEN: $TARGET_TOKEN" \
    --data "user_id=$TARGET_USER_ID&access_level=$ACCESS_LEVEL" \
    "$TARGET_GITLAB_URL/api/v4/groups/$TARGET_GROUP_ID/members" && echo "User $USERNAME added to target group with access level $ACCESS_LEVEL"
done
