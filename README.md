# WPBackupViaGit
**WPBackupViaGit** is for making backup and restore on a git account with any frequency.

## Features
- Backup from databases
- Backup from files and dirs
- Sync backup point with git account
- Restore backup point from git account
- common use is for WordPress but it could be able for any other things that need a backup process

## Install and Run the Project
### Backup
1. Create a repository on git for WordPress, website, etc
2. Connect to the shell via SSH, cpanel terminal, etc
3. Clone your git repository
    - for example `git clone "your_repo_url"`
4. run `git clone https://github.com/arminmokri/WPBackupViaGit.git`
5. run `cd WPBackupViaGit`
6. Copy **WPBackupViaGit** files to your repository directory
    - for example `cp Backup.sh Backup.config database_backup.sh database_restore.sh ../your_repo_dir`
7. run `cd ..`
8. Open **Backup.config** file in vim or nano or vi or etc
    - for example `vi your_repo_dir/Backup.config`
9. Fill your data with the structure of examples
10. At last set a cron job with any period (hourly, daily, weekly) for your backup process and call **Backup.sh** script file
    - for example `/absolute_path/your_repo_dir/Backup.sh &> /absolute_path/your_repo_dir/Backup.log`

### Restore
1. Clone your git repository
    - for example `git clone "your_repo_url"`
2. run `./your_repo_dir/Restore.sh --action show-restore-points` to see backup/restore points
   - as a result, you will see this
```
fetch restore points from git repo 'your_repo_name' successfully completed.
Index  Date       Time         Commit ID                                    Commit Message
1)     2023-12-09 03:00:03     d36d58ced5a6d9ad3f63557eb2b5554179cc087c     backup point 2023/12/09 03:00:06
2)     2023-12-08 03:00:02     c5e54499c78d3794e4fa26b68d2db8bd62cfc0b2     backup point 2023/12/08 03:00:05
...
```
4. find your restore point from the list.
5. for restoration we have some commands that I make examples and explanation
   - restore to the lastest commit `./your_repo_dir/Restore.sh --action restore --latest`
   - restore based on the commit id `./your_repo_dir/Restore.sh --action restore --restore-point-type commit-id --restore-point c5e54499c78d3794e4fa26b68d2db8bd62cfc0b2`
   - restore based on the row index `./your_repo_dir/Restore.sh --action restore --restore-point-type index --restore-point 2`
   - restore based on the current state of files and ignore backup/restore points `./your_repo_dir/Restore.sh --action restore --restore-point-type manual`
6. wait until the restore process is finished.

## Some Points
- you also can create a token for access to your repository from this menu `profile -> settings -> Developer Settings -> personal access tokens` on GitHub
