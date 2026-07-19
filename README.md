<div align="center">
    <h1>【 Termux-Desktop-Awesome 】</h1>
    <h3></h3>
</div>

<div align="center"> 
  <a href="https://github.com/Keytaro2/Termux-Desktop-Awesome/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=git&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7"></a><br>
  <a href="https://github.com/Keytaro2/Termux-Desktop-Awesome/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=andela&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7"></a>
  <img alt="Repo Size" src="https://img.shields.io/github/repo-size/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=protondrive&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7&label=SIZE"><br>
  <a href="https://www.reddit.com/u/Vgloomy/s/nG9DCBad5p"><img alt="Reddit" src="https://img.shields.io/badge/reddit-10-7aa2f7?style=for-the-badge&logo=reddit&logoColor=c0caf5&labelColor=1E202B"></a>
</div>

<div align="center">
    <h2>• overview •</h2>
    <h3></h3>
</div>

> [!WARNING]
> You should back up your files before using this dotfile configuration.
>
> **IMPORTANT:** Be careful with these commands, as you could lose your progress, make sure to execute them correctly.
> 
>  It is important to have more than 5GB of space available, as this desktop setup is somewhat resource-heavy.

<details> 
  <summary>Termux Backups</summary>

  - **Compress data**:
  - termux-setup-storage
  - cd ..
  - tar -zcvf /sdcard/termux-backup.tar.gz home usr
   
  - **Decompress (extract) data**:
  - termux-setup-storage
  - cd ..
  - tar -zxf /sdcard/termux-backup.tar.gz --recursive-unlink --preserve-permissions
  
</details>

<details> 
  <summary>Notable Features</summary>
     
  - **Overview**: Shows open apps with live previews
  - **catppuccin mocha theme**: Choose your wallpaper with Ctrl + K, done, enjoy
  - **Transparent installation**: Every command is shown before it's run
</details>

<details> 
  <summary>Installation</summary>

   - **One-Line Installation**

```bash
apt update && apt upgrade -y && apt install git wget python python3 python-pip x11-repo -y && git clone https://github.com/Keytaro2/Termux-Desktop-Awesome.git && cd Termux-Desktop-Awesome && python3 install.py && ./startawesome_termux.sh
```


</details>

<details>
  <summary>Keyboard Shortcut</summary>

| Keys | Action |
| :-------------------: | :---------------------------------------------------------------: |
| `ctrl` + `w` | Close Windows. |
| `ctrl` + `Enter` | Open a terminal. |
| `ctrl` + `k` | Open the program to change the wallpaper. |
| `ctrl` + `n` | Close the program to change the wallpaper. |
| `alt` + `/` | Takes screenshot. |
| `ctrl` + `z`  | Toggle profiles. |
| `ctrl` + `x` | Go back profiles. |
| `ctrl` + `v` | Enabled or disable mouse mode. |
| `ctrl` + `g`  | Activate locked mode or deactivate unlocked mode. |
| `alt` + `r` | Restart awesomme. |
| `alt` + `q` | Quit awesomme. |
| `ctrl` + `d` | Run rofi. |
| `alt` + `d` | Eww close launcher. |
| `ctrl` + `left` | Move floating window a left. |
| `ctrl` + `down` | Move floating window a down |
| `ctrl` + `up` | Move floating window a up. |
| `ctrl` + `right` | Move floating window a right. |
| `alt` + `left` | Resize window a left. |
| `alt` + `down` | Resize window a down. |
| `alt` + `up` | Resize window a up. |
| `alt` + `right` | Resize window a right. |

---


</details>

<details>
    <summary>Reddit</summary>
        <a href="https://www.reddit.com/u/Vgloomy/s/yg8IJcRWab"> User link</a> | I hope this provides a friendlier environment for support  request/DM. For real issues, prefer GitHub

</details>
<details>
     <summary>Phantom Process Killer</summary>

***

## Phantom Process Killer

**NOTICE:**

