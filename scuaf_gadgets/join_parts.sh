#!/bin/bash
cat scuaf_linux_v5_15_83_part_* > scuaf_linux_v5_15_83 
original_hash="2f8ab3cdd8b047e83d9b45a1b5eaee2dc5b877e8c38dd5a48311c8fabae9e65b"
new_hash=$(printf $(shasum -a 256 scuaf_linux_v5_15_83))
if [ "$new_hash" == "$original_hash" ]; then
    echo "Gadgets file correctly restored."
else
    echo "Error: Hash Mismatch"
    echo "Original hash: $original_hash"
    echo "     New hash: $new_hash"
    rm -rf scuaf_linux_v5_15_83
fi
