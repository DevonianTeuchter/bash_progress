#!/bin/env bash

# Given input to stdin, send that to stdout
# but also update an onscreen meter that indicates that something
# has happened. This is useful for long-running processes that
# you want to see progress on.
# TODO: determine what to do with stderr from the watched process if anything!
# This is a simple example that just prints a dot for every line
# of input.

function dots() {
    batchsize=${1:-10}
    tick=1
    while read -r line; do
        tick=$(( (tick + 1) % batchsize))
        [ $tick -eq 0 ] && printf '.' >&2
        echo "$line"
    done
}

function counter() {
    increment=${1:-1}
    tick=0
    while read -r line; do
        tick=$((tick + 1))
        if [ $((tick % increment)) -eq 0  ]; then
          printf '\r%s' "$tick"  >&2
        fi
        echo "$line"
    done
}

function bounce() {
    local max_width="${1:-$(tput cols 2>/dev/null || echo 80)}"
    local bg_char="${2:- }"
    local head_char="${3}"
    local tail_right="${4:-)))}"
    local tail_left="${5:-{{{}"
    local col=1
    local direction=1
    local tick=0
    
    # Calculate tail lengths
    local tail_right_length=${#tail_right}
    local tail_left_length=${#tail_left}
    local head_length=${#head_char}
    
    # Build background string
    local background=""
    for ((i=1; i<=max_width; i++)); do
        background+="$bg_char"
    done
    
    # Ensure cursor is restored on exit
    trap 'printf "\e[?25h\r%-80s\r" "" >&2' EXIT INT TERM
    
    # Hide cursor using ANSI escape sequence
    printf '\e[?25l' >&2
    
    while read -r line; do
        tick=$(( (tick + 1) % 500 ))
        if [ $tick -eq 0 ]; then
            # Bounce at boundaries BEFORE drawing
            if [ "$col" -gt "$max_width" ]; then
                direction=-1
                col=$max_width
            elif [ "$col" -lt 1 ]; then
                direction=1
                col=1
            fi
            
            # Start with background, then overwrite with pattern
            printf '\r%s' "$background" >&2
            
            # Print character with tail
            if [ "$direction" -eq 1 ]; then
                # Moving right: tail on left
                local start_pos=$((col - tail_left_length))
                local tail_offset=0
                
                # Calculate substring offset if near left edge
                if [ "$start_pos" -lt 1 ]; then
                    tail_offset=$((1 - start_pos))
                    start_pos=1
                fi
                
                # Position cursor at start of tail
                printf '\r' >&2
                if [ "$start_pos" -gt 1 ]; then
                    printf '\e[%dC' "$((start_pos - 1))" >&2
                fi
                
                # Print tail substring
                local tail_to_print="${tail_left:$tail_offset}"
                printf '%s' "$tail_to_print" >&2
                
                # Print head if provided
                [ -n "$head_char" ] && printf '%s' "$head_char" >&2
            else
                # Moving left: tail on right
                # Position cursor at col
                printf '\r' >&2
                if [ "$col" -gt 1 ]; then
                    printf '\e[%dC' "$((col - 1))" >&2
                fi
                
                # Print head if provided
                [ -n "$head_char" ] && printf '%s' "$head_char" >&2
                
                # Calculate how much tail fits before right edge
                local space_available=$((max_width - col - head_length + 1))
                local tail_length_to_print=$tail_right_length
                
                if [ "$space_available" -lt "$tail_right_length" ]; then
                    tail_length_to_print=$space_available
                fi
                
                # Print tail substring
                local tail_to_print="${tail_right:0:$tail_length_to_print}"
                printf '%s' "$tail_to_print" >&2
            fi
            
            # Update position after drawing
            col=$((col + direction))
        fi
        
        # Pass through the line to stdout
        echo "$line"
    done
    
    # Restore cursor and clear line
    printf '\e[?25h\r%*s\r' "$max_width" "" >&2
}

#bounce 45 " " " "  "<<<<<" ">>>>>"
#bounce 45 " " "O"  "Oooooooooo......." ".......oooooooooO"
os=$(printf "%b" '\u203E')
#bounce 45 "_" ""  "/$os\\" "/$os\\"
#bounce 45 "_" ""  "/$os\\" "/$os\\"
#bounce 80 "." "" "/$os\\" "/$os\\"
#dots 1000
counter
printf '\n' >&2
