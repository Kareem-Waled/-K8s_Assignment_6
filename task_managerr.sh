#!/bin/bash
FILE="tasks.txt"
[ ! -f "$FILE" ] && touch "$FILE"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Generate new unique ID
new_id() {
    if [ ! -s "$FILE" ]; then echo 1
    else awk -F"|" 'END{print $1+1}' "$FILE"
    fi
}

# Add a new task
add_task() {
    read -rp "Title: " title
    [ -z "$title" ] && echo -e "${RED}Title cannot be empty!${NC}" && return
    [[ "$title" =~ [^a-zA-Z0-9\ ] ]] && echo -e "${RED}Invalid characters in title!${NC}" && return

    read -rp "Priority (high/medium/low): " priority
    [[ ! "$priority" =~ ^(high|medium|low)$ ]] && echo -e "${RED}Invalid priority!${NC}" && return

    read -rp "Due date (YYYY-MM-DD): " date
    [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo -e "${RED}Invalid date format!${NC}" && return
    ! date -d "$date" &>/dev/null && echo -e "${RED}Invalid date!${NC}" && return

    echo "$(new_id)|$title|$priority|$date|pending" >> "$FILE"
    echo -e "${GREEN}Task added!${NC}"
}
# List all tasks in a table
list_tasks() {
    [ ! -s "$FILE" ] && echo -e "${YELLOW}No tasks found.${NC}" && return
    echo -e "${BOLD}${CYAN}"
    printf "%-5s %-20s %-10s %-12s %-12s\n" "ID" "Title" "Priority" "Due Date" "Status"
    echo -e "${NC}------------------------------------------------------------"
    while IFS="|" read -r id title priority date status; do
        # Color per priority
        color=$NC
        [[ "$priority" == "high" ]]   && color=$RED
        [[ "$priority" == "medium" ]] && color=$YELLOW
        [[ "$priority" == "low" ]]    && color=$GREEN
        printf "${color}%-5s %-20s %-10s %-12s %-12s${NC}\n" "$id" "$title" "$priority" "$date" "$status"
    done < "$FILE"
}

# Update task status by ID
update_task() {
    read -rp "Task ID: " id
    ! grep -q "^$id|" "$FILE" && echo -e "${RED}ID not found!${NC}" && return
    read -rp "New status (pending/in-progress/done): " status
    [[ ! "$status" =~ ^(pending|in-progress|done)$ ]] && echo -e "${RED}Invalid status!${NC}" && return
    sed -i "s/^\($id|[^|]*|[^|]*|[^|]*\)|.*/\1|$status/" "$FILE"
    echo -e "${GREEN}Task updated!${NC}"
}

# Delete a task by ID
delete_task() {
    read -rp "Task ID: " id
    ! grep -q "^$id|" "$FILE" && echo -e "${RED}ID not found!${NC}" && return
    read -rp "Are you sure? (yes/no): " confirm
    [ "$confirm" = "yes" ] && sed -i "/^$id|/d" "$FILE" && echo -e "${GREEN}Task deleted!${NC}"
}

# Search tasks by keyword in title
search_tasks() {
    read -rp "Search keyword: " keyword
    [[ "$keyword" =~ [^a-zA-Z0-9\ ] ]] && echo -e "${RED}Invalid characters in keyword!${NC}" && return
    results=$(grep -i "$keyword" "$FILE")
    [ -z "$results" ] && echo -e "${YELLOW}No results found.${NC}" && return
    echo -e "${BOLD}${CYAN}"
    printf "%-5s %-20s %-10s %-12s %-12s\n" "ID" "Title" "Priority" "Due Date" "Status"
    echo -e "${NC}------------------------------------------------------------"
    while IFS="|" read -r id title priority date status; do
        printf "%-5s %-20s %-10s %-12s %-12s\n" "$id" "$title" "$priority" "$date" "$status"
    done <<< "$results"
}

# Show task summary and overdue tasks
report() {
    echo -e "${BOLD}--- Summary ---${NC}"
    echo -e "${YELLOW}Pending:     $(grep -c "|pending$" "$FILE" 2>/dev/null || echo 0)${NC}"
    echo -e "${CYAN}In-Progress: $(grep -c "|in-progress$" "$FILE" 2>/dev/null || echo 0)${NC}"
    echo -e "${GREEN}Done:        $(grep -c "|done$" "$FILE" 2>/dev/null || echo 0)${NC}"
    echo ""
    echo -e "${BOLD}--- Overdue Tasks ---${NC}"
    today=$(date +%Y-%m-%d)
    found=0
    while IFS="|" read -r id title priority date status; do
        [[ "$status" != "done" && "$date" < "$today" ]] && echo -e "${RED}$id | $title | $date${NC}" && found=1
    done < "$FILE"
    [ $found -eq 0 ] && echo -e "${GREEN}No overdue tasks!${NC}"
}

# Main menu loop
while true; do
    echo ""
    echo -e "${BOLD}${CYAN}=== Task Manager ===${NC}"
    echo "1) Add task"
    echo "2) List tasks"
    echo "3) Update task"
    echo "4) Delete task"
    echo "5) Search"
    echo "6) Report"
    echo "7) Exit"
    read -rp "Choose: " choice
    case $choice in
        1) add_task ;;
        2) list_tasks ;;
        3) update_task ;;
        4) delete_task ;;
        5) search_tasks ;;
        6) report ;;
        7) echo -e "${GREEN}Goodbye!${NC}" && exit 0 ;;
        *) echo -e "${RED}Invalid choice!${NC}" ;;
    esac
done
