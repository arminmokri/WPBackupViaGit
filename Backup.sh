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

# Database
if [ $exit_code -eq 0 ]; then
    for ((i=0; i<${#Database[@]}; i+=3)); do
        # vars
        db_name=${Database[$i]}
        db_username=${Database[$i+1]}
        db_password=${Database[$i+2]}
        
        # remove last database backup dir if exist
        if [ -d "${this_dir_path}/${db_name}" ]; then
            rm -rf "$this_dir_path/$db_name"
            echo "delete '${this_dir_path}/${db_name}' for backup database '${db_name}' successfully completed."
        fi

        # make new dir for database files
        mkdir "${this_dir_path}/${db_name}"
        echo "make dir '${this_dir_path}/${db_name}' for backup database '${db_name}' successfully completed."

        # do backup database
        res_str=$($this_dir_path/database_backup.sh --db-name "${db_name}" --db-username "${db_username}" --db-password "${db_password}" --dir-path "${this_dir_path}/${db_name}")
        res_status=$?
        if  [ $res_status -eq 0 ]; then
            echo "backup database '${db_name}' in '${this_dir_path}/${db_name}' successfully completed."
        else
            exit_code=1
            echo "backup database '${db_name}' failed."
            break
        fi

        # sleep
        sleep 1
    done
fi

# File
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

        # remove last dir/file backup if exist
        if [ -e "${this_dir_path}/${dir_name}" ]; then
            rm -rf "${this_dir_path}/${dir_name}"
            echo "delete '${this_dir_path}/${dir_name}' for backup dir/file '${dir_path}' successfully completed."
        fi

        # do backup dir/file
        if [ -e "${dir_abs_path}" ]; then
            if [ "$dir_backup_type" == "copy" ]; then
                res_str=$(cp -r "${dir_abs_path}" "${this_dir_path}/${dir_name}")
                res_status=$?
                if  [ $res_status -eq 0 ]; then
                echo "backup dir/file '${dir_path}' copy to '${this_dir_path}/${dir_name}' successfully completed."
                else
                exit_code=1
                echo "backup dir/file '${dir_path}' copy to '${this_dir_path}/${dir_name}' failed."
                break
                fi
            elif [ "$dir_backup_type" == "move" ]; then
                res_str=$(mv "${dir_abs_path}" "${this_dir_path}/${dir_name}")
                res_status=$?
                if  [ $res_status -eq 0 ]; then
                echo "backup dir/file '${dir_path}' move to '${this_dir_path}/${dir_name}' successfully completed."
                else
                exit_code=1
                echo "backup dir/file '${dir_path}' move to '${this_dir_path}/${dir_name}' failed."
                rm -rf "${this_dir_path}/${dir_name}"
                echo "delete '${this_dir_path}/${dir_name}' for cancel revert move dir/file '${dir_path}' successfully completed."
                break
                fi
            fi
        else
            exit_code=1
            echo "backup dir/file '${dir_path}' failed, does not exist."
            break
        fi

        # sleep
        sleep 1
    done
fi


if [ $exit_code -eq 0 ]; then
    # sleep
    sleep 3

    # check git config
    res_gitcheckconfig=$(gitCheckConfig "${git_url}" "${git_user_email}" "${git_user_name}" "${git_username}" "${git_password}" "${git_repo_name}" "${this_dir_path}")

    # git add commit push
    datetime_now=$(date '+%Y/%m/%d %H:%M:%S' | tr -d '\n' 2>/dev/null)
    res_str=$( \
        cd $this_dir_path >/dev/null 2>&1 && \
        git add -A >/dev/null 2>&1 && \
        git commit -m "backup point ${datetime_now}" >/dev/null 2>&1 && \
        git push origin HEAD:main >/dev/null 2>&1 && \
        cd - >/dev/null 2>&1 \
    )
    res_status=$?
    if  [ $res_status -eq 0 ]; then
        echo "add/commit/push backup to git repo '${git_repo_name}' at '${datetime_now}' successfully completed."
    else
        exit_code=1
        echo "add/commit/push backup to git repo '${git_repo_name}' at '${datetime_now}' failed."
    fi
fi


# File
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

    # revert moved dir/file for backup
    if [ "$dir_backup_type" == "move" ]; then
        if [ -e "${this_dir_path}/${dir_name}" ]; then
            
            # remove
            if [ -e "${dir_abs_path}" ]; then
                rm -rf "${dir_abs_path}"
                echo "delete '${dir_abs_path}' for revert move dir/file '${dir_path}' successfully completed."
            fi

            res_str_backup=$(mv "${this_dir_path}/${dir_name}" "${dir_abs_path}")
            res_status_backup=$?
            if  [ $res_status_backup -eq 0 ]; then
                echo "revert move dir/file '${dir_path}' to '${this_dir_path}/${dir_name}' successfully completed."
            else
                exit_code=1
                echo "revert move dir/file '${dir_path}' to '${this_dir_path}/${dir_name}' failed."
            fi

        else
            exit_code=1
            echo "revert move dir/file '${dir_path}' to '${this_dir_path}/${dir_name}' failed, does not exist."
        fi
    fi
    
    # sleep
    sleep 1
done

exit $exit_code
