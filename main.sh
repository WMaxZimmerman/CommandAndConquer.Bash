function verifyParameters {
    params=("$@")

    # === Clean Up ===
    function cleanup {
	unset params
	unset paramNames
	unset isValid
	unset last
	IFS=' '
    }
    
    # === Output usage if the last param is a ? ===
    for last; do true; done
    if [[ "$last" == "?" ]]; then
	outputUsage
	cleanup
	return 1
    fi

    isValid=true
    for p in ${paramNames[@]}; do
	verifyParameter $p 
    done

    if [ "$isValid" = false ]; then
	echo "Invalid usage. Please use a '?' to see the usage."
	cleanup
	return 1
    fi
    
    cleanup
}

function verifyParameter {
    local p="$1"
    local isEnum=false
    local isRequired=false
    local hasValue=false

    # === Get details for the parameter ===
    local indx=0
    IFS=':' read -ra ADDR <<< "$p"
    for i in "${ADDR[@]}"; do
	if [[ $indx = 0 ]]; then
	    local pName="$i"
	elif [[ $indx = 1 ]]; then
	    local pType="$i"
	    local isArray=false
	    if [[ $pType == *"[]" ]]; then
		local isArray=true
	    fi
	elif [[ $indx = 2 ]]; then
	    if [[ "$i" == "required" ]]; then
		local isRequired=true
	    fi
	elif [[ $indx = 3 ]]; then
	    local isEnum=true
	    local pEnum="$i"
	fi
	local indx=$((indx+1))
    done


    # === Get the short name for the parameter ===
    local indx=0
    IFS='|' read -ra ADDR <<< "$pName"
    for n in "${ADDR[@]}"; do
	if [[ $indx = 0 ]]; then
	    local pName="$n"
	elif [[ $indx = 1 ]]; then
	    local pShort="$n"
	fi
	local indx=$((indx+1))
    done
    
    # === Check the given parameters against the expected ones ===
    local index=0
    local wasFound=false
    local paramCount=${#params[@]}
    for param in ${params[@]}; do
	eval "unset $pName"
	if [[ "--$pName" == $param ]] || [[ "-$pShort" == $param ]]; then
	    local wasFound=true
	    local hasValue=true
	    if [[ $isArray == true ]]; then
		local isParam=false
		local COUNTER=$((index+1))
		while [[ $isParam == false ]]; do
		    local tempValue=${params[$COUNTER]}

		    if [[ $tempValue == -* ]]; then
			local isParam=true
		    else
			local value="$value $tempValue"
		    fi
		    
		    let COUNTER=COUNTER+1

		    if [ $COUNTER -gt $paramCount ]; then
			local isParam=true
		    fi
		done
	    else
		local value=${params[$((index+1))]}
	    fi
	fi
	
	local index=$((index+1))
    done

    # === Verify Parameter ===
    if [[ $wasFound = false ]]; then
	verifyRequired $isRequired
    else  
	if [[ "$pType" == "number" ]]; then
	    verifyNumber $value
	elif [[ "$pType" == "enum" ]]; then
	    verifyEnum "$value" "$pEnum"
	fi
    fi

    # === Set the Parameter ===
    eval "$pName=\"$value\""
}

function verifyRequired {
    local isRequired="$1"
    if [[ "$isRequired" = true ]]; then
	echo "Missing required parameter."
	isValid=false
    fi
}

function verifyNumber {
    local value="$1"
    local re='^[+-]?[0-9]+([.][0-9]+)?$'
    if ! [[ $value =~ $re ]] ; then
	echo "Number parameter has invalid value."
	isValid=false
    fi
}

function verifyEnum {
    local value="$1"
    local values="$2"
    local valueFound=false
    IFS='|' read -ra ADDR <<< "$values"
    for v in "${ADDR[@]}"; do

	if [[ "$v" == "$value" ]]; then
	    local valueFound=true
	fi
    done

    if [[ $valueFound = false ]]; then
	echo "Enum value did not match possible values."
	isValid=false
    fi
}

function outputUsage {
    echo "$description"
    for p in ${paramNames[@]}; do
	local isEnum=false
	local pRequired=""
	local indx=0
	IFS=':' read -ra ADDR <<< "$p"
	for i in "${ADDR[@]}"; do
	    if [[ $indx = 0 ]]; then
		local pName="$i"
	    elif [[ $indx = 1 ]]; then
		local pType="$i"
	    elif [[ $indx = 2 ]]; then
		if [[ "$i" == "required" ]]; then
		    local pRequired="*"
		else
		    local pRequired=" "
		fi
	    elif [[ $indx = 3 ]]; then
		local isEnum=true
		local pEnum="$i"
	    fi
	    local indx=$((indx+1))
	done


	local pString="$pRequired$pName:$pType"
	if [[ $isEnum = true ]]; then
	    local pString="$pString ("
	    IFS='|' read -ra ADDR <<< "$pEnum"
	    for e in "${ADDR[@]}"; do
		local pString="$pString $e"
	    done
	    local pString="$pString )"
	fi
	echo "$pString"
    done
}
