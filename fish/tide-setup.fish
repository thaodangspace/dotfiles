#!/usr/bin/env fish
#
# Tide stores its configuration in fish *universal* variables
# (~/.config/fish/fish_variables), which is machine state and is
# deliberately not tracked by stow. Run this on a new machine to
# reproduce the prompt without walking the interactive wizard.
#
#   fish fish/tide-setup.fish
#
# To change the look interactively instead, run: tide configure

tide configure --auto \
    --style=Lean \
    --prompt_colors='True color' \
    --show_time=No \
    --lean_prompt_height='Two lines' \
    --prompt_connection=Disconnected \
    --prompt_connection_andor_frame_color=Lightest \
    --prompt_spacing=Sparse \
    --icons='Many icons' \
    --transient=No
