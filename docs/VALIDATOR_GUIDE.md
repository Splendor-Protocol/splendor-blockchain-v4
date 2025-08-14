****You must create a fresh wallet and have Private key it will be needed****
Splendor Validator Installation Guide

1. Switch to root:
sudo -i

2. Update and upgrade packages:
apt update && apt upgrade -y

3. Install required packages:
apt install -y git tar curl wget tmux

4. Reboot the server:
reboot

5. After reboot, switch to root again:
sudo -i

6. Clone the Splendor blockchain repository:
git clone https://github.com/Splendor-Protocol/splendor-blockchain-v4.git

7. Move into the Core-Blockchain directory:
cd splendor-blockchain-v4/Core-Blockchain


8. Run the validator setup:
./node-setup.sh --validator 1

9. Start the validator:
./node-start.sh --validator

 
10. Attach to the validator session:
tmux attach -t node1

11. Wait until the output shows 'Block Sealing Failed Mutippule times'. 
!!WARNING DO NOT DETACH HERE!!

12. Then go stake stake tokens https://dashboard.splendor.org/
13. Wai nt unitl you see a hammer icon or mined potintal block!

12. To detach from the session (leave node running):
Press CTRL + b, release both keys, then press d.
