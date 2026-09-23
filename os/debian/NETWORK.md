# Setting a Static IP on Debian

Quick reference for giving your Debian machine a fixed local IP address, so it never changes (instead of relying on your router's DHCP).

Just copy-paste each block into your terminal, one at a time.

## 1. Find your network interface name and current IP

```bash
# List network interfaces. Look for the Ethernet one (e.g. eno1, enp2s0)
sudo ip a
```

## 2. Edit the network configuration file

```bash
# Open the network config file in a text editor
sudo nano /etc/network/interfaces
```

Find the block for your interface, which looks like this:

```
allow-hotplug eno1
iface eno1 inet dhcp
```

Replace `dhcp` with `static`, and add your address details below it:

```
allow-hotplug eno1
iface eno1 inet static
    address 192.168.0.77
    netmask 255.255.255.0
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1 8.8.8.8
```

- `address` → the fixed IP you want this machine to have
- `netmask` → almost always `255.255.255.0` on a home network
- `gateway` → your router's IP (usually ends in `.1`)
- `dns-nameservers` → your router's IP as primary, Google DNS (`8.8.8.8`) as backup

Leave everything else in the file (the `loopback` block, the `source` line) untouched.

Save and exit nano.

## 3. Apply the change

```bash
# Restart the networking service to apply the new settings
sudo systemctl restart networking
```

Your SSH session may briefly disconnect. This is normal. Reconnect after a few seconds using the same IP.

## 4. Verify it worked

```bash
# Check that the interface now shows your chosen static IP
sudo ip a
```
