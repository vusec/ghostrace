#!/bin/bash

if [ $# -lt 3 ]
  then
    echo "ERROR: Missing arguments"
    echo "       ./run_spatch.sh cocci_scripts_dir kernel_source_root_dir output_dir"
    exit 1
fi

cocci_dir=$1
kernel_root=$2
output_dir=$3

if [ ! -d "$kernel_root/arch/x86/include" ] || \
   [ ! -d "$kernel_root/arch/x86/include/generated" ] || \
   [ ! -d "$kernel_root/include" ] || \
   [ ! -d "$kernel_root/arch/x86/include/uapi" ] || \
   [ ! -d "$kernel_root/arch/x86/include/generated/uapi" ] || \
   [ ! -d "$kernel_root/include/uapi" ] || \
   [ ! -d "$kernel_root/include/generated/uapi" ] || \
   [ ! -f "$kernel_root/include/linux/compiler-version.h" ] || \
   [ ! -f "$kernel_root/include/linux/kconfig.h" ]
then
    echo "ERROR: Wrong kernel source root directory"
    exit 1
fi

if [ ! -d "$cocci_dir" ]
then
    echo "ERROR: Coccinelle scripts directory ($cocci_dir) not found"
    exit 1
elif [ ! -d "$cocci_dir/use" ]
then
    echo "ERROR: Coccinelle USE scripts directory ($cocci_dir/use) not found"
    exit 1
elif [ ! -d "$cocci_dir/free" ]
then
    echo "ERROR: Coccinelle FREE scripts directory ($cocci_dir/free) not found"
    exit 1
else
    use_scripts=($(find $cocci_dir/use -name '*.cocci' | xargs readlink -f))
    free_scripts=($(find $cocci_dir/free -name '*.cocci' | xargs readlink -f))
fi

for script in ${use_scripts[@]} ${free_scripts[@]}
do
    if [ ! -f "$script" ]
    then
        echo "ERROR: Coccinelle script not found"
        exit 1
    fi
done

if [ ! -d "$output_dir" ]
then
    echo "ERROR: Output directory not found!"
    exit 1
else
    timestamp=$(date +"%Y_%m_%d_@_%H_%M")
    use_output_dir=$output_dir/reports_$timestamp/use
    free_output_dir=$output_dir/reports_$timestamp/free
    mkdir -p $use_output_dir
    mkdir -p $free_output_dir
fi

counter=$(printf "%02d" 1)
num_scripts=$(expr ${#use_scripts[@]} + ${#free_scripts[@]})
echo "***** Started @ $(date +"%Y-%m-%d %H:%M") *****"

for script in ${use_scripts[@]} ${free_scripts[@]}
do
    printf "[$counter/$num_scripts] $script ..."
    if [[ $script =~ .*"free".* ]]
    then
        output_file=$(readlink -f $free_output_dir/$(echo $script | rev | cut -d "/" -f -1 | rev | cut -d "." -f 1))
    else
        output_file=$(readlink -f $use_output_dir/$(echo $script | rev | cut -d "/" -f -1 | rev | cut -d "." -f 1))
    fi

    if /usr/bin/spatch \
        -D report \
        --no-show-diff \
        --very-quiet \
        --cocci-file $script \
        --patch .  \
        --dir $kernel_root \
        -I $kernel_root/arch/x86/include \
        -I $kernel_root/arch/x86/include/generated \
        -I $kernel_root/include \
        -I $kernel_root/arch/x86/include/uapi \
        -I $kernel_root/arch/x86/include/generated/uapi \
        -I $kernel_root/include/uapi \
        -I $kernel_root/include/generated/uapi \
        --include $kernel_root/include/linux/compiler-version.h \
        --include $kernel_root/include/linux/kconfig.h \
        --jobs 20 \
        --chunksize 1 \
        --all-includes \
        --timeout 120 \
        > $output_file 2>&1
    then
        printf "\r[$counter/$num_scripts] DONE $script\n"
    else
        printf "\r[$counter/$num_scripts] FAIL $script\n"
    fi

    counter=$(printf "%02d" $(expr $counter + 1))
done

echo "----- Finished @ $(date +"%Y-%m-%d %H:%M") -----"
