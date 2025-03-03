# System Backup Scripts

A collection of bash scripts for creating comprehensive system backups for personal use. These scripts create detailed system information reports and backup critical system directories while excluding unnecessary cache and temporary files. Currently working on a windows script, with plans to do others in the future.

## Features

- Creates timestamped backups with detailed system information
- Generates markdown-formatted system reports including:
  - System information
  - Disk usage
  - Installed packages
  - Running services
  - Docker images (if applicable)
- Maintains a specified number of recent backups
- Includes error handling and cleanup procedures
- Provides detailed logging of the backup process

## Prerequisites

- Root access
- rsync
- External backup drive mounted and accessible
- Sufficient space on backup drive

## Usage

1. Clone the repository:
```bash
git clone https://github.com/yourusername/system-backup-scripts
```

2. Configure the backup location in the script:
```bash
BACKUP_DIR="/path/to/backup/location"
MAX_BACKUPS=3  # Number of backups to retain
```

3. Run the script with sudo:
```bash
sudo ./backup-system.sh
```

## Backup Contents

The script backs up:
- User home directory
- System configuration (/etc)
- Local installations (/usr/local)
- Systemd configurations
- Docker data (if applicable)

While excluding:
- Temporary directories
- Cache files
- Package manager caches
- Virtual filesystems
- Build directories

## Output Structure

```
backup-directory/
└── YYYY-MM-DD_HH-MM-SS/
    ├── system/
    │   └── [backup files]
    ├── system-info.md
    └── backup.log
```

## Customization

Each script can be customized for specific systems by modifying:
- Backup locations
- Include/exclude patterns
- Number of backups to retain
- System information collection

## License

GPL-3.0 License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Disclaimer

Always test backup scripts in a safe environment before using them on production systems.