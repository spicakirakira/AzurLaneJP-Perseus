#!/bin/bash
# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
if [ ! -f "AzurLane/com.YoStarJP.AzurLane.apk" ]; then
    #echo "Get Azur Lane apk"

    # eg: wget "your download link" -O "your packge name.apk" -q
    #if you want to patch .xapk, change the suffix here to wget "your download link" -O "your packge name.xapk" -q
    wget "https://d-e03.winudf.com/b/XAPK/Y29tLllvU3RhckpQLkF6dXJMYW5lXzgyMTVfNzk1ZGI4ZmE?_fn=44Ki44K644O844Or44Os44O844OzXzguMi4xNV9BUEtQdXJlLnhhcGs&_p=Y29tLllvU3RhckpQLkF6dXJMYW5l&download_id=1957405346141324&is_hot=true&k=da3a75c9e4b1e186898ad1e987c43524670c244a&uu=https%3A%2F%2Fd-08.winudf.com%2Fb%2FXAPK%2FY29tLllvU3RhckpQLkF6dXJMYW5lXzgyMTVfNzk1ZGI4ZmE%3Fk%3D33f595d24a4f8bfa0da31bd5f0fac787670c244a" -O com.bilibili.AzurLane.apk -q
    echo "apk downloaded !"
    
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    cp AzurLane/com.YoStarJP.AzurLane.apk .
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/Egoistically/Perseus
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.YoStarJP.AzurLane.apk

echo "Copy Perseus libs"
cp -r Perseus/. com.YoStarJP.AzurLane.apk/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.YoStarJP.AzurLane.apk/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.YoStarJP.AzurLane.apk/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"Perseus\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.bilibili.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.YoStarJP.AzurLane.apk -o build/com.YoStarJP.AzurLane.patched.apk

echo "Set Github Release version"
s=($(./apkeep -a com.YoStarJP.AzurLane -l))
echo "PERSEUS_VERSION=$(echo ${s[-1]})" >> $GITHUB_ENV
