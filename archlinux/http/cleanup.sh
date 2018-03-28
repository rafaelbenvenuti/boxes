#!/usr/bin/bash -x

# Clean the pacman cache.
/usr/bin/yes | /usr/bin/pacman -Scc
/usr/bin/pacman-optimize

pacman -Sc && pacman-optimize


# Write zeros to improve virtual disk compaction.
zerofile=$(/usr/bin/mktemp /zerofile.XXXXX)
/usr/bin/dd if=/dev/zero of="$zerofile" bs=1M
/usr/bin/rm -f "$zerofile"
/usr/bin/sync


# Another one
#!/usr/bin/zsh
set -o verbose
#clean
pacman --noconfirm --sync --clean --clean
#find /var/log -type f -execdir sh -c "echo -n >{}" \; #causes shutdown failures
for i in {,/{home,var}}/fillfile
do
		dd if=/dev/zero of=$i bs=4M
		rm $i
done
#clear history
[ -f /root/.bash_history ] && rm /root/.bash_history


