#!/bin/zsh
read bytes

echo "bytes:" > /dev/stderr
echo $bytes | hexdump -C > /dev/stderr

readarray -t data <<< $(echo -n $bytes | hexdump -e '/1 "%u\n"')

echo "data:" > /dev/stderr
echo ${data[@]} | hexdump -C > /dev/stderr


echo "FIN bit:" $(( ${data[0]} >> 7 )) > /dev/stderr

echo "opcode:" $(( ${data[0]} & 0x0f )) > /dev/stderr

echo ${data[0]} > /dev/stderr

mask_bit=$(( ${data[1]} >> 7 ))
echo "Mask (bit):" $mask_bit > /dev/stderr

len=$(( ${data[1]} & 0x7f ))
offset=2 # 2 for header

if [[ $len == 126 ]]; then
	len=$(( ${data[2]} << 8 + ${data[3]} ))
	offset=4 # 2 for header, 2 for extended length
elif [[ $len == 127 ]]; then
	len=0
	for i in {0..8}; do
		len=$(( $len << 8 + ${data[2+i]} ))
	done
	offset=10 # 2 for header, 8 for extended length
fi

echo "Data length:" $len > /dev/stderr

echo "Offset:" $offset > /dev/stderr

if [[ $mask_bit == 1 ]]; then
	read -ra mask <<< ${data[@]:$offset:4}

	echo "Mask:" $mask > /dev/stderr

	offset=$(( $offset + 4 ))
fi

read -ra payload <<< ${data[@]:$offset:$len}

echo "Payload:" ${payload[@]} > /dev/stderr

if [[ $mask_bit == 1 ]]; then
	for ((i = 0; i < $len; i++)); do
		byte=$(( ${payload[$i]}  ^ ${mask[$i % 4]} ))
		echo "Byte $i: $byte" > /dev/stderr
		payload[$i]=$byte
	done

	echo "Payload unmasked:" ${payload[@]} > /dev/stderr
fi

payload_hex=""
for ((i = 0; i < $len; i++)); do
	hex=$(printf '\\x%x\n' $(( ${payload[$i]} )))
	payload_hex+=$hex
done

echo "Payload hex:" $payload_hex > /dev/stderr
echo -e "Payload: $payload_hex" > /dev/stderr
