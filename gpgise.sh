#!/bin/bash
# # Encrypts or decrypts a file using GPG, replacing the original file securely

MODE="$1";
FILE="$2";

set -euo pipefail; # qu'est-ce que ca fait ?

function usage() {
        echo "Usage";
        echo " $0 encrypt <file>";
        echo " $0 decrypt <file>";
        exit 1;
}

function encrypt_file() {
	if [[ ! -f "$FILE" ]]
	then
        	echo "Error: '$FILE' does not exist or is not a file.";
	fi

	echo "[*] Encrypting $FILE...";
    	gpg --symmetric --no-symkey-cache "$FILE";
    	echo "[*] Securely deleting original...";
    	shred --remove "$FILE";
    	echo "[+] Done. Encrypted file: $FILE.gpg";
}

function decrypt_file() {
	ENCRYPTED_FILE="$FILE.gpg";

	if [[ ! -f "$ENCRYPTED_FILE" ]]
	then
        	echo "Error: '$ENCRYPTED_FILE' does not exist or cannot be decrypted";
        	exit 1;
    	fi

    	echo "[*] Decrypting $ENCRYPTED_FILE...";
    	gpg --no-symkey-cache --output "$FILE" "$ENCRYPTED_FILE";
    	echo "[*] Securely deleting encrypted file...";
    	shred --remove "$ENCRYPTED_FILE";
    	echo "[+] Done. Decrypted file: $FILE";
}

if ! command -v gpg &> /dev/null
then
	echo "Error: gpg is not installed";
	exit 1;
fi

if ! command -v shred &> /dev/null
then
	echo "Error: shred is not installed";
	exit 1;
fi

if [ $# -ne 2 ]
then
	usage;
fi

case "$MODE" in
        "encrypt")
	   encrypt_file;
           ;;
        "decrypt")
	   decrypt_file;
           ;;
        *)
           usage;
           ;;
esac
