#!/bin/sh
# faillock.sh status → "<used> <deny> <remaining_seconds>" for the lock screen.
# used = failures still counted; remaining > 0 only while the account is locked.
conf=/etc/security/faillock.conf
val() { sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([0-9]*\).*/\1/p" "$conf" 2>/dev/null | tail -1; }
deny=$(val deny); deny=${deny:-3}
unlock=$(val unlock_time); unlock=${unlock:-600}
now=$(date +%s)
used=0 last=0
for t in $(faillock --user "$USER" 2>/dev/null | awk '$NF=="V"{print $1"T"$2}'); do
  e=$(date -d "$(echo "$t" | tr T ' ')" +%s 2>/dev/null) || continue
  used=$((used + 1)); last=$e
done
rem=0
if [ "$used" -ge "$deny" ]; then
  rem=$((last + unlock - now)); [ "$rem" -lt 0 ] && rem=0
fi
echo "$used $deny $rem"
