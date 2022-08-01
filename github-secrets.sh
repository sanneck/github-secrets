#!/bin/bash


die() {
    printf '%s\n' "$1" >&2
    exit 1
}

show_title(){
    echo '        _ _   _           _                                  _       '
    echo '   __ _(_) |_| |__  _   _| |__        ___  ___  ___ _ __ ___| |_ ___ '
    echo '  / _` | | __|  _ \| | | |  _ \ _____/ __|/ _ \/ __|  __/ _ \ __/ __|'
    echo ' | (_| | | |_| | | | |_| | |_) |_____\__ \  __/ (__| | |  __/ |_\__ \'
    echo '  \__, |_|\__|_| |_|\__,_|_.__/      |___/\___|\___|_|  \___|\__|___/'
    echo '  |___/                                                              '
    echo
}

show_help(){
    
    # Display Help
    echo
    echo "options:"
    echo "-u, --user            Clone all the github repositories from the specified user"
    echo "-o, --org             Clone all the github repositories from the specified organization"
    echo "-om, --orgmembers     Clone all the github repositories from the organization's members"
    echo "-h,-?,-help           Print help"
    echo
    echo "Examples:" 
    echo "  ./github-secrets -u sanneck"
    echo "  ./github-secrets -o github"

}

clone_repo(){

    repo=$1
    
    repo_url=$(echo $repo | awk -F '|' '{print $1}')
    is_fork=$(echo $repo | awk -F '|' '{print $2}')
    repo_name="${repo_url##*/}"
    if [ $is_fork = false ] && [ ! -d $repo_name ]; then
        git clone $repo_url
        echo "▼ Files deleted in $repo_name ▼" >> deleted.txt
        echo "▼ Commits in $repo_name ▼" >> commits.txt
        cd $repo_name
        git log --diff-filter=D --summary | grep delete | awk {'print $4'} >> ../deleted.txt
        git log --oneline >> ../commits.txt
        cd ..
    fi
}

clone_user_repos(){

    user=$1

    repos=$(curl https://api.github.com/users/$user/repos | jq '.[] | "\(.html_url)|\(.fork)"' | tr -d '"')
    mkdir -p $user && cd $user
    for repo in $repos
    do
        clone_repo $repo
    done
    cd ..
}

clone_org_repos(){

    user=$1

    repos=$(curl https://api.github.com/orgs/{$org}/repos | jq '.[] | "\(.html_url)|\(.fork)"' | tr -d '"')
    mkdir -p $org && cd $org
    for repo in $repos
    do
        clone_repo $repo
    done
    cd ..
}

clone_org_members_repos(){

    org=$1

    members=$(curl https://api.github.com/orgs/{$org}/members | jq '.[] | "\(.login)|\(.repos_url)"' | tr -d '"')
    mkdir -p $org && cd $org
    mkdir -p members && cd members
    for member in $members
    do
        member_username=$(echo $member | awk -F '|' '{print $1}')
        member_repos=$(echo $member | awk -F '|' '{print $2}')
        repos=$(curl {$member_repos} | jq '.[] | "\(.html_url)|\(.fork)"' | tr -d '"')
        mkdir -p $member_username && cd $member_username
        for repo in $repos
        do
            clone_repo $repo
        done
        cd ..
        [ -f "$member_username/deleted.txt" ] && cat "$member_username/deleted.txt" >> deleted.txt
        [ -f "$member_username/commits.txt" ] && cat "$member_username/commits.txt" >> commits.txt
    done
    cd ../..
}

run_clone_user_repos=0
run_clone_org_repos=0

while :; do
    case $1 in
        -h|-\?|--help)
            show_help # Display a usage synopsis.
            exit
            ;;
        -u|--user) # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                run_clone_user_repos=1
                user="$2"
                shift
            else
                die 'ERROR: "-u or --user" requires a non-empty option argument.'
            fi
            ;;
        -o|--org) # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                run_clone_org_repos=1
                org="$2"
                shift
            else
                die 'ERROR: "-o or --org" requires a non-empty option argument.'
            fi
            ;;
        -om|--orgmembers) # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                run_clone_org_members_repos=1
                orgmembers="$2"
                shift
            else
                die 'ERROR: "-om or --orgmembers" requires a non-empty option argument.'
            fi
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)  show_title # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

if [[ "${run_clone_user_repos}" -eq 1 ]] ; then
    clone_user_repos $user
fi

if [[ "${run_clone_org_repos}" -eq 1 ]] ; then
    clone_org_repos $org
fi

if [[ "${run_clone_org_members_repos}" -eq 1 ]] ; then
    clone_org_members_repos $orgmembers
fi
