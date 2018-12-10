alias bleh="'blah'"
function blah {
    description="This tells what the command does at a High level"
    declare -a paramNames=(
	"env:enum:required:prod|cert|qual|devl"
	"queue:string:optional"
	"query:string:optional"
	"rank:number:required")
    verifyParameters "$@" || return 1

    echo "$env $queue $query $rank"
    echo "Something"
}
