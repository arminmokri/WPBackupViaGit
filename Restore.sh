#!/bin/bash

gitCheckConfig() { # git_url, git_user_email, git_user_name, git_username, git_password, git_repo_name, dir_path
    local git_url=$1
    local git_user_email=$2
    local git_user_name=$3
    local git_username=$4
    local git_password=$5
    local git_repo_name=$6
    local dir_path=$7
    local git_credential="https://${git_username}:${git_password}@${git_url}"
    local res_status=1

    # check user.email
    local res_str1=$( \
        cd $dir_path >/dev/null 2>&1 && \
        git config --local --list | grep "user.email" | cut -d '=' -f 2 | tr -d '\n' 2>/dev/null && \
        cd - >/dev/null 2>&1 \
    )
    local res_status1=$?

    local res_status2=0
    if [ $res_status1 -ne 0 ] || [ "${res_str1}" != "${git_user_email}" ]; then
        local res_str2=$( \
            cd $dir_path >/dev/null 2>&1 && \
            git config --local user.email "${git_user_email}" >/dev/null 2>&1 && \
            cd - >/dev/null 2>&1 \
        )
        local res_status2=$?
    fi

    # check user.name
    local res_str3=$( \
        cd $dir_path >/dev/null 2>&1 && \
        git config --local --list | grep "user.name" | cut -d '=' -f 2 | tr -d '\n' 2>/dev/null && \
        cd - >/dev/null 2>&1 \
    )
    local res_status3=$?

    local res_status4=0
    if [ $res_status3 -ne 0 ] || [ "${res_str3}" != "${git_user_name}" ]; then
        local res_str4=$( \
            cd $dir_path >/dev/null 2>&1 && \
            git config --local user.name "${git_user_name}" >/dev/null 2>&1 && \
            cd - >/dev/null 2>&1 \
        )
        local res_status4=$?
    fi

    # check credential.helper
    local res_str5=$( \
        cd $dir_path >/dev/null 2>&1 && \
        git config --local --list | grep "credential.helper" | cut -d '=' -f 2 | tr -d '\n' 2>/dev/null && \
        cd - >/dev/null 2>&1 \
    )
    local res_status5=$?

    local res_status6=0
    if [ $res_status5 -ne 0 ] || [ "$res_str5" != "store" ]; then
        local res_str6=$( \
            cd $dir_path >/dev/null 2>&1 && \
            git config --local credential.helper store >/dev/null 2>&1 && \
            cd - >/dev/null 2>&1 \
        )
        local res_status6=$?
    fi

    # check ~/.git-credentials
    if [ -f ~/.git-credentials ]; then
        local res_str7=$(cat ~/.git-credentials | tr -d '\n')
        local res_status7=$?
    else
        local res_str7=""
    fi

    local res_status8=0
    if [ "$res_str7" != "${git_credential}" ]; then
        local res_str8=$(echo "${git_credential}" > ~/.git-credentials)
        local res_status8=$?
    fi

    if [ $res_status2 -eq 0 ] && [ $res_status4 -eq 0 ] && [ $res_status6 -eq 0 ] && [ $res_status8 -eq 0 ]; then
        res_status=0
    fi
    echo -n "${res_status}"
}

# parse Args
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --action)
            # show-restore-points / restore
            action="$2"
            shift # past argument
            shift # past value
            ;;
        --latest)
            latest="yes"
            shift # past argument
            ;;
        --restore-point-type)
            # manual / index / commit-id
            restorePointType="$2"
            shift # past argument
            shift # past value
            ;;
        --restore-point)
            restorePoint="$2"
            shift # past argument
            shift # past value
            ;;
        -*|--*)
            echo "Unknown option $1"
            action=""
            break
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# path
this_file_path=$(eval "realpath $0")
this_dir_path=$(eval "dirname $this_file_path")

exit_code=0

source "${this_dir_path}/Backup.config"

git_url=$GitURL
git_user_email=$GitUserEmail
git_user_name=$GitUserName
git_username=${Git[0]}
git_password=${Git[1]}
git_repo_name=${Git[2]}

if [[ $action == "show-restore-points" ]]; then
    # check git config
    res_gitcheckconfig=$(gitCheckConfig "${git_url}" "${git_user_email}" "${git_user_name}" "${git_username}" "${git_password}" "${git_repo_name}" "${this_dir_path}")
    
    # git fetch new commits
    res_str_fetch=$( \
        cd $this_dir_path >/dev/null 2>&1 && \
        git fetch origin main >/dev/null 2>&1 && \
        cd - >/dev/null 2>&1 \
    )
    res_status_fetch=$?
    if  [ $res_status_fetch -eq 0 ]; then
        echo "fetch restore points from git repo '${git_repo_name}' successfully completed."
    else
        exit_code=1
        echo "fetch restore points from git repo '${git_repo_name}' failed."
    fi

    # show all commits
    res_str_log=$(git log --all --date=format:'%Y-%m-%d %H:%M:%S' --pretty="%ad     %H     %s" | awk '{print NR  ")     " $s}')
    echo "Index  Date       Time         Commit ID                                    Commit Message"
    echo "$res_str_log"
