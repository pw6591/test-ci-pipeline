$packageJson = (Get-Content package.json) -join "`n" | ConvertFrom-Json
$env:VERSION = $packageJson.version

docker build -t pw6591/test-ci-pipeline:windows-amd64-$($env:VERSION) -f Dockerfile.windows .
docker login -u $($env:DOCKERHUBUSERNAME) -p $($env:DOCKERHUBPASSWORD)
docker push plossys/test-ci-pipeline:windows-amd64-$($env:VERSION)
