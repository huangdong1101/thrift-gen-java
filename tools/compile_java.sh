#!/bin/sh

function check_thrift_env() {
    local thrift_version=$1
    local tre_path=$(dirname $0)/../env/$thrift_version
    if [ ! -d "$tre_path" ]; then
        echo "Unsupported Thrift version: $thrift_version"
        exit 1
    fi
    local tre_path=$(cd $tre_path; pwd)
    if [ $(find $tre_path -name "*.jar" | wc -l) == 0 ]; then
        echo "Unsupported Thrift version: $thrift_version"
        exit 1
    fi
}

function check_java_src_files() {
    local java_src_dir=$1
    if [ ! -d "$java_src_dir" ]; then
        echo "Invalid java src dir: \"$java_src_dir\""
        exit 1
    fi
    local java_src_cnt=$(find $java_src_dir -name "*.java" | wc -l | awk '{print $1}')
    if [ $java_src_cnt == 0 ]; then
        echo "Empty java src dir: \"$java_src_dir\", files(*.java) not found"
        exit 1
    fi
}

function compile_java_src_files() {
    local tre_path=$1
    local java_src_dir=$2
    local out_dir=$3

    echo "Thrift Runtime Environment: \"$tre_path\""
    echo "Java source: \"$java_src_dir\", files(*.java) found: $java_src_cnt"
    echo "Output dir: \"$out_dir\""

    # java tmp dir, copy src to tmp dir
    local java_tmp_dir=$out_dir/tmp_src
    rm -rf $java_tmp_dir
    mkdir $java_tmp_dir
    # find $java_src_dir -name "*.java" | xargs cp -t $java_tmp_dir
    # if [[ "$?" != "0" ]]; then
    #     rm -rf $java_tmp_dir
    #     exit 1
    # fi
    for file in $(find $java_src_dir -name "*.java"); do
        cp $file $java_tmp_dir
    done

    # compile to *.class
    local classes_dir=$out_dir/classes
    rm -rf $classes_dir
    mkdir $classes_dir
    javac -cp :$tre_path/* -d $classes_dir $java_tmp_dir/*.java
    if [[ "$?" != "0" ]]; then
        rm -rf $classes_dir
        rm -rf $java_tmp_dir
        exit 1
    else
        echo "compile java files success, classes dir: \"$classes_dir\""
        rm -rf $java_tmp_dir
    fi

    # No need to compile as a jar
    compress_as_jar $classes_dir $out_dir/classes.jar
}

function compress_as_jar() {
    local classes_dir=$1
    local jar_path=$2
    rm -rf $jar_path
    cd $classes_dir
    jar -cvf $jar_path ./*
    if [[ "$?" != "0" ]]; then
        exit 1
    fi
    echo "compress as jar file: \"$jar_path\""
}

javac -version
if [[ "$?" != "0" ]]; then
    exit 1
fi

if [ $# -lt 3 ]; then
    echo "too less arguments"
    exit 1
fi

# Thrift version
check_thrift_env $1
tre_path=$(cd $(dirname $0)/../env/$1; pwd)

# java src dir
check_java_src_files $2
if [[ "$?" != "0" ]]; then
    exit 1
fi
java_src_dir=$(cd $2; pwd)

# output dir
out_dir=$3
if [ ! -d "$out_dir" ]; then
    mkdir -p $out_dir
fi
out_dir=$(cd $out_dir; pwd)

compile_java_src_files $tre_path $java_src_dir $out_dir
