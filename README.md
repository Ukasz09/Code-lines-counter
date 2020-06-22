# :mag_right: Code lines counter [![License](https://img.shields.io/badge/licence-MIT-blue)](https://choosealicense.com/licenses/mit/) [![Contributions welcome](https://img.shields.io/badge/contributions-welcome-orange.svg)](https://github.com/Ukasz09/Code-lines-counter)

> Generate a summary report of written lines of code (Bash)

**code_lines_counter** is a simple tool used to generate report about written lines of code for given directory, with all sub-directories

## Examples

- **Counting lines**

| For actual directory | For given specific directory |
| -------- | ------- |
| ![](/doc/images/counter_norm.png) | ![](/doc/images/counter_specific.png) |

- **Supported languages**

![](/doc/images/extensions.png)

*You can add new extension / extensions with corresponding language_name if you need it ([MANUAL](https://github.com/Ukasz09/Code-lines-counter/wiki/MANUAL-PAGE))*

- **Excluded files / directories from counting**

![](/doc/images/ignored.png)


*Yoou can add extra ignored files / directories if you need it ([MANUAL](https://github.com/Ukasz09/Code-lines-counter/wiki/MANUAL-PAGE))*

## Distinguishing features

- `Jupyter Notebook` support (correct counting lines of code inside `.ipynb` files)
- Automatically excluding all files / localizations from `.gitignore` files found inside searched directories
- Possibility of adding / removing additional localizations / files to exclude from counting
- Possibility of adding / removing any file extensions with associated languages / names

## Manual Page

You can find full manual page ([here](https://github.com/Ukasz09/Code-lines-counter/wiki))<br/> or just type in terminal any of this: <br/>

```bash
    info code_lines_counter 
```
```bash
    man code_lines_counter 
```
```bash
    code_lines_counter --help 
```
```bash
    code_lines_counter -h
```

## Setup

This tool use ([fd-find app](https://github.com/sharkdp/fd)) shell app. First of all, you need to make sure that you have installed it.
([Original fd-find installation steps](https://github.com/sharkdp/fd#installation)) - In most cases it can by done by typing:

```bash
    sudo apt install fd-find
```
After that you are ready to install `code_lines_counter`:

```bash
    git clone https://github.com/Ukasz09/Code-lines-counter.git
    cd Code-lines-counter/
    sudo make install
```

## How to use it?

Go to directory in which you want to count lines of code and simply type:
```bash
    code_lines_counter
```

You can also specify directory by typing:

```bash
    code_lines_counter -d path/to/parent/directory/
```
or
```bash
    code_lines_counter --dir path/to/parent/directory/
```

All others available flags you can find in ([manual](https://github.com/Ukasz09/Code-lines-counter#manual-page))
___
## 📫 Contact 
Created by <br/>
<a href="https://github.com/Ukasz09" target="_blank"><img src="https://avatars0.githubusercontent.com/u/44710226?s=460&v=4"  width="100px;"></a>
<br/> gajerski.lukasz@gmail.com - feel free to contact me! ✊


