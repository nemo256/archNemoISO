# ArchNemo Installer Script

![Image](nvimForTheWin.png)

This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a window tiling manager (DWM), all the support packages (network, bluetooth, audio, etc.), along with all my preferred applications and utilities. The shell scripts in this repo allow the entire process to be automated.

---
## Create Arch ISO

Download ArchISO from <https://archlinux.org/download/> and put on a USB drive with [Etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/index.html), or [Rufus](https://rufus.ie/en/)

## Boot Arch ISO

From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://github.com/nemo256/archNemo
cd archNemo
./archnemo.sh
```

### System Description
This is a completely automated arch install of my dwm, st... setup on arch using all the packages I use on a daily basis. 

## Credits

- Big thank you to ChrisTitusTech and all contributors who made this possible: https://github.com/ChrisTitusTech/ArchTitus
- Original packages script was a post install cleanup script called ArchMatic located here: https://github.com/rickellis/ArchMatic
