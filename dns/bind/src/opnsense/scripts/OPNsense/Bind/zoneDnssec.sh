#!/bin/sh

# show the DNSSEC state of a zone and the DS records to publish at the parent zone

# the BIND tools are installed in both /usr/local/sbin (rndc) and /usr/local/bin (dnssec-*)
PATH="/usr/local/sbin:/usr/local/bin:${PATH}"
export PATH

ZONENAME="${1%.}"
KEYDIR="/usr/local/etc/namedb/working"

case "${ZONENAME}" in
    ""|*[!A-Za-z0-9._-]*)
        echo "Invalid zone name"
        exit 0
        ;;
esac

echo "== DNSSEC status (rndc dnssec -status)"
rndc -c /usr/local/etc/namedb/rndc.conf dnssec -status "${ZONENAME}" 2>&1

echo
echo "== DS records to publish at the parent zone"
if ! command -v dnssec-dsfromkey > /dev/null; then
    echo "dnssec-dsfromkey not found"
    exit 0
fi
FOUND=0
for KEYFILE in "${KEYDIR}/K${ZONENAME}".+*.key; do
    [ -f "${KEYFILE}" ] || continue
    # only keys with the SEP flag (DNSKEY flags 257: KSK or CSK) have a DS record, ZSKs (256) are skipped
    grep -q ' DNSKEY 257 ' "${KEYFILE}" || continue
    dnssec-dsfromkey -a SHA-256 "${KEYFILE}" 2>&1
    FOUND=1
done
if [ "${FOUND}" -eq 0 ]; then
    echo "No key with a DS record found in ${KEYDIR} (is the zone signed and the configuration applied?)"
fi

exit 0
