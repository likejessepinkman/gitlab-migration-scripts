#!/bin/bash

# Kaynak ve hedef GitLab bilgileri
SOURCE_GITLAB_URL="<source-gitlab-url>"
TARGET_GITLAB_URL="<target-gitlab-url>"
SOURCE_GROUP_ID="<source_group_id>"           # Kaynak group ID'si
TARGET_GROUP_ID="<target_group_id>"  # Hedef group ID'si (buraya hedef ID'yi girin)
SOURCE_TOKEN="<source_token>"
TARGET_TOKEN="<target_token>"

# Kaynak Group'taki tüm projeleri listele
SOURCE_PROJECTS=$(curl --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "$SOURCE_GITLAB_URL/api/v4/groups/$SOURCE_GROUP_ID/projects?per_page=100" | jq -c '.[]')

# Hedef Group'taki tüm projeleri listele
TARGET_PROJECTS=$(curl --header "PRIVATE-TOKEN: $TARGET_TOKEN" "$TARGET_GITLAB_URL/api/v4/groups/$TARGET_GROUP_ID/projects?per_page=100" | jq -c '.[]')

# Kaynak projeleri döngüye al
echo "$SOURCE_PROJECTS" | while read source_project; do
  SOURCE_PROJECT_ID=$(echo $source_project | jq -r '.id')
  SOURCE_PROJECT_NAME=$(echo $source_project | jq -r '.name')

  # Kaynak projeden değişkenleri al
  VARIABLES=$(curl --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "$SOURCE_GITLAB_URL/api/v4/projects/$SOURCE_PROJECT_ID/variables")

  # Hedef projeyi bul (aynı isimli proje olması varsayılıyor)
  TARGET_PROJECT_ID=$(echo "$TARGET_PROJECTS" | jq -r --arg NAME "$SOURCE_PROJECT_NAME" 'select(.name == $NAME) | .id')

  if [ -z "$TARGET_PROJECT_ID" ]; then
    echo "Hedef projede $SOURCE_PROJECT_NAME isminde bir proje bulunamadı. Atlanıyor."
    # continue komutunu kaldırarak bu projeyi atlatalım, script devam etsin
    continue
  fi

  # Hedef projeye değişkenleri ekle
  echo "$VARIABLES" | jq -c '.[]' | while read variable; do
    KEY=$(echo $variable | jq -r '.key')
    VALUE=$(echo $variable | jq -r '.value')

    echo "Adding variable $KEY to project ID $TARGET_PROJECT_ID"
    curl --request POST --header "PRIVATE-TOKEN: $TARGET_TOKEN" \
      --data "key=$KEY&value=$VALUE" \
      "$TARGET_GITLAB_URL/api/v4/projects/$TARGET_PROJECT_ID/variables"
  done
done
