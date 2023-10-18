## 2023.10.18 Support for Saving and Loading Configurations
- Upon software startup, check if the config_para.json file exists. If not, create a new one. The saved contents include figure position, ripple_noise, and select_folder.
- Before software shutdown, save the current config settings to the file.