elif [[ $action == "restore" ]]; then

    commit_id=""

    # check git config
    res_gitcheckconfig=$(gitCheckConfig "${git_url}" "${git_user_email}" "${git_user_name}" "${git_username}" "${git_password}" "${git_repo_name}" "${this_dir_path}")
    
    # git fetch new commits
    res_str_fetch=$( \
        cd $this_dir_path >/dev/null 2>&1 && \
        git fetch origin main >/dev/null 2>&1 && \
        cd - >/dev/null 2>&1 \
    )
    res_status_fetch=$?
    if  [ $res_status_fetch -eq 0 ]; then
        echo "fetch restore points from git repo '${git_repo_name}' successfully completed."
    else
        exit_code=1
        echo "fetch restore points from git repo '${git_repo_name}' failed."
    fi

    # fill params for latest condition
    if [[ $latest == "yes" ]]; then
        restorePointType="index"
        restorePoint=1
    fi

    # set commit-id for restore point type index/commit-id
    if [[ $restorePointType == "index" ]]; then
        commit_id=$(git log --all --date=format:'%Y-%m-%d %H:%M:%S' --pretty="%H" | awk "NR == ${restorePoint} {print; exit}")
    elif [[ $restorePointType == "commit-id" ]]; then
        commit_id=$restorePoint
    fi

    # Remove Files
    if [ $exit_code -eq 0 ]; then
        for ((i=0; i<${#Dir[@]}; i+=3)); do
            # vars
            dir_path=${Dir[$i]}
            dir_path_type=${Dir[$i+1]} # relative / absolute
            dir_backup_type=${Dir[$i+2]} # copy / move
            dir_abs_path=""
            if [ "$dir_path_type" == "relative" ]; then
                dir_abs_path="${this_dir_path}/${dir_path}"
            elif [ "$dir_path_type" == "absolute" ]; then
                dir_abs_path="${dir_path}"
            fi
            dir_name=$(basename "${dir_abs_path}")

            # remove restore dir/file if exist
            if [ -e "${dir_abs_path}" ]; then
                rm -rf "${dir_abs_path}"
                echo "delete '${dir_abs_path}' for restore dir/file '${dir_path}' successfully completed."
            fi

            # sleep
            sleep 1
        done
    fi

    # git goto specific commit id
    if [[ $restorePointType == "index" ]] || [[ $restorePointType == "commit-id" ]]; then
        res_str_reset=$( \
            cd $this_dir_path >/dev/null 2>&1 && \
            git reset --hard "${commit_id}" >/dev/null 2>&1 && \
            git clean -d -f -x >/dev/null 2>&1 && \
            cd - >/dev/null 2>&1 \
        )
        res_status_reset=$?
        if  [ $res_status_reset -eq 0 ]; then
            echo "reset to restore point '${commit_id}' from git repo '${git_repo_name}' successfully completed."
        else
            exit_code=1
            echo "reset to restore point '${commit_id}' from git repo '${git_repo_name}' failed."
        fi
    fi

    # Database
    if [ $exit_code -eq 0 ]; then
        for ((i=0; i<${#Database[@]}; i+=3)); do
            # vars
            db_name=${Database[$i]}
            db_username=${Database[$i+1]}
            db_password=${Database[$i+2]}

            # do restore database
            res_str=$($this_dir_path/database_restore.sh --db-name "${db_name}" --db-username "${db_username}" --db-password "${db_password}" --dir-path "${this_dir_path}/${db_name}" --with-drop)
            res_status=$?
            if  [ $res_status -eq 0 ]; then
                echo "restore database '${db_name}' from '${this_dir_path}/${db_name}' successfully completed."
            else
                exit_code=1
                echo "restore database '${db_name}' failed."
                break
            fi

            # sleep
            sleep 1
        done
    fi

    # Restore Files
    if [ $exit_code -eq 0 ]; then
        for ((i=0; i<${#Dir[@]}; i+=3)); do
            # vars
            dir_path=${Dir[$i]}
            dir_path_type=${Dir[$i+1]} # relative / absolute
            dir_backup_type=${Dir[$i+2]} # copy / move
            dir_abs_path=""
            if [ "$dir_path_type" == "relative" ]; then
                dir_abs_path="${this_dir_path}/${dir_path}"
            elif [ "$dir_path_type" == "absolute" ]; then
                dir_abs_path="${dir_path}"
            fi
            dir_name=$(basename "${dir_abs_path}")

            # do restore dir/file
            if [ -e "${this_dir_path}/${dir_name}" ]; then
                if [ "$dir_backup_type" == "copy" ]; then
                    res_str=$(cp -r "${this_dir_path}/${dir_name}" "${dir_abs_path}")
                    res_status=$?
                    if  [ $res_status -eq 0 ]; then
                        echo "restore dir/file '${dir_path}' copy to '${dir_abs_path}' successfully completed."
                    else
                        exit_code=1
                        echo "restore dir/file '${dir_path}' copy to '${dir_abs_path}' failed."
                        break
                    fi
                elif [ "$dir_backup_type" == "move" ]; then
                    res_str=$(mv "${this_dir_path}/${dir_name}" "${dir_abs_path}")
                    res_status=$?
                    if  [ $res_status -eq 0 ]; then
                        echo "restore dir/file '${dir_path}' move to '${dir_abs_path}' successfully completed."
                    else
                        exit_code=1
                        echo "restore dir/file '${dir_path}' move to '${dir_abs_path}' failed."
                        break
                    fi
                fi
            else
                exit_code=1
                echo "restore dir/file '${dir_path}' failed, does not exist."
                break
            fi

            # sleep
            sleep 1
        done
    fi

else
    echo "Invalid Parameter"
    exit_code=${errorCode[invalidParameter]}
fi

exit $exit_code
