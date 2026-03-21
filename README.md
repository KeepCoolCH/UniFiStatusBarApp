# ![App Icon](https://online.kevintobler.ch/projectimages/UniFiStatusBarApp.png) UniFi Status Bar App

**Monitor your UniFi Network directly from the macOS menu bar** —  
view gateway health, connected devices, live throughput, PoE stats, and client information in real-time.  
Version **2.0** – developed by  **Kevin Tobler** 🌐 [www.kevintobler.ch](https://www.kevintobler.ch)

---

## 🧩 Overview

`UniFiStatusBarApp` is a lightweight macOS utility that connects to your local **UniFi Network Controller** and displays key system metrics right in the macOS menu bar.

Features include:
- 🔹 Automatic detection of your UniFi Controller (Gateway IP)
- 🔹 Live health status, device list, and client connections
- 🔹 Real-time throughput (Mbps) and PoE information
- 🔹 Compact menu bar UI for quick network insights
- 🔹 Local API access — no cloud login required

---

## 🔄 Changelog

### 🆕 Version 2.x
- **2.0**
  - 🌳 **Topology View:** Devices and clients are shown as a live tree (uplink relationships).
  - 🌐 **WAN Details:** WAN 1/2 IP + ISP shown in Overview and Network entries.
  - 🧭 **Menu Bar WAN Status:** WAN 1/2 IP + ISP shown directly in the menu bar panel.
  - 🧠 **Smarter Device Labels:** Improved model detection (e.g., UCG Fiber and new model fields).
  - 🔎 **Network Tab Enhancements:** WAN info is displayed inline with Internet networks.

### 🆕 Version 1.x
- **1.0**
  - 🔁 Initial Release

---

## 📸 Screenshot

![Screenshot](https://online.kevintobler.ch/projectimages/UniFiStatusBarAppPanelV2-menubar.png)
![Screenshot](https://online.kevintobler.ch/projectimages/UniFiStatusBarAppPanelV2-overview.png)

---

## ⚙️ Requirements

- **macOS 14.6 (Sonoma)** or newer  
- **UniFi Controller** reachable in your local network (Network Version 9.4.19 or newer) 
- A valid **UniFi API Key** (`Settings → System → API Access`)

---

## 🧭 Installation

### Download Prebuilt App

[![Download UniFiStatusBarApp](https://img.shields.io/badge/Download-UniFiStatusBarApp-blue)](https://github.com/KeepCoolCH/UniFiStatusBarApp/releases/tag/V.2.0)

- Unzip the App and run it or move it to the Applications folder

---

## 🔑 First Launch

When starting the app for the first time:

1. The app automatically detects your local UniFi Gateway (e.g. `192.168.1.1`)
2. A small settings window appears asking for your **API Key**
3. Paste your UniFi key and press **💾 Save and Connect**
4. The app refreshes automatically and starts displaying live stats

---

### 🧩 Contact
📧 [internet@kevintobler.ch](mailto:internet@kevintobler.ch)  
🐙 [github.com/KeepCoolCH](https://github.com/KeepCoolCH)

---
