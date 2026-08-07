<div align="center">
    <h1>【 Termux-Desktop-Awesome 】</h1>
    <h3></h3>
</div>

<div align="center"> 
  <a href="https://github.com/Keytaro2/Termux-Desktop-Awesome/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=git&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7"></a><br>
  <a href="https://github.com/Keytaro2/Termux-Desktop-Awesome/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=andela&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7"></a>
  <img alt="Repo Size" src="https://img.shields.io/github/repo-size/Keytaro2/Termux-Desktop-Awesome?style=for-the-badge&logo=protondrive&logoColor=c0caf5&labelColor=1E202B&color=7aa2f7&label=SIZE"><br>
  <a href="https://www.reddit.com/u/Vgloomy/s/nG9DCBad5p"><img alt="Reddit" src="https://img.shields.io/badge/reddit-12-7aa2f7?style=for-the-badge&logo=reddit&logoColor=c0caf5&labelColor=1E202B"></a>
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
>  It is important to have more than 5GB of free space available, as this desktop setup is somewhat resource-heavy.

<details> 
  <summary>Termux Backups</summary>

  - **📁 Compress data**:
  - termux-setup-storage
  - cd ..
  - tar -zcvf /sdcard/termux-backup.tar.gz home usr
   
  - **📂 Decompress (extract) data**:
  - termux-setup-storage
  - cd ..
  - tar -zxf /sdcard/termux-backup.tar.gz --recursive-unlink --preserve-permissions
  
</details>

<details> 
  <summary>Notable Features</summary>
     
  - **🐧 OVERVIEW:** Open apps with live previews.
  - **💻 CATPPUCCIN MOCHA THEME:** Choose your wallpaper with Ctrl + K. It's that simple, enjoy!
  - **💾 TRANSPARENT INSTALLATION:** Every command is shown in the terminal before it runs, so you know exactly what is happening.
  - **🔒 LOCK MODE:** This mode is enabled by default to prevent accidental layout changes. To unlock the layout and move the Eww widgets, press Ctrl + G. A notification will appear to confirm the change.

    <img src="https://github.com/user-attachments/assets/03c42c2a-f82a-4d28-b0d2-f33b6c382acf" alt="image" width="200" />

    Once unlocked, you can move the widgets using Ctrl + Up, Down, Left, or Right. You can resize them using Alt + Up, Down, Left, or Right. To lock the layout again, press Ctrl + G. The layout will lock, and you will receive another notification.

    <img src="https://github.com/user-attachments/assets/7803cae9-d7be-4d64-9d19-17fbbb96d139" alt="image" width="200" />
    
  - **🖱️ MOUSE MODE:** Disabled by default. When enabled, it allows you to move Eww widgets and other floating programs using your mouse. To toggle it on or off, press Ctrl + V; a notification will appear to confirm the status.

    <img src="https://github.com/user-attachments/assets/456f07c5-b40a-4482-83ef-5b6757c0eb97" alt="image" width="200" />

    Usage: Click and drag to move widgets. To resize them, hold Alt, click on a corner or edge, and drag. 

    <img src="https://github.com/user-attachments/assets/4886a8a9-15e2-48d7-b479-c1ff47ac6bfb" alt="image" width="200" />

    **Note:** Mouse Mode only works if Lock Mode is unlocked.

  - **🔔 NOTIFICATION SYSTEM:** This is the standout feature of this desktop! The notification system fully integrates with Mouse Mode and Lock Mode. It also displays real-time updates for:
    
     Screenshot.

    <img src="https://github.com/user-attachments/assets/5a8d51f0-69c2-4922-a606-b53ca29b859a" alt="image" width="200" />
  
     Wallpaper changes.

    <img src="https://github.com/user-attachments/assets/7b4ff17a-53ac-4570-b002-101144917cdf" alt="image" width="200" />

     and Music playback.

    <img src="https://github.com/user-attachments/assets/e1276683-450c-447f-8327-abc64dea27f9" alt="image" width="200" />

     You can play music using:
```bash
audacious -p ~/storage/music
```

