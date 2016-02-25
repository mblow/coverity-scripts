#!/bin/bash
set -e
case $1 in
  asterixdb-hyracks)
    project="Apache AsterixDB Hyracks"
    token=oYZXCWGySw_hxhpUmPrP1g
    ;;
  asterixdb)
    project="Apache AsterixDB"
    token=u3GFYqA24l2xHavA1EZNvw
    ;;
  *)
    echo Unknown project: $1; exit 1;;
esac

project_key="$(echo $project | tr ' ' '+')"
archive_name="$(echo $project | tr ' ' '+' | tr '[A-Z]' '[a-z]').tgz"

set -x
dir="$(pwd)/$(dirname $0)"
work="${dir}/work/$1"
devroot=$(cd ${dir}/../$1; pwd)
rm -rf ${work}
mkdir -p ${work}/cov-int 
cd ${devroot}
git pull
mvn clean
cov-build --dir ${work}/cov-int mvn -DskipTests=true install
cd ${work}
tar czvf ${archive_name} cov-int

curl -v -# -o curl.out \
  --form token=$token \
  --form email=michael@michaelblow.com \
  --form file=@${archive_name} \
  --form version="$(cd $devroot && git log | head -1 | awk '{ print $NF }') ($(cd $devroot && git branch | grep '^*' | awk '{print $NF}'))" \
  --form description="${project} (Incubating) scan ($(date -u))" \
  https://scan.coverity.com/builds?project=${project_key}
