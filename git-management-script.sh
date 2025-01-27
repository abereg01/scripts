#!/bin/bash

# Function to handle personal repositories
handle_personal() {
    echo "Choose a personal repository:"
    select repo in "dotfiles" "scripts" "wallpapers"; do
        case $repo in
            dotfiles)
                cd "$HOME/dotfiles/" || exit
                break
                ;;
            scripts)
                cd "$HOME/lib/scripts/" || exit
                break
                ;;
            wallpapers)
                cd "$HOME/lib/images/wallpapers/" || exit
                break
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
    done
}

# Function to handle work repository
handle_work() {
    cd "$HOME/digit/script" || exit
}

# Main script
echo "Choose repository type:"
select type in "personal" "work"; do
    case $type in
        personal)
            handle_personal
            break
            ;;
        work)
            handle_work
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

# Git operations
git add .

echo "Enter commit message:"
read -r commit_message

git commit -m "$commit_message"
git push

echo "Git operations completed successfully."