**Termux may be unstable on Android 12+.** Android OS will kill any (phantom) processes greater than 32 (limit is for all apps combined) and also kill any processes using excessive CPU. You may get `[Process completed (signal 9) - press Enter]` message in the terminal without actually exiting the shell process yourself. Check the related issue [#2366](https://github.com/termux/termux-app/issues/2366), [issue tracker](https://issuetracker.google.com/u/1/issues/205156966), [gist with details](https://gist.github.com/agnostic-apollo/dc7e47991c512755ff26bd2d31e72ca8) and [this TLDR comment](https://github.com/termux/termux-app/issues/2366#issuecomment-1009269410) on how to disable trimming of phantom processes.

#### Deactivation Instructions (ADB):

- On an ADB console, paste the following commands on the following order:

```
adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
```
```
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```
```
adb shell settings put global settings_enable_monitor_phantom_procs false
```
- If it doesn't work on your phone,Reboot your phone.

#### Reboot Phone
```
adb reboot
```
### You Can Also Deative It With Termux.
```
pkg up -y;pkg i -y android-tools
```
- After installing the package,you must open Developer Options in order to use wireless ADB with Termux.

- Go to Settings, About Phone & Touch build-number for servial times.

- On Xiaomi Phones, Touch MIUI version servial times.

- After Opening Developer Options,Open wireless debugging & Split Screen.

- Then,Open Termux & Pair Device with paring code.

- You can also use two phones with a same wifi network.

- Write This ADB Command in termux

#### This is Example,Pair your host port
```
adb pair 192.168.1.3:41538
```
#### Choose 3rd Line's host port.[Not Paired Host Port]

```
adb connect 192.168.1.3:41115
```
## Example 1 

![](https://raw.githubusercontent.com/atamshkai/Phantom-Process-Killer/main/Example.jpg)

## Example 2 

![](https://raw.githubusercontent.com/atamshkai/Phantom-Process-Killer/main/Example2.jpg)

#### Deactivation Instructions (ROOT):

- On Termux (or any Terminal Emulator), paste the following commands on the following order:

```
su -c /system/bin/device_config set_sync_disabled_for_tests persistent
```
```
su -c /system/bin/device_config put activity_manager max_phantom_processes 2147483647
```
```
su -c setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false
```

- If it doesn't work on your phone,reboot your phone.

```
su -c reboot
```

#### Experimental Method (MAGISK)

- On a Rooted phone with Magisk installed, flash the following module:

  [Download](https://github.com/atamshkai/Phantom-Process-Killer/raw/main/PhantomProcessRetainer-main.zip) 

- After that, `PhantomProcessKiller' might be deactivated on every device boot.

#### Check if PhantomProcessKiller was Disabled (ROOT):
```
su -c /system/bin/dumpsys activity settings | grep max_phantom_processes
```
```
su -c /system/bin/device_config get activity_manager max_phantom_processes
```
- Both commands above should return `2147483647`

```
su -c getprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs
```
- It should return "false"

***

### To Wait

- After restarting your phone,

- It may be hot for a while.

- Wait it to normal state.

### Stop Auto Lauch Applications

- [Playstore Link](https://play.google.com/store/apps/details?id=com.tafayor.killall) 
    
</details>



<div align="center">
    <h2>• Screenshots •</h2>
    <h3></h3>
</div>

<div align="center">
    <img src="https://github.com/user-attachments/assets/94a27802-cb09-4897-ab4c-99a697f38f1c" alt="illogical-impulse logo" style="float:left; width:175px;">
</div>

Widget system: Termux + Awesome + Eww


| Perfil 1 | Perfil 2 |
|:---|:---------------|
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/f3b711eb-dfca-4f28-97f1-720f1860b40b" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2637dcf0-2c4a-4be5-832e-64331dd2b6f0" /> |

| Perfil 3 | Perfil 4 |
|:---|:---------------|
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6c15ab84-461b-415f-8cc2-9fd3ba9176fc" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/cb47ac7a-5eda-4572-a948-aef310d815dc" /> |

<div align="center">
    <h2></h2>
    <h3></h3>
</div>

<div align="center">
    <h2>• Requirements •</h2>
    <h3></h3>

<img src="https://f-droid.org/repo/com.termux/en-US/icon_7jMZ7XD80oeucmGEaTwktIRZexLtGWvJfKdVD6Wu2SI=.png" width="5%" alt="Termux Desktop Screenshot">

<img src="https://github.com/user-attachments/assets/a0d048dc-68a0-4913-8234-14ffbb4b7d3e" width="5%" alt="Termux Desktop Logo">

<img src="https://f-droid.org/repo/com.termux/en-US/icon_7jMZ7XD80oeucmGEaTwktIRZexLtGWvJfKdVD6Wu2SI=.png" width="5%" alt="Termux Desktop Screenshot">
</div>
<div align="center">

<img
  src="https://readme-typing-svg.demolab.com?font=Inconsolata&weight=900&size=53&duration=4000&pause=300&color=3B82F6&center=true&vCenter=true&multiline=true&repeat=false&width=1300&height=140&lines=Termux+%E2%80%A2+Termux-x11+%E2%80%A2+Termux-api"
  style="max-width: 100%; height: auto;"
/>
<br/>

---

<div align="center">
    <h2>• Other Screenshots •</h2>
</div> 

<img src="https://github.com/user-attachments/assets/115185e7-a23d-40ed-ae81-f7621e41a388" width="90%" alt="Termux Desktop Screenshot">

---

### Shutdown menu


|  |  |
|:---|:---------------|
|  <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b2ae10ea-af2c-489b-97ed-573c8e6f0b1e" /> |  <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d8d1e1ee-5119-4ddc-bf5a-a2288e8eea66" /> |
|  |  |

#### Notification system


<img src="https://github.com/user-attachments/assets/511d6cec-eef2-4677-b745-cbfbd7a519c9" alt="Notification system">

#### Program to change wallpaper


<img src="https://github.com/user-attachments/assets/d8f90560-4450-4121-a906-eac058aaba43" alt="Program to change wallpaper">


#### Cava and actions

<img src="https://github.com/user-attachments/assets/314c3bcc-8c74-4fb3-9c08-057d20ffac15" alt="cava and actions">

#### The notification system supports Audacious, Flameshot, mouse mode, and lock mode.

<img src="https://github.com/user-attachments/assets/f970f283-d17e-4b68-848b-674914014a11" alt="Desktop Preview">



<div align="center">
    <h2>• inspirations/copying •</h2>
    <h3></h3>
</div>

 - Inspiration: This desktop setup is obviously inspired by AlphaTechnolog dotfiles, give him a follow and a star. ⭐🌟💫. https://github.com/AlphaTechnolog/dotfiles
  
 - Copying: Absolutely, feel free. Just follow the license and it's all good
 
