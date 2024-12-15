#!/bin/bash

# Terminal settings
stty -echo -icanon time 0 min 0

# Game settings
field_width=10
field_height=15
player_x=$((field_width / 2))
player_char="A"
enemy_char="X"
bullet_char="^"
empty_char="."

# Initialize field
declare -a field
for ((i=0; i<field_height; i++)); do
    field[i]=$(printf "%-${field_width}s" | tr ' ' "$empty_char")
done

# Print the game field
print_field() {
    clear
    for ((i=0; i<field_height; i++)); do
        echo "${field[i]}"
    done
    echo "Use 'a' and 'd' to move, 's' to shoot."
    echo "Score: $score"
}

# Move player
move_player() {
    local direction=$1
    case $direction in
        a) ((player_x > 0)) && ((player_x--)) ;;
        d) ((player_x < field_width - 1)) && ((player_x++)) ;;
    esac
}

# Shoot bullet
shoot_bullet() {
    local bullet_row=$((field_height - 2))
    field[bullet_row]="${field[bullet_row]:0:player_x}${bullet_char}${field[bullet_row]:player_x+1}"
}

# Update bullets
update_bullets() {
    for ((i=0; i<field_height; i++)); do
        for ((j=0; j<field_width; j++)); do
            if [[ ${field[i]:j:1} == "$bullet_char" ]]; then
                # Clear current bullet
                field[i]="${field[i]:0:j}${empty_char}${field[i]:j+1}"
                if ((i > 0)); then
                    if [[ ${field[i-1]:j:1} == "$enemy_char" ]]; then
                        # Collision with enemy
                        field[i-1]="${field[i-1]:0:j}${empty_char}${field[i-1]:j+1}"
                        ((score++))
                    else
                        # Move bullet up
                        field[i-1]="${field[i-1]:0:j}${bullet_char}${field[i-1]:j+1}"
                    fi
                fi
            fi
        done
    done
}

# Spawn enemy
spawn_enemy() {
    local enemy_x=$((RANDOM % field_width))
    field[0]="${field[0]:0:enemy_x}${enemy_char}${field[0]:enemy_x+1}"
}

# Move enemies
move_enemies() {
    for ((i=field_height-1; i>0; i--)); do
        field[i]=${field[i-1]}
    done
    field[0]=$(printf "%-${field_width}s" | tr ' ' "$empty_char")
}

# Initialize score
score=0

# Main game loop
enemy_move_counter=0
while true; do
    # Clear the previous player position
    field[field_height-1]=$(printf "%-${field_width}s" | tr ' ' "$empty_char")

    # Update player position
    field[field_height-1]="${field[field_height-1]:0:player_x}${player_char}${field[field_height-1]:player_x+1}"

    print_field

    # Clear input buffer
    while read -t 0.001 -n 1 input; do : ; done

    # Read input
    read -n1 -t 0.1 input

    case $input in
        a|d) move_player $input ;;
        s) shoot_bullet ;;
    esac

    # Update bullets
    update_bullets

    # Randomly spawn enemies
    ((RANDOM % 10 < 1)) && spawn_enemy

    # Move enemies every second
    ((enemy_move_counter++))
    if ((enemy_move_counter >= 10)); then
        move_enemies
        enemy_move_counter=0
    fi

    # Check for game over
    if [[ ${field[field_height-1]} == *"$enemy_char"* ]]; then
        break
    fi

    sleep 0.02  # Adjusting overall game speed
done

# Reset terminal
stty echo icanon
clear
echo "Game Over! Your score: $score"