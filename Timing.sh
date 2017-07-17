#!/bin/bash
echo -n "Você tem 4s para digitar algo:"
if read -t 4 response; then
	echo "Boa você digitou no tempo previsto."
else
	echo "Desculpa, você foi lerdo."
fi
