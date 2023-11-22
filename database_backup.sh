#!/bin/bash

dumpDatabaseSchema() { # db_name, db_username, db_password, dir_path
    local db_name=$1
    local db_username=$2
    local db_password=$3
    local dir_path=$4
    local db_schema_path="${dir_path}/database_${db_name}_schema.sql"
    local res_status=1
    local res1_str=$(mysqldump -u "${db_username}" -p"${db_password}" "${db_name}" --no-data --skip-add-drop-table 1> "${db_schema_path}" 2>/dev/null)
    local res1_status=$?
    local res2_str=$(sed -i 's/CREATE TABLE/CREATE TABLE IF NOT EXISTS/g' "${db_schema_path}")
    local res2_status=$?
    local res3_str=$(sed -i 's/ AUTO_INCREMENT=[0-9]*//g' "${db_schema_path}")
    local res3_status=$?

    if [ $res1_status -eq 0 ] && [ $res2_status -eq 0 ] && [ $res3_status -eq 0 ]; then
        res_status=0
    fi
    echo -n "${res_status}"
}

dumpDatabaseTables() { # db_name, db_username, db_password, dir_path
    local db_name=$1
    local db_username=$2
    local db_password=$3
    local dir_path=$4
    local res_status=1
    local res1_str=$(mysql -u "${db_username}" -p"${db_password}" -N -B -e "show tables from ${db_name}" 2>/dev/null)
    local res1_status=$?
    local res2_str=""
    local res2_status=0
    if [ $res1_status -eq 0 ]; then
        local tables=$res1_str;
        for table in $tables;
        do
            local table_dump_path="${dir_path}/table_${table}.sql"
            local res2_str=$(mysqldump -u "${db_username}" -p"${db_password}" "${db_name}" "${table}" --no-create-info 1> "${table_dump_path}" 2>/dev/null)
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
        --db-name)
            dbName="$2"
            shift # past argument
            shift # past value
            ;;
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
        --dir-path)
            dirPath="$2"
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

#
exit_code=0

res_db=$(dumpDatabaseSchema "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")
res_tbs=$(dumpDatabaseTables "${dbName}" "${dbUsername}" "${dbPassword}" "${dirPath}")

if [ $res_db -ne 0 ] || [ $res_tbs -ne 0 ]; then
    exit_code=1
fi

exit $exit_code
