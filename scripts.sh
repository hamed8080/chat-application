#!/bin/bash
root=$(pwd)
sub="$root/../sub-modules"

talkDir="$root"

ch="Chat"
async="Async"
logger="Logger"
additive="Additive"
additiveui="AdditiveUI"
models="ChatModels"
dto="ChatDTO"
core="ChatCore"
cache="ChatCache"  
trans="ChatTransceiver"
ext="ChatExtensions"
mocks="Mocks"

PACKEGE_PATHS=("$ch" "$async" "$logger" "$additive" "$additiveui" "$models" "$mocks" "$dto" "$core" "$cache" "$ext" "$trans" "$talkDir")

chch() {
    # Checkout to a specific branch
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        chk "$1"
    done
    cd $root

    return 0
}

pushall() {
    # Push
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git push "$1" "$2"
    done
    cd $root

    return 0
}

switchAll() {
    #Create branch
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git switch -c "$1"
    done
    cd $root

    return 0
}

mergeAll() {
    #Checkout to a branch then merge with another branch
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git checkout $1
        git merge $2
    done
    cd $root

    return 0
}

mergeContinue() {
    #Continue merging all branches
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git add .
        git merge --continue
    done
    cd $root

    return 0
}

commitAll() {
    #Checkout add all files to satge then commit to a branch
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git checkout $1
        git add .
        git commit -am $2
    done
    cd $root

    return 0
}

statusAll() {
    #Get status of all packages
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git status
    done
    cd $root

    return 0
}

undoAll() {
    #Undo all staged/unstaged changes
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git restore --staged .
        git restore .
    done
    cd $root

    return 0
}

ammendNoEdit() {
    #Ammend and no edit commit message
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git add .
        git commit --amend --no-edit
    done
    cd $root

    return 0
}

printDirectory() {
    dir=$(pwd)
    echo "Changed dirctory to $dir"
}

pushBoth() {
    pushall origin $1 &
    pid1=$!

    pushall origin-private $1 &
    pid2=$!

    wait $pid1
    wait $pid2
}

pushTags() {
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        git push --tags "$1"
    done
    cd $root

    return 0
}

pushBothTags() {
    echo "pushing origin tags"
    pushTags origin &
    pid1=$!

    echo "pushing origin-private tags"
    pushTags origin-private &
    pid2=$!

    wait $pid1
    wait $pid2

    echo "Both pushes are done."
}

pkg() {
    cd $sub
    CONFIG=$1
    for packagePath in "${PACKEGE_PATHS[@]}"; do
        cd $sub
        cd "$packagePath"
        printDirectory
        changePackage $CONFIG
        cd $sub
    done

    cd $root
    cd TalkModels
    printDirectory
    changePackage $CONFIG
    cd $root
}

changePackage() {
    PACKAGE_FILE="Package.swift"
    if [[ "$1" == "local" ]]; then
        sed -i '' 's|let useLocalDependency = false|let useLocalDependency = true|' "$PACKAGE_FILE" && echo "Set to use local dependency."
    elif [[ "$1" == "remote" ]]; then
        sed -i '' 's|let useLocalDependency = true|let useLocalDependency = false|' "$PACKAGE_FILE" && echo "Set to use remote dependency."
    fi
}

downloadSubModules() {

}