(requires local music files). If you want to see how to take a screenshot or change your wallpaper, you can check the keyboard shortcuts [here](#keyboard-shortcuts).

</details>

<details> 
  <summary>Installation</summary>

   - **One-Line Installation**

```bash
apt update && apt upgrade -y && apt install git wget python python3 python-pip x11-repo -y && git clone [https://github.com/Keytaro2/Termux-Desktop-Awesome.git](https://github.com/Keytaro2/Termux-Desktop-Awesome.git) && cd Termux-Desktop-Awesome && python3 install.py && ./startawesome_termux.sh
```


</details>

<details>
  <summary>Keyboard Shortcut</summary>
   <a id="keyboard-shortcuts"></a>

| Keys | Action |
| :-------------------: | :---------------------------------------------------------------: |
| `ctrl` + `w` | Close focused window. |
| `ctrl` + `Enter` | Open a terminal. |
| `ctrl` + `k` | Open the wallpaper changer program. |
| `ctrl` + `n` | Close the wallpaper changer program. |
| `alt` + `/` | Take a screenshot. |
| `ctrl` + `z`  | Toggle between profiles. |
| `ctrl` + `x` | Go back to previous profile. |
| `ctrl` + `v` | Enable or disable Mouse Mode. |
| `ctrl` + `g`  | Toggle Lock Mode (lock/unlock widgets). |
| `alt` + `r` | Restart Awesome. |
| `alt` + `q` | Quit Awesome. |
| `ctrl` + `d` | Run Rofi (App Launcher). |
| `alt` + `d` | Close Eww launcher. |
| `ctrl` + `left` | Move floating window to the left. |
| `ctrl` + `down` | Move floating window down. |
| `ctrl` + `up` | Move floating window up. |
| `ctrl` + `right` | Move floating window to the right. |
| `alt` + `left` | Resize window to the left. |
| `alt` + `down` | Resize window down. |
| `alt` + `up` | Resize window up. |
| `alt` + `right` | Resize window to the right. |

---


</details>

<details>
    <summary>Reddit</summary>
        <a href="https://www.reddit.com/u/Vgloomy/s/yg8IJcRWab"> User link</a> | I hope this provides a friendlier environment for support requests/DMs. For real issues, prefer GitHub

</details>
<details>
     <summary>Phantom Process Killer</summary>

***

## Phantom Process Killer

**NOTICE:**

**Termux may be unstable on Android 12+.** Android OS will kill any (phantom) processes greater than 32 (limit is for all apps combined) and also kill any processes using excessive CPU. You may get a `[Process completed (signal 9) - press Enter]` message in the terminal without actually exiting the shell process yourself. Check the related issue [#2366](https://github.com/termux/termux-app/issues/2366), [issue tracker](https://issuetracker.google.com/u/1/issues/205156966), [gist with details](https://gist.github.com/agnostic-apollo/dc7e47991c512755ff26bd2d31e72ca8) and [this TLDR comment](https://github.com/termux/termux-app/issues/2366#issuecomment-1009269410) on how to disable trimming of phantom processes.

#### Deactivation Instructions (ADB / No Root):

- On an ADB console, paste the following commands in the following order:

```
adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent"
```
```
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```
```
adb shell settings put global settings_enable_monitor_phantom_procs false
```
- If it doesn't work right away, reboot your phone using `adb reboot`.

#### You Can Also Deactivate It Directly With Termux (Wireless ADB).
```
pkg up -y;pkg i -y android-tools
```
- After installing the package, you must enable Developer Options in order to use wireless ADB with Termux.

- Go to Settings > About Phone and tap the Build Number several times.

- On Xiaomi Phones, tap the MIUI version several times.

- After enabling Developer Options, open Wireless Debugging and use Split Screen.

- Then, open Termux & pair the device with a pairing code.

- You can also use two phones on the same Wi-Fi network.

- Type this ADB Command in Termux:

#### This is an example, use your own pairing port
```
adb pair 192.168.1.3:41538
```
#### Choose the 3rd Line's host port. [Not Paired Host Port]

```
adb connect 192.168.1.3:41115
```
## Example 1 

![](https://raw.githubusercontent.com/atamshkai/Phantom-Process-Killer/main/Example.jpg)

## Example 2 

![](https://raw.githubusercontent.com/atamshkai/Phantom-Process-Killer/main/Example2.jpg)

#### Deactivation Instructions (ROOT):

- On Termux (or any Terminal Emulator), paste the following commands in this order:

```
su -c /system/bin/device_config set_sync_disabled_for_tests persistent
```
```
su -c /system/bin/device_config put activity_manager max_phantom_processes 2147483647
```
```
su -c setprop persist.sys.fflag.override.settings_enable_monitor_phantom_procs false
```

- If it doesn't work, reboot your phone.

```
su -c reboot
```

#### Experimental Method (MAGISK)

- On a Rooted phone with Magisk installed, flash the following module:

  [Download](https://github.com/atamshkai/Phantom-Process-Killer/raw/main/PhantomProcessRetainer-main.zip) 

- After that, the Phantom Process Killer will be deactivated on every device boot.

#### Check if Phantom Process Killer was Disabled (ROOT):
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

### Additional Tips

- After restarting your phone, it may run hot for a while.

- Wait for the device to cool down and return to a normal state.

### Stop Auto Launch Applications

- [Play Store Link (KillApps)](https://play.google.com/store/apps/details?id=com.tafayor.killall) 
    
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

#### The notification system supports Audacious, Flameshot, Mouse mode,  Lock mode and Wallpapers.

<img src="https://github.com/user-attachments/assets/f970f283-d17e-4b68-848b-674914014a11" alt="Desktop Preview">



<div align="center">
    <h2>• inspirations/copying •</h2>
    <h3></h3>
</div>

 - Inspiration: This desktop setup is obviously inspired by [AlphaTechnolog](https://github.com/AlphaTechnolog/dotfiles). dotfiles, give him a follow and a star. ⭐🌟💫.
 - Copying: Absolutely, feel free. Just follow the license and it's all good
