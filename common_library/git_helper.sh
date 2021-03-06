#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : git_helper.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-01-08>
## Updated: Time-stamp: <2016-10-27 16:45:07>
##-------------------------------------------------------------------
function current_git_sha() {
    set -e
    local src_dir=${1?}
    cd "$src_dir"
    sha=$(git log -n 1 | head -n 1 | grep commit | head -n 1 | awk -F' ' '{print $2}')
    echo "$sha"
}

function git_log() {
    local code_dir=${1?}
    local tail_count=${2:-"10"}
    cd "$code_dir"
    command="git log -n $tail_count --pretty=format:\"%h - %an, %ar : %s\""
    echo -e "\n\nShow latest git commits: $command"
    eval "$command"
}

function parse_git_repo() {
    # git@github.com:MYORG/mydevops.wiki.git -> mdmdevops.wiki
    # git@bitbucket.org:MYORG/mydevops.git/wiki -> wiki
    # git@github.com:MYORG/mydevops.git -> mydevops
    local git_url=${1?}
    local repo_name=""

    if [[ "$git_url" = *:*/*.*.git ]]; then
        if [[ "$git_url" = https:*.* ]]; then
            # Sample: https://github.com/DennyZhang/devops_public.git
            repo_name=$(echo "${git_url%.git}" | awk -F'/' '{print $5}')
        else
            # Sample: git@github.com:DennyZhang/devops_public.git
            repo_name=$(echo "${git_url%.git}" | awk -F'/' '{print $2}')
        fi
    else
        if [[ "$git_url" = *:*/*.git/* ]]; then
            repo_name=$(echo "${git_url}" | awk -F'/' '{print $3}')
        else
            if [[ "$git_url" = *:*/*.git ]]; then
                repo_name=$(echo "${git_url%.git}" | awk -F'/' '{print $2}')
            fi
        fi
    fi
    echo "$repo_name"
}

function git_update_code() {
    set -e
    local branch_name=${1?}
    local working_dir=${2?}
    local git_repo_url=${3?}

    git_repo=$(parse_git_repo "$git_repo_url")
    local code_dir="$working_dir/$branch_name/$git_repo"
    echo "Git update code for $git_repo_url to $code_dir"
    # checkout code, if absent
    if [ ! -d "$working_dir/$branch_name/$git_repo" ]; then
        mkdir -p "$working_dir/$branch_name"
        cd "$working_dir/$branch_name"
        git clone --depth 1 "$git_repo_url" --branch "$branch_name" --single-branch
        cd "$code_dir"
        git config user.email "jenkins@devops.com"
        git config user.name "Jenkins Auto"
    else
        cd "$code_dir"
        git ls-remote --tags
        git config remote.origin.url "$git_repo_url"
        git config user.email "jenkins@devops.com"
        git config user.name "Jenkins Auto"
        # add retry for network turbulence
        git pull origin "$branch_name" || (sleep 2 && git pull origin "$branch_name")
    fi

    cd "$code_dir"
    git checkout "$branch_name"
    # git reset --hard
}
######################################################################
## File : git_helper.sh ends
