# My Personal Dotfiles

This repository contains my personal dotfiles and configuration files for various tools and applications I use on a daily basis. These configurations are tailored to my workflow and preferences, but feel free to use them as inspiration for your own setup.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/muhamadgameel/dotfiles.git
cd dotfiles

# Run the setup script
./setup.sh
```

## 🔧 Command Line Options

| Option               | Description                                    |
| -------------------- | ---------------------------------------------- |
| `-h, --help`         | Show help message                              |
| `-a, --auto-confirm` | Auto-confirm all prompts                       |
| `-d, --dry-run`      | Show what would be done without making changes |

## 🔒 Safety Features

- **Dry Run Mode**: Preview changes before applying
- **Validation**: Checks for required dependencies and valid configurations
- **Error Handling**: Graceful failure with rollback options
- **Logging**: Comprehensive logging with rotation

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure scripts are executable

   ```bash
   chmod +x setup.sh scripts/setup/*.sh scripts/setup/macos/*.sh
   ```

2. **Homebrew Not Found**: The script will offer to install it automatically

3. **Stow Not Found**: Install via Homebrew or manually

   ```bash
   brew install stow
   ```

4. **Configuration Conflicts**: Use `--dry-run` to preview changes first

### Logs

Check the log files in the `logs/` directory for detailed information about the setup process.

## 🤝 Contributing

Feel free to fork this repository and customize it for your own needs. If you have improvements or suggestions, pull requests are welcome!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
