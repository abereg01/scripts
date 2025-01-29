import requests
import curses
import subprocess
import time
import urllib3
from pathlib import Path
import json

# Suppress InsecureRequestWarning
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
PORTAINER_URL = "https://172.20.0.21:9443/api"
API_KEY = "ptr_82MqBRFEFfNc7/GG1kMHgVW91CH7q5vcKXVIQSGZ6+8="
HEADERS = {"X-API-Key": API_KEY}

# Theme configuration
THEME_PATH = Path("~/.config/kitty/theme.conf").expanduser()

def load_theme():
    try:
        with open(THEME_PATH, "r") as file:
            colors = {}
            for line in file:
                if line.strip() and not line.startswith("#"):
                    key, value = line.split()
                    colors[key] = value
            return colors
    except FileNotFoundError:
        return {}

theme_colors = load_theme()
def get_color(key, default):
    return theme_colors.get(key, default)

# Fetch container data
def fetch_containers():
    try:
        response = requests.get(f"{PORTAINER_URL}/endpoints", headers=HEADERS, verify=False)
        response.raise_for_status()
        endpoints = response.json()

        containers = []
        for endpoint in endpoints:
            endpoint_id = endpoint["Id"]
            endpoint_name = endpoint["Name"]
            container_response = requests.get(
                f"{PORTAINER_URL}/endpoints/{endpoint_id}/docker/containers/json",
                headers=HEADERS,
                verify=False
            )
            container_response.raise_for_status()
            for container in container_response.json():
                containers.append({"endpoint": endpoint_name, **container})

        return containers
    except requests.exceptions.RequestException as e:
        return [{"error": str(e)}]

# Display containers table
def display_containers(stdscr, containers, selected_index):
    stdscr.clear()
    stdscr.addstr(0, 0, "Docker Containers Overview", curses.color_pair(2) | curses.A_BOLD)

    headers = ["Endpoint", "Container ID", "Name", "State", "Status"]
    stdscr.addstr(2, 0, " | ".join(headers), curses.color_pair(3))

    for index, container in enumerate(containers):
        if "error" in container:
            stdscr.addstr(4, 0, container["error"], curses.color_pair(1) | curses.A_BOLD)
            continue

        endpoint = container.get("endpoint", "Unknown")
        container_id = container.get("Id", "")[:12]
        name = container.get("Names", [""])[0].strip("/")
        state = container.get("State", "")
        status = container.get("Status", "")

        style = curses.A_REVERSE if index == selected_index else curses.A_NORMAL
        stdscr.addstr(4 + index, 0, f"{endpoint:15} | {container_id:12} | {name:20} | {state:10} | {status:10}", style)

    stdscr.refresh()

# Actions menu
def display_action_menu(stdscr, actions, selected_index, container_name):
    stdscr.clear()
    stdscr.addstr(0, 0, f"Actions for {container_name}", curses.color_pair(2) | curses.A_BOLD)

    for index, action in enumerate(actions):
        style = curses.A_REVERSE if index == selected_index else curses.A_NORMAL
        stdscr.addstr(2 + index, 0, action, style)

    stdscr.refresh()

# Handle actions
def handle_action(action, container):
    if action == "Start":
        requests.post(
            f"{PORTAINER_URL}/endpoints/1/docker/containers/{container['Id']}/start",
            headers=HEADERS, verify=False
        )
    elif action == "Stop":
        requests.post(
            f"{PORTAINER_URL}/endpoints/1/docker/containers/{container['Id']}/stop",
            headers=HEADERS, verify=False
        )
    elif action == "Restart":
        requests.post(
            f"{PORTAINER_URL}/endpoints/1/docker/containers/{container['Id']}/restart",
            headers=HEADERS, verify=False
        )
    elif action == "Enter":
        subprocess.run(["docker", "exec", "-it", container['Id'][:12], "/bin/sh"])

# Main application loop
def main(stdscr):
    curses.start_color()
    curses.init_pair(1, curses.COLOR_RED, curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)
    curses.init_pair(3, curses.COLOR_CYAN, curses.COLOR_BLACK)

    stdscr.nodelay(1)
    curses.curs_set(0)

    selected_index = 0
    current_menu = "containers"
    actions = ["Start", "Stop", "Restart", "Enter", "Back"]

    while True:
        containers = fetch_containers()

        if current_menu == "containers":
            display_containers(stdscr, containers, selected_index)
        elif current_menu == "actions":
            display_action_menu(stdscr, actions, selected_index, containers[selected_index]["Names"][0].strip("/"))

        try:
            key = stdscr.getch()
            if key == curses.KEY_DOWN:
                selected_index += 1
            elif key == curses.KEY_UP:
                selected_index -= 1
            elif key == curses.KEY_ENTER or key in [10, 13]:
                if current_menu == "containers":
                    current_menu = "actions"
                elif current_menu == "actions":
                    action = actions[selected_index % len(actions)]
                    handle_action(action, containers[selected_index % len(containers)])
                    if action == "Back":
                        current_menu = "containers"
            elif key == 27:  # Escape key
                if current_menu == "actions":
                    current_menu = "containers"
        except KeyboardInterrupt:
            break

if __name__ == "__main__":
    curses.wrapper(main)
