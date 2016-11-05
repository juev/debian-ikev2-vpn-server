# IKEv2 VPN Server on Debian

Based on [`gaomd/docker-ikev2-vpn-server`](https://github.com/gaomd/docker-ikev2-vpn-server) docker image.

## Usage

### 1. Install IKEv2 VPN Server

    git clone https://github.com/Juev/debian-ikev2-vpn-server.git
    cd debian-ikev2-vpn-server
    ./install.sh

### 2. Use .mobileconfig (for iOS / macOS)

Transfer the generated `~/ikev2-vpn.mobileconfig` file to your local computer via SSH tunnel (`scp`) or any other secure methods.

### 3. Install the .mobileconfig (for iOS / macOS)

- **iOS 9 or later**: AirDrop the `.mobileconfig` file to your iOS 9 device, finish the **Install Profile** screen;

- **macOS 10.11 El Capitan or later**: Double click the `.mobileconfig` file to start the *profile installation* wizard.

## License

Copyright (c) 2016 Denis Evsyukov, This software is licensed under the [MIT License](LICENSE).

---

\* IKEv2 protocol requires iOS 8 or later, macOS 10.11 El Capitan or later.

\* Install for **iOS 8 or later** or when your AirDrop fails: Send an E-mail to your iOS device with the `.mobileconfig` file as attachment, then tap the attachment to bring up and finish the **Install Profile** screen.
