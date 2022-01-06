#!/bin/bash
set -eu

cd artifacts
LOCAL_REPO="$(pwd)"

echo "Uploading to maven central ..."
TMPDIR="$(mktemp -d)"
cd "$TMPDIR"

mkdir -p ~/.m2
cat <<EOF >> ~/.m2/settings.xml
<settings>
    <servers>
        <server>
            <id>sonatype-nexus</id>
            <username>$SONATYPE_OSSRH_USERNAME</username>
            <password>$SONATYPE_OSSRH_PASSWORD</password>
        </server>
    </servers>
</settings>
EOF

function mvnstage {
    TASK="$1"; shift
    mvn -e -B \
        -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
        "org.sonatype.plugins:nexus-staging-maven-plugin:1.6.8:$TASK" \
        -DnexusUrl="https://oss.sonatype.org/" \
        -DserverId="sonatype-nexus" \
        -DstagingProfileId="$SONATYPE_OSSRH_STAGING_PROFILE_ID" \
        "$@"
}

echo "Opening a new staging repository ..."
mvnstage rc-open -DopenedRepositoryMessageFormat='MYREPOID==%s' | tee "$TMPDIR/openlog.txt"

REPOID="$(cat "$TMPDIR/openlog.txt" | grep -oP '^.*MYREPOID==\K.+' || true)"
if [[ ! "$REPOID" ]]; then
    echo "Failed to get REPOID" >&2
    exit 1
fi
echo "Opened repo ID: $REPOID"

echo "Uploading / Staging ..."
find "$LOCAL_REPO" -type f
echo "Total Size:"
du -s "$LOCAL_REPO"
mvnstage deploy-staged-repository -DrepositoryDirectory="$LOCAL_REPO" -DstagingRepositoryId="$REPOID" || {
    echo "An error occurred... dropping repo ..."
    mvnstage rc-drop -DstagingRepositoryId="$REPOID"
    die "Failed to upload / stage"
}

echo "Closing ..."
mvnstage rc-close -DstagingRepositoryId="$REPOID" || {
    echo "An error occurred... dropping repo ..."
    mvnstage rc-drop -DstagingRepositoryId="$REPOID"
    die "Failed to close"
}

echo "Releasing ..."
mvnstage rc-release -DstagingRepositoryId="$REPOID" || {
    echo "An error occurred... dropping repo ..."
    mvnstage rc-drop -DstagingRepositoryId="$REPOID"
    die "Failed to release"
}

rm -Rf ~/.m2

echo "Maven Central upload completed successfully"
echo
