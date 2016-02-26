#!/bin/bash
set -e
project=$1
case $project in
  asterixdb-hyracks)
    project_name="Apache AsterixDB Hyracks"
    ;;
  asterixdb)
    project_name="Apache AsterixDB"
    ;;
  *)
    echo Unknown project: ${project}; exit 1;;
esac

project_key="$(echo $project_name | tr ' ' '+')"
archive_name="$(echo $project_name | tr ' ' '+' | tr '[A-Z]' '[a-z]').tgz"

dir="$(cd $(dirname $0) && pwd)"
work="${dir}/work/${project}"
devroot=$(cd ${dir}/../${project} && pwd)

token=$(cat ${dir}/${project}.token)
if [ -z "$token" ]; then
  echo "ERROR: cannot find token for ${project}" && exit 1
fi
rm -rf ${work}
mkdir -p ${work}/cov-int 
cd ${devroot}
git pull
version=$(cd $devroot && git log | head -1 | awk '{ print $NF }')
if [ "$version" = "$(cat $dir/${project}.last_version)" ]; then
  echo "No new version, bypassing..."
  exit 0
fi
set -x
mvn clean
mvn dependency:go-offline
cov-build --dir ${work}/cov-int mvn -o -DskipTests=true install
cd ${work}
tar czvf ${archive_name} cov-int

curl -v -o curl.out \
  --form token=$token \
  --form email=michael@michaelblow.com \
  --form file=@${archive_name} \
  --form version="$version" \
  --form description="${project_name} (Incubating) scan ($(date -u))" \
  https://scan.coverity.com/builds?project=${project_key}

echo $version > $dir/${project}.last_version 


