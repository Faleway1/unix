#!/bin/bash

affichage_cours_date() {
    local date_recherche="$1"
    local type_recherche="$2"
    local type_agenda


    if [ -z "$type_recherche" ]; then
        echo "Veuillez fournir une date (ex. AAAA-MM-JJ)."
        return 1
    else 
        if [[ "$type_recherche" == "prof" ]]; then
            type_agenda="teacher_3302.json"
        elif [[ "$type_recherche" == "eleve" ]]; then
            type_agenda="program_778.json"
        else
            echo "Type de recherche inconnu : $type_recherche"
            return 1
        fi
    fi

    echo "Calendrier des événements de la date $date_recherche :"
    jq -r --arg date "$date_recherche" '
        .rows[] | 
        select(.srvTimeCrDateFrom | contains($date)) | 
        "\n- Date: \(.srvTimeCrDateFrom) \n- Nom du Cours: \(.prgoOfferingDesc) \n- Description du Cours: \(.valDescription)"' "$type_agenda" 
}


afficher_control() {
    local date_recherche="$1"
    local type_agenda="program_778.json"
    local type_cours="DEVOIRECRIT"

        if [ -z "$date_recherche" ]; then
        echo "Veuillez fournir une date (ex. AAAA-MM-JJ)."
        return 1
    fi

    echo "Prochain controle pour le $date_recherche :"
    jq -r --arg date "$date_recherche" --arg soffDeliveryMode "$type_cours" '
        .rows[] | 
        select(.srvTimeCrDateFrom | contains($date)) | 
        "\n- Date: \(.srvTimeCrDateFrom) \n- Nom du Cours: \(.prgoOfferingDesc) \n- Description du Cours: \(.valDescription)"' "$type_agenda" 
}


afficher_heure_semaine() {
    local date_recherche="$1"
    local date_jour
    local date_fin
    local type_agenda
    local total_heures=0


    if [ -z "$type_recherche" ]; then
        echo "Veuillez fournir une date (ex. AAAA-MM-JJ)."
        return 1
    else 
        if [[ "$type_recherche" == "prof" ]]; then
            type_agenda="teacher_3302.json"
        elif [[ "$type_recherche" == "eleve" ]]; then
            type_agenda="program_778.json"
        else
            echo "Type de recherche inconnu : $type_recherche"
            return 1
        fi
    fi

    for i in {0..6}; do 
        date_jour=$(date -d "$date_debut + $i days" +%Y-%m-%d)
        echo $date_jour
}

afficher_heure_semaine 2024-10-01