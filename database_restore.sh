#!/bin/bash

restoreDatabaseSchema() { # db_name, db_username, db_password, dir_path
    local db_name=$1
    local db_username=$2
    local db_password=$3
    local dir_path=$4
    local res_status=1
    local res1_str=$(find "${dir_path}" -type f -name "database_*_schema.sql" | tail -n 1 | tr -d '\n' 2>/dev/null)
    local res1_status=$?
    if [ $res1_status -eq 0 ]; then
        local db_schema_path=$res1_str
        local res2_str=$(mysql -u "${db_username}" -p"${db_password}" "${db_name}" < "${db_schema_path}" 2>/dev/null)
        local res2_status=$?
    fi

    if [ $res1_status -eq 0 ] && [ $res2_status -eq 0 ]; then
        res_status=0
    fi
    echo -n "${res_status}"
}

restoreDatabaseTables() { # db_name, db_username, db_password, dir_path
    local db_name=$1
    local db_username=$2
    local db_password=$3
    local dir_path=$4
    local res_status=1
    local res1_str=$(find "${dir_path}" -type f -name 'table_*.sql' ! -name 'database_*_schema.sql' 2>/dev/null)
    local res1_status=$?
    local res2_str=""
    local res2_status=0
    if [ $res1_status -eq 0 ]; then
        local files=$res1_str
        for file in $files;
        do
            local res2_str=$(mysql -u "${db_username}" -p"${db_password}" "${db_name}" < "${file}" 2>/dev/null)
            local res2_status=$?
            if [ $res2_status -ne 0 ]; then
                break;
            fi
        done;
    fi

    if [ $res1_status -eq 0 ] && [ $res2_status -eq 0 ]; then
        res_status=0
    fi
    echo -n "${res_status}"
}

dropDatabaseTables() { # db_name, db_username, db_password
    local db_name=$1
    local db_username=$2
    local db_password=$3
    local res_status=1
    res1_str=$(mysql -u "${db_username}" -p"${db_password}" -N -B -e "SHOW TABLES FROM ${db_name};" 2>/dev/null)
    res1_status=$?
    local res2_str=""
    local res2_status=0
    if [ $res1_status -eq 0 ]; then
        local tables=$res1_str;
        for table in $tables;
        do
            local res2_str=$(mysql -u "${db_username}" -p"${db_password}" "${db_name}" -B -e "SET FOREIGN_KEY_CHECKS = 0; DROP TABLE IF EXISTS ${table}; SET FOREIGN_KEY_CHECKS = 1;" 2>/dev/null)
            local res2_status=$?
            if [ $res2_status -ne 0 ]; then
                break;
            fi
        done;
    fi

    if [ $res1_status -eq 0 ] && [ $res2_status -eq 0 ]; then
        res_status=0
    fi
    echo -n "${res_status}"
}

# parse Args
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --db-username)
            dbUsername="$2"
            shift # past argument
            shift # past value
            ;;
        --db-password)
            dbPassword="$2"
            shift # past argument
            shift # past value
            ;;
        --db-name)
            dbName="$2"
            shift # past argument
            shift # past value
            ;;
        --dir-path)
            dirPath="$2"
            shift # past argument
            shift # past value
            ;;
        --with-drop)
            withDrop="yes"
            shift # past argument
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

#
exit_code=0

if [ "$withDrop" == "yes" ]; then
    res_drop=$(dropDatabaseTables "${dbName}" "${dbUsername}" "${dbPassword}")
    if [ $res_drop -eq 0 ]; then
        res_db=$(restoreDatabaseSchema "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")
        res_tbs=$(restoreDatabaseTables "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")
    fi

    if [ $res_drop -ne 0 ] || [ $res_db -ne 0 ] || [ $res_tbs -ne 0 ]; then
        exit_code=1
    fi
else
    res_db=$(restoreDatabaseSchema "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")
    res_tbs=$(restoreDatabaseTables "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")

    if [ $res_db -ne 0 ] || [ $res_tbs -ne 0 ]; then
        exit_code=1
    fi
fi

exit $exit_code
