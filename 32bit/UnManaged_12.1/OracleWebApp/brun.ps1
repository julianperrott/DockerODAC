docker stop XXXX;
docker rm -v $(docker ps -a -q -f status=exited);
docker rmi $(docker images -f "dangling=true" -q);

docker build -t myoraclientapp .;
pause;
docker run -it --rm -p 80:80 --name XXXX myoraclientapp;