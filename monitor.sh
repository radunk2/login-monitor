#!/bin/bash

THRESHOLD=5
ALERT_FILE="alerts.log"
HISTORY_FILE="history.log"
JSON_FILE="alerts.json"
TEMP_FILE="temp.txt"

scan_logins() {
  echo "Scanare.."
  journalctl -u ssh --no-pager | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr > "$TEMP_FILE"

  > "$JSON_FILE"
  echo "[" >> "$JSON_FILE"
  FIRST_ENTRY=true

  while read -r count ip; do
    if [ "$count" -ge "$THRESHOLD" ]; then
      # Dacă nu e deja în alerts.log
      if ! grep -q "$ip" "$ALERT_FILE" 2>/dev/null; then
        ALERT_MSG="[ALERTA] $ip a avut $count incercari esuate!"
        echo "$ALERT_MSG" | tee -a "$ALERT_FILE"

        # Salvăm în JSON
        if [ "$FIRST_ENTRY" = true ]; then
          FIRST_ENTRY=false
        else
          echo "," >> "$JSON_FILE"
        fi
        echo "  { \"ip\": \"$ip\", \"incercari\": $count }" >> "$JSON_FILE"
      fi
    fi
  done < "$TEMP_FILE"

  echo "]" >> "$JSON_FILE"
  cat "$TEMP_FILE" >> "$HISTORY_FILE"
  rm "$TEMP_FILE"
}

view_alerts() {
  echo -e "\n Alerte detectate:"
  [ -f "$ALERT_FILE" ] && cat "$ALERT_FILE" || echo "Nicio alerta salvata."
}

view_history() {
  echo -e "\n Istoric autentificari:"
  [ -f "$HISTORY_FILE" ] && cat "$HISTORY_FILE" || echo "Istoricul este gol."
}

export_json() {
  echo -e "\n Export JSON:"
  [ -f "$JSON_FILE" ] && cat "$JSON_FILE" || echo "Niciun export disponibil."
}

clear_logs() {
  rm -f "$ALERT_FILE" "$HISTORY_FILE" "$JSON_FILE"
  echo "Toate logurile au fost sterse!"
}

while true; do
  echo -e "\n=== MENIU LOGIN MONITOR ==="
  echo "1. Scanare"
  echo "2. Vezi alerte"
  echo "3. Vezi istoric complet"
  echo "4. Exporta JSON"
  echo "5. Sterge logurile"
  echo "6. Iesire"
  read -p "Alege o optiune (1-6): " opt

  case $opt in
    1) scan_logins ;;
    2) view_alerts ;;
    3) view_history ;;
    4) export_json ;;
    5) clear_logs ;;
    6) exit 0 ;;
    *) echo "Optiune invalida!" ;;
  esac
done

