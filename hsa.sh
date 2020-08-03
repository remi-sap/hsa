#!/bin/bash
#Connects to the streaming node and display the status of the projects
#If the parameter connect is passed, an interactive session to the tool streamingclusteradmin is open
#If any other parameter is passed, a more verbose status is displayed

PARAMS=$#
  URI=${1}
  WK=${2}
  USER=${3}
  PASS=${4}
  CCL=${5}


usage() {
  echo "Usage of ${0}"
  echo ""
  echo $0 ":  <URI> <workspace> <user> <password> [ <ccl file> ] "
  echo "	<uri>:  esps://localhost:30059  https could be used instead of esps"
  echo "	<workspace>"
  echo "	<user>"
  echo "	<password>: Either the password, or the location of a file containing the password"
  echo "        [ <ccl_file> ] If not specified, print the status of all projects."
  echo "		 If specified, deploys it along with the crr file if it exists in the same folder"
}

parse_params(){

  if [[ ${PARAMS} -le 3 ]] ; then
    usage
    exit -1
  fi

  [[ -f ${PASS} ]] && PASS=$(<${PASS})

  SCA_CMD="$STREAMING_HOME/bin/streamingclusteradmin --uri=${URI}  --username=${USER} --password=${PASS}" 
  test_connection
  ret=$?
  if [[ ${ret} -eq 0 ]]; then
     echo " OK!"
  else
     echo " error!"
     ${SCA_CMD} --get_projects | awk '{ print "	|" $0 }'
     exit -2
  fi
  if [[ -z "${CCL}" ]] ; then
    print_projects
  else
    [[ ! -f "${CCL}" ]] && echo "ERROR. Cannot find ccl file at: ${CCL}" && exit 4
    PRJ=$(basename ${CCL}| sed -e 's/\.ccl$//' )
    compile
    #stop_project    
    is_started=$(is_project_running)
    if [[ $is_started -eq 1 ]]; then
       stop_project
       delete_project
    fi
    add_project
    start_project
  fi
  
}
start_project(){
	mylog "starting ${WK}/${PRJ}.."
	$SCA_CMD --workspace-name=${WK} --project-name=${PRJ} --start_project
}
add_project(){
	mylog "adding ${CCL} in project ${WK}/${PRJ}.."
	CCX=/tmp/${PRJ}.ccx
	if [[ -f "${PRJ}.ccr" ]]; then
		CCR="-ccr ${PRJ}.ccr"
	else
		CCR=""
	fi
	$SCA_CMD --workspace-name=${WK} --project-name=${PRJ} --add_project -ccx ${CCX} ${CCR}
}

stop_project() {
   mylog "Stopping ${WK}/${PRJ}" 
  $SCA_CMD --workspace-name=${WK} --project-name=${PRJ} --stop_project
  #TODO
  #sleep, retry, and then force stop   
}
delete_project() {
  mylog "Removing ${WK}/${PRJ}"
  $SCA_CMD --workspace-name=${WK} --project-name=${PRJ} --remove_project 
}

is_project_running() {
  print_projects | grep "${WK}/${PRJ}" | wc -l
}
mylog() {
  f=/tmp/hsa_deploy.log
  d=`date +%F_%T`
  echo $@ | awk -v dt=$d '{ print dt,"|",$0}' | tee -a ${f}
}

logfile() {
  f=/tmp/hsa_deploy.log
  if [[ -f ${1} ]] ; then
    awk '{ print "		",$0}' ${1} | tee -a ${f}
  fi  

}

test_connection(){
  echo -n "Testing connection to ${URI} ..."
  ${SCA_CMD} --get_projects > /tmp/hsa_test_conn.out 2>&1
  ERR=$( grep "^\[error" /tmp/hsa_test_conn.out | wc -l )
  return $ERR

}

print_projects() {
  $SCA_CMD --get_projects | awk -f $HOME/.hsa_get_projects.awk | sort
}

compile() {
  mylog start compilation of ${CCL} 
  streamingcompiler -i ${CCL} -o /tmp/${PRJ}.ccx 2>&1 >/tmp/hsa_${PRJ}_compile.out
  ret=$?
  if [[ $ret -ne 0 ]] ; then 
    mylog "Compilation error in ${CCL}"
    logfile /tmp/hsa_${PRJ}_compile.out
    exit 123
  fi
  mylog "compilation of ${CCL} finished :-)"
   
}

parse_params
