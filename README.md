# SmoothSSH 🔒

**SmoothSSH** is a high-performance, gesture-driven SSH client for Android, built specifically for sysadmins who need speed, security, and a frictionless terminal experience on the move.

Forget clunky menus and dropped frames. SmoothSSH provides a smooth interface optimized for modern hardware like the Pixel 9 Pro XL, ensuring 60fps terminal scrolling and cryptographic handshakes that don't hang your UI.

## ✨ Key Features

* **Multi-Session Swiping:** Running maintenance across a cluster? Fluidly swipe left or right on the terminal canvas to instantly snap between active SSH sessions.
* **The Transcript Engine:** Stop fighting with mobile text selection. One tap dumps your entire live terminal buffer into a native, searchable text view—perfect for grabbing IP addresses or logs.
* **Encrypted Vault:** All connections, passwords, and private keys (PEM) are stored in a heavily encrypted local vault using AES-256.
* **Biometric App Lock:** Secure the entire application behind your device's native Fingerprint, Face ID, or PIN.
* **Frictionless Workflow:** Quick-add new Identities or Private Keys directly from the connection screen without losing your place.
* **Volume Rocker Scaling:** Instantly scale your terminal font size up or down using your phone's physical volume buttons.
* **Portable Backups:** Export your entire configuration as an encrypted `.smoothvault` file to migrate between devices securely.

## 🛠️ Performance Stack

* **Terminal Emulator:** `xterm.dart`
* **SSH/Crypto:** `dartssh2` (AOT Native Compiled)
* **Security:** `flutter_secure_storage` & `local_auth`
* **UI Engine:** Flutter (Custom Cupertino Slide Transitions)

## 🚀 Installation & Build

To get SmoothSSH running on your local machine:

1.  **Clone the Repo:**
    ```bash
    git clone [https://github.com/cfultz/smoothssh.git](https://github.com/cfultz/smoothssh.git)
    cd smoothssh
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Launcher Icons:**
    *(Ensure your `app_icon.png` is in the `assets/` directory)*
    ```bash
    flutter pub run flutter_launcher_icons
    ```

4.  **Run on Device:**
    ```bash
    # Use --release mode for optimal crypto and rendering performance
    flutter run --release
    ```

## 📂 Project Structure

This project has been stripped of all non-Android platform code to remain as lean and performant as possible.

* `lib/models/`: Data structures for Connections and Identities.
* `lib/services/`: Logic for Session Management, Encryption, and Settings.
* `lib/screens/`: High-performance UI views and Terminal logic.
* `assets/`: Branding and iconography.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built for sysadmins, by sysadmins. 🔒