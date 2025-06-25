# USR-W610

Script will find any usr-w610s on the network and list them with the socat command to setup a virtual serial port in linux.

## To Run

    chmod +x usr-w610.sh
    ./usr-w610.sh
    
## Output

    D8:B0:4C:C5:6A:84	192.168.1.109:8899
    socat pty,link=/home/user/vcom6A84,waitslave,group-late=dialout,mode=660 tcp:192.168.1.109:8899 &
    D8:B0:4C:C5:93:78	192.168.1.198:8899
    socat pty,link=/home/user/vcom9378,waitslave,group-late=dialout,mode=660 tcp:192.168.1.198:8899 &

## Testing

Tested on two physical usr-w610 devices using Ubuntu 24.04.2 LTS.
Requires arping, arp-scan, and nmap. Admin/sudo rights required for scan.

    sudo apt install iputils-arping arp-scan nmap

## Issues

Need to add support for server/client detection, only detects tcp servers properly.  Should only provide socat command for server only.
