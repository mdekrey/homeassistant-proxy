# Home Assistant Proxy server

I set up Home Assistant for home automation recently, and I want it accessible
to the web for features such as my Nest thermostat, Google Assistant
integration, etc. This repository documents that process.

## Hardware

- [Raspberry PI 3 B+](https://www.amazon.com/gp/product/B0811L9QV9/) - with a
  decent starter kit with case, etc. because I don't need to show it off with 3d
  printing
- [GoControl CECOMINOD016164 HUSBZB-1 USB
  Hub](https://affiliate-program.amazon.com/) - for Z-Wave and Zigbee
  integration
- One or more Z-Wave or Zigbee devices
    - [Z-Wave Plus Outlet](https://www.amazon.com/gp/product/B08FM3NFCP/) - my
      first just to test it out because it is functional and cheap.

## Setup

- [Home Assistant
  OS](https://www.home-assistant.io/installation/raspberrypi/#install-home-assistant-operating-system)
  - I just downloaded the image directly and used the Raspberry Pi imager. The
    image was "Raspberry Pi 3 64-bit" since the Pi listed above is was 64-bit.
    - I initially tried using Home Assistant Core in a docker container, but
      realized quickly that I was over my head with figuring out the Supervisor
      functionality (which runs out-of-process add-ons for you). Since I didn't
      want to struggle with it, I did the OS option.
- Integrations
    - Z-Wave JS
        - For this stick (since it has both Z-Wave and Zigbee support), Z-wave
          comes in the first serial port
          `/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_C13005F7-if00-port0`
          note the "if00". If you're unsure, set up the Zigbee interface first
          because its dropdown has a nicer interface (at least, as of the time
          of this writing).
        - Activating inclusion was so easy that I didn't realize it worked the
          first time. Read the instructions for your hardware to allow it to be
          included, and then click "Add Node" and "Start Inclusion" in the
          Z-Wave JS Integration screen.
    - Zigbee Home Automation - straightforward, although I didn't have any
      Zigbee devices to test... hopefully this is working!
- Wi-fi
    - This felt like a weird spot for the menu: `Supervisor -> System -> Host ->
      IP Address -> Change -> WLAN0 -> WiFi`... once I found it it set up
      easily, though.
- SSH
    - Since I (of course) want to remote into the device, Adding the `Terminal &
      SSH` add-on was important to me. Needing to specify the host port was odd,
      but was otherwise very easy. The other trick was that I needed to log in
      as root - meaning the actual command was:

            ssh root@homeassistant.local

- MFA
    - This was already built-in, so was easy: Head to your profile, and scroll
      to the Multi-factor authentication modules.
- Updates
    - Within Supervisor, there was a notice to automatically update and
      Snapshot.

## Remote Access

Of course, I wanted remote access to my home... and I definitely didn't want to
pay for something new. And I don't want to deal with dynamic DNS or exposing a
port to my home... what to do?

A reverse proxy, of course! SSH from my home to the cloud with port tunnelling,
and then expose that there. I already have a kubernetes ingress instance set up
for dekrey.net, all I need is a script that will SSH from Home Automation OS to
a container inside my cluster... I'll want it to automatically reconnect, too.

Fortunately, I was able to find [ThomDietrich's Home Assistant
Add-ons](https://github.com/ThomDietrich/home-assistant-addons) which already
had an autossh add-on for just this purpose.

I also found someone else who had a [demo set of docker
containers](https://github.com/aduermael/docker-ssh-reverse-proxy) for the
purpose, too. Though, they had a few issues:

    - Keys for the host are regenerated each time the container restarts, which I dislike
    - Layers are left a little large for my taste, too

With a small rewrite, I had something decent. I snagged the public key from the
autossh add-on and wrote my kubernetes yaml file. Adding my registry secret, a
`kubectl apply`, and finally a call to my publish script... I had everything set
up and ready to use, including a Let's Encrypt certificate! I grabbed the
External-IP from my load balancer SSH service, plugged that into home assistant,
and it was working.

## Using this yourself

Assumptions:

- I use AKS (Azure Kubernetes Service) and ACR (Azure Container Service), and
  already had it running.
- I already had `nginx-ingress` helm chart and `cert-manager` in my cluster.

Obviously, you don't host your site at dekrey.net. And even if it's me coming
back for a second home later (maybe for my parents or my brother), they won't
get the obvious domain. Here's the steps to customize:

- Clone this repository.
- `make-registry-secret.ps1` is only necessary if you use a private ACR
  registry. Otherwise, you can ignore it. (If you're using a different private
  repository, you probably already know what to do.)
- Modify homeassisstant.k8s.yaml, make-registry-secret.ps1, and publish.ps1 to
  reference the namespace you want. I used `homeassistant-proxy`.
- Modify the ps1 files to use your correct subscription ID. (Some people treat
  these as secret, since no one can get them normally, but they're not used by
  themselves, and they're not really keys, so... mine is not secret.) While
  you're here, also adjust the resource group. If you're not using Azure, you
  can remove the corresponding lines.
- Modify homeassisstant.k8s.yaml, make-registry-secret.ps1, and publish.ps1 to
  reference your container registry. I use `dekreydotnet.azurecr.io`.
- Modify homeassisstant.k8s.yaml to specify your domain.
- Get your public key from the autossh add-on, base-64 encode the whole thing
  (comment, etc.) and update the container args in homeassisstant.k8s.yaml.
- Run `make-registry-secret.ps1`.
- Run `kubectl apply -f homeassisstant.k8s.yaml`.
- Run `publish.ps1`
- Run `kubectl -n homeassistant-proxy get service --watch` (swapping out your
  namespace) to watch for the EXTERNAL-IP get added to your
  `homeassistant-ssh-service`. When you have that, update your autossh config:

        hostname: <EXTERNAL-IP>
        ssh_port: 2222
        username: root
        remote_forwarding:
        - '8000:<INTERNAL-NETWORK-HOST-NAME>:8123'
        other_ssh_options: '-v'
        force_keygen: false

- Watch your logs to make sure it's connected, and enjoy!

## What I'd like to change

Because I never really finish a project, here's a couple tweaks I still want to do:

- [ ] Rather than using command line arguments within the start.sh, I'd like to
  use a config object and map the file in.
- [X] I feel there's a better way to keep the container running than that sleep
  instruction. Find it.