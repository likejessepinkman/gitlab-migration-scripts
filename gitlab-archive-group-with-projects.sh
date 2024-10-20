#!/bin/bash

# GitLab bilgileri
GITLAB_URL="<source-gitlab-url>"
ACCESS_TOKEN="<access_token>"
GROUP_ID="<group_id>"  # Group ID veya group path

# Projeleri al
get_projects() {
    page=1
    while :; do
        echo "Sayfa $page için projeler alınıyor..."
        response=$(curl -s --header "Private-Token: $ACCESS_TOKEN" "$GITLAB_URL/api/v4/groups/$GROUP_ID/projects?per_page=100&page=$page&include_subgroups=true")
        
        # Gelen cevabı ekrana yazdırarak kontrol edelim
        echo "API yanıtı: $response"
        
        project_ids=$(echo "$response" | jq -r '.[] | "\(.id) \(.name)"')

        if [[ -z "$project_ids" ]]; then
            echo "Arşivlenecek başka proje yok."
            break
        fi

        echo "Projeler bulundu, arşivleme başlıyor..."
        echo "$project_ids"

        while read -r project_id project_name; do
            archive_project "$project_id" "$project_name"
        done <<< "$project_ids"

        ((page++))
    done
}

# Projeyi arşivle
archive_project() {
    project_id=$1
    project_name=$2
    archive_url="$GITLAB_URL/api/v4/projects/$project_id/archive"

    echo "Arşivleniyor: $project_name (ID: $project_id)..."

    response=$(curl -s -o /dev/null -w "%{http_code}" --request POST --header "Private-Token: $ACCESS_TOKEN" "$archive_url")
    
    if [[ "$response" == "201" ]]; then
        echo "Başarıyla arşivlendi: $project_name (ID: $project_id)"
    else
        echo "Arşivleme hatası: $project_name (ID: $project_id) - HTTP $response"
    fi
}

# Script'i çalıştır
get_projects
