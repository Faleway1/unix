#!/bin/bash

affichage_cours_date() {
    local date_recherche="$1"
    local type_recherche="$2"
    local nom="$3"
    local type_agenda
    local date_jour="$date_recherche"


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

    if [ -z "$nom" ]; then
        echo "Veuillez fournir un nom et prenom (ex : NOM, Prenom)."
        return 1
    fi

    for i in {0..6}; do
        echo "Calendrier des événements de la date $date_jour :"

        jq -r --arg date "$date_jour" --arg tchResName "$nom" '
            .rows[] | 
            select(.srvTimeCrDateFrom | contains($date)) | 
            "\n- Date: \(.srvTimeCrDateFrom) \n- Nom du Cours: \(.prgoOfferingDesc) \n- Description du Cours: \(.valDescription)\n"' "$type_agenda" 

        date_jour=$(date -d "$date_debut + $i days" +%Y-%m-%d)
    done
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

format_heure() {
  local heure="$1"
  printf "%04d" "$heure"
}

calculer_duree() {
  local debut="$1"
  local fin="$2"
  debut=$(format_heure "$debut")
  fin=$(format_heure "$fin")
  heure_debut=$((10#${debut:0:2} * 60 + 10#${debut:2:2}))
  heure_fin=$((10#${fin:0:2} * 60 + 10#${fin:2:2}))
  echo $(( (heure_fin - heure_debut) / 60 ))
}



afficher_heure_semaine() {
    local date_recherche="$1"
    local type_recherche="$2"
    local date_jour
    local type_agenda
    local total_heures=0

    if [ -z "$type_recherche" ]; then
        echo -e "\e[31mErreur :\e[0m Veuillez spécifier si vous êtes un élève ou un prof."
        return 1
    else 
        if [[ "$type_recherche" == "prof" ]]; then
            type_agenda="teacher_3302.json"
        elif [[ "$type_recherche" == "eleve" ]]; then
            type_agenda="program_778.json"
        else
            echo -e "\e[31mErreur :\e[0m Type de recherche inconnu : \e[1m$type_recherche\e[0m"
            return 1
        fi
    fi

    if [[ ! -f $type_agenda ]]; then
        echo -e "\e[31mErreur :\e[0m Le fichier \e[1m$type_agenda\e[0m n'existe pas."
        return 1
    fi

    dates_semaine=()
    for i in {0..6}; do
        dates_semaine+=("$(date -d "$date_recherche +$i days" +"%Y-%m-%d")")
    done

    for date in "${dates_semaine[@]}"; do
        echo -e "\nCours pour le $date :"

        cours=$(jq -r --arg date "$date" '
            .rows[]
            | select(.srvTimeCrDateFrom | startswith($date))
            | "\(.timeCrTimeFrom) \(.timeCrTimeTo) \(.valDescription)"
        ' "$type_agenda")

        if [[ -z "$cours" ]]; then
            jour=$(date -d "$date" +%u)
            if [[ "$jour" -eq 6 || "$jour" -eq 7 ]]; then
                echo -e "C'est le weekend !!!"
            else
                echo -e "Jour chomage."
            fi
        else
            while IFS=" " read -r debut fin desc; do
                if [[ "$debut" =~ ^[0-9]+$ && "$fin" =~ ^[0-9]+$ ]]; then
                    duree=$(calculer_duree "$debut" "$fin")
                    total_heures=$((total_heures + duree))
                    echo -e "  - $desc : $duree heures"
                else
                    echo -e "  - $desc : Heures invalides ($debut-$fin)"
                fi
            done <<< "$cours"
        fi
    done

    echo -e "\nTotal des heures de cours pour la semaine : $total_heures heures"
}

afficher_date_module() {
    local FILE="teacher_3302.json"
    local module="$1"

    if [ -z "$module" ]; then
        echo "Veuillez fournir un nom de module (ex. Algorithmique)."
        return 1
    fi

    echo -e "Prochaines séances pour le module : $module "

    jq -c '.rows[]' "$FILE" | while IFS= read -r row; do
    module_name=$(echo "$row" | jq -r '.prgoOfferingDesc')
    date=$(echo "$row" | jq -r '.srvTimeCrDateFrom')
    from=$(echo "$row" | jq -r '.timeCrTimeFrom')
    to=$(echo "$row" | jq -r '.timeCrTimeTo')
    salle=$(echo "$row" | jq -r '.srvTimeCrDelRoom')

    if [[ "$module_name" == "$module" ]]; then
        heure_debut=$(printf "%04d" "$from" | sed 's/\(.\{2\}\)/\1h/')
        heure_fin=$(printf "%04d" "$to" | sed 's/\(.\{2\}\)/\1h/')
        echo -e "  - $date : $heure_debut à $heure_fin (Salle: $salle)"
    fi
    done
}

afficher_date_module Algorithmique