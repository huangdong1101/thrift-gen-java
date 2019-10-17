#!/bin/sh

function gen_thrift_file() {
    local out_dir=$2
    local src_file=$1
    echo "IDL source: \"$src_file\""
    thrift -r -gen java -o $out_dir $src_file
    if [[ "$?" != "0" ]]; then
        exit 1
    fi
    echo "gen java from thrift source file success!"
}

function gen_thrift_files() {
    local out_dir=$2
    local src_dir=$(cd $1; pwd)
    local src_cnt=$(find $src_dir -name "*.thrift" | wc -l | awk '{print $1}')
    if [[ $src_cnt == 0 ]]; then
        echo "Empty IDL src dir: \"$src_dir\", files(*.thrift) not found"
        exit 1
    fi
    echo "IDL source: \"$src_dir\", files(*.thrift) found: $src_cnt"
    # find $src_dir -name "*.thrift" | xargs -i thrift -r -gen java -o $out_dir {}
    # if [[ "$?" != "0" ]]; then
    #     exit 1
    # fi
    for file in $(find $src_dir -name "*.thrift"); do
    	thrift -r -gen java -o $out_dir $file
    done

    echo "gen java from thrift source files success!"
}

function compile_java_files() {
    local out_dir=$1
    local thrift_version=$(thrift -version | awk '{print $3}')
    sh $(cd "$(dirname $0)"; pwd)/compile_java.sh $thrift_version $out_dir/gen-java $out_dir
}

thrift -version
if [[ "$?" != "0" ]]; then
    exit 1
fi

if [[ $# -lt 2 ]]; then
    echo "too less arguments"
    exit 1
fi

# output dir
if [[ ! -d "$2" ]]; then
    mkdir -p $2
fi
out_dir=$(cd $2; pwd)

# IDL source
if [[ -f "$1" ]]; then
    gen_thrift_file $1 $out_dir
elif [[ -d "$1" ]]; then
    src_dir=$(cd $1; pwd)
    gen_thrift_files $1 $out_dir
else
    echo "Invalid IDL source: \"$1\""
    exit 1
fi

compile_java_files $out_dir
