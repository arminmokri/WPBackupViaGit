# WPBackupViaGit
**WPBackupViaGit** is for making backup and restore on a git account by any frequency.

## Features
- Backup from databases
- Backup from files and dirs
- Sync backup point with git account
- Restore backup point from git account
- common use is for WordPress but it could be able for any other things that need a backup process

## Install and Run the Project
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

## Some Points
- you also can create a token for access to your repository from this menu `profile -> settings -> Developer Settings -> personal access tokens` on GitHub
